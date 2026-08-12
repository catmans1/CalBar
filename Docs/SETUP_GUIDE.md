# Setup Guide — CalBar

## Step 1: Create a Google Cloud Project

1. Go to [console.cloud.google.com](https://console.cloud.google.com/)
2. Create a new project (or select an existing one)
3. Go to **APIs & Services → Library**
4. Search for **Google Calendar API** and click **Enable**

## Step 2: Create an OAuth 2.0 Client

1. Go to **APIs & Services → Credentials**
2. Click **+ Create Credentials → OAuth 2.0 Client ID**
3. Application type: **Desktop app**
4. Give it a name (e.g. "CalBar macOS") and click **Create**
5. Copy the **Client ID** (format: `123456789-abc.apps.googleusercontent.com`) and **Client Secret**

> If your OAuth consent screen is in "Testing" mode, add your Google account email as a test user under **OAuth consent screen → Test users**.

## Step 3: Configure the URL Scheme in Xcode

Open `CalBar/Info.plist` and update the URL scheme to match your Client ID:

| Key | Value |
|---|---|
| CFBundleURLName | `com.calbar.oauth` |
| CFBundleURLSchemes | `com.googleusercontent.apps.YOUR_CLIENT_ID` |

> Replace `YOUR_CLIENT_ID` with the portion before `.apps.googleusercontent.com`.
> Example: Client ID `123456-abc.apps.googleusercontent.com` → scheme `com.googleusercontent.apps.123456-abc`

## Step 4: Set the Code Signing Entitlement

In Xcode, go to the **CalBar** target → **Build Settings** → search **Code Signing Entitlements** → set it to `CalBar/CalBar.entitlements`.

This grants the network client entitlement required for all HTTP requests (OAuth token exchange, Calendar API).

## Step 5: Build & Run

Select the **CalBar** scheme in Xcode and press `⌘R`. The calendar icon appears in your menu bar.

## Step 6: Sign In

1. Click the calendar icon in the menu bar
2. Click the ⚙️ button in the footer → **Settings**
3. Go to the **Account** tab
4. Paste your **Client ID** and **Client Secret**
5. Click **Sign in with Google** — a browser window opens
6. Sign in with your Google account and grant calendar access
7. Events for today load automatically

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| Browser does not open | URL Scheme mismatch in Info.plist | Verify scheme matches your Client ID |
| `invalid_client` | Wrong Client ID or Secret | Double-check both fields in Settings → Account |
| `client_secret missing` | Client Secret not entered | Enter Client Secret in Settings → Account |
| HTTP 403 on test connection | Google Calendar API not enabled | Enable it in Cloud Console → APIs & Services → Library |
| Network error (-1003) | Missing network entitlement | Set `CODE_SIGN_ENTITLEMENTS` in Xcode Build Settings |
| No events showing | Calendar not selected | Settings → Calendars → enable the calendars to display |
| Token expired | Refresh token expired | Sign out and sign in again |
