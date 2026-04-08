<p align="center">
  <img src="https://img.shields.io/badge/questions-1,300-c45d3e?style=for-the-badge" alt="1300 Questions"/>
  <img src="https://img.shields.io/badge/categories-13-2d7a4f?style=for-the-badge" alt="13 Categories"/>
  <img src="https://img.shields.io/badge/cost-free-b8860b?style=for-the-badge" alt="Free"/>
  <img src="https://img.shields.io/badge/platforms-web%20%7C%20iOS-4a3928?style=for-the-badge" alt="Web & iOS"/>
</p>

<h1 align="center">Real Estate Exam Practice</h1>

<p align="center">
  <strong>A comprehensive, beautifully designed practice exam with 1,000 multiple choice questions<br>and 300 case study questions covering all major topics on the California real estate licensing exam.</strong>
</p>

<p align="center">
  <a href="https://nilehanov.github.io/real-estate-exam/">Launch the Web App</a>
</p>

---

## Features

- **1,000 multiple choice questions** across 13 exam categories
- **300 case study questions** — 100 real-world scenarios with 3 questions each
- **Two study modes** — toggle between multiple choice and case studies
- **Instant feedback** with detailed explanations for every answer
- **Hints** to nudge you in the right direction before revealing the answer
- **Progress tracking** — see your score, accuracy, and per-category breakdown
- **Search** — find questions by keyword across all categories
- **Category filtering** — focus on your weak areas
- **Visual question grid** — quickly navigate and see which questions you've answered correctly or missed
- **Fully responsive** — works on desktop, tablet, and phone
- **Native iOS app** — runs natively on iPhone via Capacitor
- **Zero dependencies** — single HTML file for web, no backend
- **Works offline** — save the page and study anywhere

## Question Categories

| Category | Questions |
|:---|---:|
| Financing | 148 |
| Property Ownership | 97 |
| Math & Calculations | 97 |
| Contracts | 87 |
| Valuation | 75 |
| Transfer of Property | 72 |
| Agency | 71 |
| Land Use | 69 |
| Practice of Real Estate | 64 |
| Fair Housing | 59 |
| Property Management | 57 |
| Escrow & Closing | 52 |
| California Specific | 52 |

## Getting Started

### Web

Just open the app in your browser:

```
https://nilehanov.github.io/real-estate-exam/
```

Or run it locally:

```bash
git clone https://github.com/nilehanov/real-estate-exam.git
open real-estate-exam/index.html
```

No install, no setup, no accounts.

### iOS (Run on iPhone)

Prerequisites: Xcode, Node.js

```bash
git clone https://github.com/nilehanov/real-estate-exam.git
cd real-estate-exam
npm install
npx cap sync ios
npx cap open ios
```

Then in Xcode:
1. Select your iPhone as the build target
2. Go to **Signing & Capabilities** and set your Team (Apple ID)
3. Click **Play** to build and install on your phone
4. On your iPhone: **Settings > General > VPN & Device Management** — trust the developer certificate

> **Note:** A free Apple ID works for local testing (app expires after 7 days). The $99/year Apple Developer Program is required for App Store distribution.

### Updating the iOS App

After any changes to `www/index.html`:

```bash
npx cap sync ios
```

Then rebuild in Xcode.

## How It Works

1. **Pick a category** from the sidebar (or study all at once)
2. **Read the question** and select your answer
3. **Use the hint** if you're stuck — it gives a nudge without the full answer
4. **Review the explanation** after answering to reinforce the concept
5. **Track your progress** via the stats bar and question grid
6. **Switch modes** — toggle between multiple choice and case study questions

## Project Structure

```
index.html              # Web app (served by GitHub Pages)
www/index.html          # iOS-adapted version (safe area support)
ios/                    # Native Xcode project (Capacitor)
capacitor.config.json   # Capacitor configuration
package.json            # Node dependencies (Capacitor)
```

## Tech

Single-file vanilla HTML/CSS/JS application. All 1,300 questions are embedded as JSON. The UI uses CSS custom properties for theming and is fully responsive with a collapsible sidebar on mobile.

The iOS app uses [Capacitor](https://capacitorjs.com/) to wrap the web app in a native WKWebView shell with Dynamic Island/notch safe area handling.

## App Store Connect API Setup

The project uses the App Store Connect API for automated builds, uploads, and review submissions.

### 1. Generate an API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com) > Users and Access > Integrations > App Store Connect API
2. Click **Generate API Key** (requires Admin role)
3. Download the `.p8` private key file (you can only download it once)
4. Note the **Key ID** and **Issuer ID** shown on the page

### 2. Configure Environment

Copy the example env file and fill in your values:

```bash
cp .env.example .env
```

Edit `.env`:

```
ASC_KEY_ID=YOUR_KEY_ID              # e.g. AB12CD34EF
ASC_ISSUER_ID=YOUR_ISSUER_ID       # e.g. a1b2c3d4-e5f6-7890-abcd-ef1234567890
ASC_PRIVATE_KEY_PATH=/path/to/AuthKey_XXXXXXXX.p8
ASC_APP_ID=YOUR_APP_ID             # From App Store Connect URL
ASC_BUNDLE_ID=com.yourcompany.yourapp
ASC_TEAM_ID=YOUR_TEAM_ID           # Apple Developer Team ID
```

Store the `.p8` key file somewhere safe outside the repo (e.g. `~/private_keys/`). The `.env` file is gitignored and never committed.

### 3. Usage

The API key is used by deployment scripts (fastlane, Python scripts) for:
- Uploading builds to App Store Connect
- Setting export compliance on new builds
- Managing app review submissions
- Updating app metadata

## App Store Submission

1. Enroll in the [Apple Developer Program](https://developer.apple.com) ($99/year)
2. In Xcode: **Product > Archive** (target: "Any iOS Device")
3. **Organizer > Distribute App > App Store Connect > Upload**
4. In [App Store Connect](https://appstoreconnect.apple.com): create listing, add screenshots, set category to Education
5. Submit for App Review (typically 24-48 hours)

## License

MIT
