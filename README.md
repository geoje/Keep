## <img src="https://raw.githubusercontent.com/geoje/Keep/refs/heads/main/Keep/Assets.xcassets/AppIcon.appiconset/32.png"> Fanmade Keep for macOS

A macOS menu bar app that brings your **Google Keep** notes to your desktop.

## ✨ Features

<table>
<tr>
  <th>Menu Bar</th>
  <th>Edit Mode</th>
</tr>
<tr>
  <td><img width="387" height="536" alt="image" src="https://github.com/user-attachments/assets/c25ccf8f-746b-4a68-b7ef-adc34a4e8bf1" /></td>
  <td><img width="388" height="537" alt="image" src="https://github.com/user-attachments/assets/eb19959c-c53f-4ea5-9b16-e47a1c3a8bc7" /></td>
</tr>
</table>

<table>
<tr>
  <th>Widget</th>
  <th>Liquid Glass</th>
</tr>
<tr>
  <td><img width="378" height="403" alt="image" src="https://github.com/user-attachments/assets/a59c8871-7611-40ad-8725-03b5cf20dc6b" /></td>
  <td><img width="378" height="402" alt="image" src="https://github.com/user-attachments/assets/96187f0f-2be4-4dcb-85b7-150427e505d7" /></td>
</tr>
<tr>
  <th>Notification Center</th>
  <th>Widget Config</th>
</tr>
<tr>
  <td><img width="378" height="448" alt="image" src="https://github.com/user-attachments/assets/8a3bd72f-b1f7-401a-96c8-8448f1665daa" /></td>
  <td><img width="395" height="482" alt="image" src="https://github.com/user-attachments/assets/9dae268b-f6a1-4956-a72e-6ef705a840a1" /></td>
</tr>
</table>

## 📦 Install

### Option 1: Terminal (one-liner)

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

### Option 2: Without Terminal

1. Download **`Keep.zip`** from [**Latest Release**](https://github.com/geoje/Keep/releases/latest)
2. Double-click `Keep.zip` to extract — `Keep.app` will appear
3. Drag `Keep.app` to the **Applications** folder
4. On first launch, macOS may block it — open **System Settings → Privacy & Security** and click **"Open Anyway"**
