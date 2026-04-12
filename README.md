## <img src="https://raw.githubusercontent.com/geoje/Keep/refs/heads/main/Keep/Assets.xcassets/AppIcon.appiconset/32.png"> Fanmade Keep for macOS

A macOS menu bar app that brings your **Google Keep** notes to your desktop.


## 📦 Install

#### Option 1: Terminal (one-liner)

```sh
curl -L -o Keep.zip https://github.com/geoje/Keep/releases/latest/download/Keep.zip \
  && unzip Keep.zip \
  && xattr -cr Keep.app \
  && mv Keep.app /Applications/ \
  && rm Keep.zip \
  && open /Applications/Keep.app
```

> **Why `xattr -cr`?**  
> Keep is self-signed and not notarized by Apple. This command removes the macOS quarantine flag so the app can launch.

#### Option 2: Without Terminal

1. Download **`Keep.zip`** from [**Latest Release**](https://github.com/geoje/Keep/releases/latest)
2. Double-click `Keep.zip` to extract — `Keep.app` will appear
3. Drag `Keep.app` to the **Applications** folder
4. On first launch, macOS may block it — open **System Settings → Privacy & Security** and click **"Open Anyway"**


## ✨ Features

<table>
<tr>
  <th>Menu Bar</th>
  <th>Edit Mode</th>
</tr>
<tr>
  <td><img width="387" height="536" src="https://github.com/user-attachments/assets/c25ccf8f-746b-4a68-b7ef-adc34a4e8bf1" /></td>
  <td><img width="388" height="537" src="https://github.com/user-attachments/assets/eb19959c-c53f-4ea5-9b16-e47a1c3a8bc7" /></td>
</tr>
</table>

<table>
<tr>
  <th>Widget</th>
  <th>Liquid Glass</th>
</tr>
<tr>
  <td><img width="378" height="403" src="https://github.com/user-attachments/assets/a59c8871-7611-40ad-8725-03b5cf20dc6b" /></td>
  <td><img width="378" height="402" src="https://github.com/user-attachments/assets/96187f0f-2be4-4dcb-85b7-150427e505d7" /></td>
</tr>
<tr>
  <th>Notification Center</th>
  <th>Widget Config</th>
</tr>
<tr>
  <td><img width="378" height="448" src="https://github.com/user-attachments/assets/8a3bd72f-b1f7-401a-96c8-8448f1665daa" /></td>
  <td><img width="395" height="482" src="https://github.com/user-attachments/assets/9dae268b-f6a1-4956-a72e-6ef705a840a1" /></td>
</tr>
</table>

## 🔐 Play Service

#### How it works
1. Opens a visible Chrome window at Google's embedded sign-in page.
2. Polls cookies every second via ChromeDriver; waits for `oauth_token` to appear.
3. Exchanges `oauth_token` → `master token` (long-lived, stored persistently) via Google's Android auth endpoint.
4. At sync time, exchanges `master token` → scoped `access token`, then calls the Keep API directly.

#### How to add an account
<table>
<tr>
  <th>1. Click add option</th>
  <th>2. Login google account</th>
  <th>3. Click <code>I agree</code></th>
</tr>
<tr>
  <td><img width="386" height="589" src="https://github.com/user-attachments/assets/040404bd-6a6e-403b-909f-7fa8c5274684" /></td>
  <td><img width="757" height="741" src="https://github.com/user-attachments/assets/187317af-a842-4ce6-b93a-492818883450" /></td>
  <td><img width="756" height="742" src="https://github.com/user-attachments/assets/05f38535-aa64-4441-9dc9-bc9eddf033d1" /></td>
</tr>
</table>

<table>
<tr>
  <th>4. Wait app detects the OAuth token from the cookie and creates a notification</th>
  <th>5. Click <code>Sync now</code> option to get all notes</th>
  <th>6. Verify it works</th>
</tr>
<tr>
  <td><img width="379" height="126" src="https://github.com/user-attachments/assets/c1633d9f-b177-436c-811a-2dd95050098c" /></td>
  <td><img width="366" height="718" src="https://github.com/user-attachments/assets/c642edac-0409-4152-8f4b-4cbf1948684f" /></td>
  <td><img width="369" height="535" src="https://github.com/user-attachments/assets/bd6ce568-c065-4285-b3fe-ff71f391c456" /></td>
</tr>
</table>

## 🔐 Chrome Profile

> Recommended for accounts where master token issuance is restricted (e.g., Google Workspace / corporate accounts). <br>
> Try Play Service first.
> Use this only if that fails.
> Currently supports read-only access only.

#### How it works
1. Opens a visible Chrome for Testing window, prompting the user to add a Chrome profile and sign in.
2. Polls the Chrome user data directory every second for a new profile folder with `explicit_browser_signin: true`.
3. Once detected, reads the email and picture URL directly from the profile's `Preferences` file — no tokens needed.
4. At sync time, launches a headless (invisible) Chrome using the saved profile, navigates to `keep.google.com`, and parses the embedded `loadChunk` JSON payload from the page HTML to retrieve notes.

#### How to add an account
<table>
<tr>
  <th>1. Click add option</th>
  <th>2. Click the user icon and <code>Add Chromium Profile</code></th>
  <th>3. Click <code>Sign in</code></th>
</tr>
<tr>
  <td><img width="387" height="586" src="https://github.com/user-attachments/assets/b6b34f6a-ab42-4673-84d0-c80008766582" /></td>
  <td><img width="756" height="523" src="https://github.com/user-attachments/assets/b06539ac-e6ff-47d6-a264-bd5dbef7943b" /></td>
  <td><img width="978" height="717" src="https://github.com/user-attachments/assets/be123d6d-020e-48e7-87cf-7f173b49237b" /></td>
</tr>
</table>

<table>
<tr>
  <th>4. Login google account</th>
  <th>5. Finish profile settings</th>
</tr>
<tr>
  <td><img width="979" height="719" src="https://github.com/user-attachments/assets/d032bbc6-b479-4761-ae37-36a298e52bca" /></td>
  <td><img width="773" height="664" src="https://github.com/user-attachments/assets/6ee8aea0-2852-4c86-b6c3-ce656d9bdb4b" /></td>
</tr>
</table>

<table>
<tr>
  <th>6. Wait app detects the new profile folder. When you see the notification, close Chrome</th>
  <th>7. Click <code>Sync now</code> option to get all notes</th>
  <th>8. Verify it works</th>
</tr>
<tr>
  <td><img width="750" height="240" src="https://github.com/user-attachments/assets/6e8019ef-2eed-4a60-875d-270cc68d3bdb" /></td>
  <td><img width="774" height="1438" src="https://github.com/user-attachments/assets/f3c5c551-1157-4496-ac2b-091545932b18" /></td>
  <td><img width="768" height="1064" src="https://github.com/user-attachments/assets/64715ebc-65d3-4649-835d-c3e8fa98ebae" /></td>
</tr>
</table>
