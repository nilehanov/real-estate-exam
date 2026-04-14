import os, json, time, jwt, requests

KEY_ID          = os.environ["ASC_KEY_ID"]
ISSUER_ID       = os.environ["ASC_ISSUER_ID"]
APP_ID          = os.environ["ASC_APP_ID"]
SUBSCRIPTION_ID = os.environ.get("ASC_SUBSCRIPTION_ID")  # required to submit IAP for review

with open(os.environ["ASC_PRIVATE_KEY_PATH"]) as f:
    PRIVATE_KEY = f.read()

# Generate JWT token
now = int(time.time())
token = jwt.encode(
    {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
    PRIVATE_KEY,
    algorithm="ES256",
    headers={"kid": KEY_ID}
)
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

# Wait for build to finish processing
print("Waiting for build to finish processing...")
for attempt in range(30):
    builds = requests.get(
        f"https://api.appstoreconnect.apple.com/v1/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=1",
        headers=headers
    ).json()
    build = builds["data"][0]
    build_id = build["id"]
    state = build["attributes"].get("processingState", "UNKNOWN")
    version = build["attributes"]["version"]
    print(f"  Build {version} (#{build_id}): {state}")
    if state == "VALID":
        break
    if state == "FAILED":
        print("Build processing failed!")
        exit(1)
    time.sleep(10)
else:
    print("Timed out waiting for build processing")
    exit(1)

print(f"Latest build: v{build['attributes'].get('version', '?')} (build {version}, id={build_id})")

# Set export compliance
resp = requests.patch(
    f"https://api.appstoreconnect.apple.com/v1/builds/{build_id}",
    headers=headers,
    json={"data": {"type": "builds", "id": build_id,
          "attributes": {"usesNonExemptEncryption": False}}}
)
print(f"Export compliance set (status {resp.status_code})")

# Get app store version
versions = requests.get(
    f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}/appStoreVersions?filter[appStoreState]=DEVELOPER_REJECTED,REJECTED,PREPARE_FOR_SUBMISSION,READY_FOR_REVIEW",
    headers=headers
).json()

if not versions.get("data"):
    # Try without filter
    versions = requests.get(
        f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}/appStoreVersions",
        headers=headers
    ).json()

version_id = versions["data"][0]["id"]
version_state = versions["data"][0]["attributes"]["appStoreState"]
print(f"App Store version: {versions['data'][0]['attributes']['versionString']} (state: {version_state}, id: {version_id})")

# Assign build to version
resp = requests.patch(
    f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{version_id}/relationships/build",
    headers=headers,
    json={"data": {"type": "builds", "id": build_id}}
)
print(f"Build assigned to version (status {resp.status_code})")

# Submit for review
sub = requests.post(
    "https://api.appstoreconnect.apple.com/v1/reviewSubmissions",
    headers=headers,
    json={"data": {"type": "reviewSubmissions",
          "attributes": {"platform": "IOS"},
          "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}}}}
).json()

if "errors" in sub:
    print(f"Submission error: {json.dumps(sub['errors'], indent=2)}")
    exit(1)

sub_id = sub["data"]["id"]

requests.post(
    "https://api.appstoreconnect.apple.com/v1/reviewSubmissionItems",
    headers=headers,
    json={"data": {"type": "reviewSubmissionItems",
          "relationships": {
              "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
              "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}}}
)

# Submit IAP subscription for review alongside the binary
if SUBSCRIPTION_ID:
    iap_resp = requests.post(
        "https://api.appstoreconnect.apple.com/v1/reviewSubmissionItems",
        headers=headers,
        json={"data": {"type": "reviewSubmissionItems",
              "relationships": {
                  "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
                  "subscription": {"data": {"type": "subscriptions", "id": SUBSCRIPTION_ID}}}}}
    )
    print(f"IAP subscription added to review (status {iap_resp.status_code})")
    if iap_resp.status_code >= 400:
        print(f"  Warning: {iap_resp.text}")
else:
    print("WARNING: ASC_SUBSCRIPTION_ID not set — IAP subscription will NOT be included in review!")

resp = requests.patch(
    f"https://api.appstoreconnect.apple.com/v1/reviewSubmissions/{sub_id}",
    headers=headers,
    json={"data": {"type": "reviewSubmissions", "id": sub_id,
          "attributes": {"submitted": True}}}
)
print(f"Submitted for review! (status {resp.status_code})")
