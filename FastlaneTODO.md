# Fastlane & CI/CD Setup TODO

## 1. App Store Connect API Key

This is used by Fastlane to authenticate with Apple (instead of username/password).

- [ ] Go to [App Store Connect > Users and Access > Integrations > App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)
- [ ] Click **Generate API Key**
- [ ] Name: `Fastlane CI` (or whatever you want)
- [ ] Access: **App Manager** (minimum needed for TestFlight + submission)
- [ ] Download the `.p8` key file — you can only download it once
- [ ] Note the **Key ID** and **Issuer ID** shown on the page

## 2. Distribution Certificate

You need an Apple Distribution certificate exported as a `.p12` file.

- [ ] Open **Keychain Access** on your Mac
- [ ] Find your **Apple Distribution** certificate (under "My Certificates")
  - If you don't have one, create it in [Apple Developer > Certificates](https://developer.apple.com/account/resources/certificates/list)
- [ ] Right-click the certificate > **Export** > save as `.p12`
- [ ] Set a password when prompted — you'll need this as `P12_PASSWORD`

## 3. Base64 Encode the Secrets

Run these commands locally to get the values for GitHub secrets:

```bash
# Encode the .p12 certificate
base64 -i ~/path/to/your-certificate.p12 | pbcopy
# Paste this as BUILD_CERTIFICATE_BASE64

# Encode the .p8 API key
base64 -i ~/path/to/AuthKey_XXXXXXXXXX.p8 | pbcopy
# Paste this as APP_STORE_CONNECT_KEY
```

## 4. GitHub Repository Secrets

- [ ] Go to your repo > **Settings > Secrets and variables > Actions**
- [ ] Add these **Repository Secrets**:

| Secret Name | Value |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | Base64-encoded .p12 certificate |
| `P12_PASSWORD` | Password you set when exporting the .p12 |
| `APP_STORE_CONNECT_KEY_ID` | Key ID from step 1 |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from step 1 |
| `APP_STORE_CONNECT_KEY` | Base64-encoded .p8 key file |

## 5. GitHub Environments

The deploy workflows reference environments for approval gates.

- [ ] Go to your repo > **Settings > Environments**
- [ ] Create **staging** environment (used by TestFlight deploys)
  - Optional: add required reviewers if you want approval before deploy
- [ ] Create **production** environment (used by App Store deploys)
  - Recommended: add required reviewers so releases don't go out accidentally

## 6. App Store Connect App Record

- [ ] Go to [App Store Connect > Apps](https://appstoreconnect.apple.com/apps)
- [ ] If you haven't already, click **+** > **New App**
- [ ] Bundle ID: `com.Solomon.Lazer-Dragon`
- [ ] Fill in the required metadata (name, primary language, etc.)
- [ ] This must exist before Fastlane can upload builds

## 7. Install Fastlane Locally

```bash
cd /Users/luke/Documents/GitHub/Lazer-Dragon-Workout-Experience
bundle install
```

## 8. Test Locally

```bash
# Run tests
bundle exec fastlane test

# Build and upload to TestFlight (uses your local Xcode signing)
bundle exec fastlane beta
```

## 9. Verify CI

- [ ] Push a branch and open a PR — `tests.yml` should run automatically
- [ ] Merge to master — `deploy-testflight.yml` should trigger and upload to TestFlight
- [ ] Create a GitHub Release — `deploy-appstore.yml` should trigger and submit for review

---

## How It Works

| Event | Workflow | Fastlane Lane | Result |
|---|---|---|---|
| PR opened / updated | `tests.yml` | `test` | Unit tests run |
| Push to master | `tests.yml` | `test` | Unit tests run |
| Push to master (code changed) | `deploy-testflight.yml` | `beta` | Build uploaded to TestFlight |
| GitHub Release published | `deploy-appstore.yml` | `release` | Build submitted to App Store review |
| Manual dispatch | `deploy-appstore.yml` | `release` | Build submitted to App Store review |

## File Reference

```
Gemfile                              # Ruby dependencies (fastlane, xcpretty)
fastlane/
  Appfile                            # App identifier + team config
  Fastfile                           # Lane definitions (test, beta, release)
  Matchfile                          # Code signing config (for future use)
.github/workflows/
  tests.yml                          # CI: run tests on PRs and pushes
  deploy-testflight.yml              # CD: auto-deploy to TestFlight on master
  deploy-appstore.yml                # CD: submit to App Store on release
```
