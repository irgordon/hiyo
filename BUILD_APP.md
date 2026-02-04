# Building Hiyo for macOS (Local / No Developer Account)

This guide explains how to build the **Hiyo** macOS app from source, create a `.dmg` installer, and sign it with your own local identity.

**Note:** This process does **not** require an Apple Developer account, Apple Developer Program membership, or Notarization. It is intended for users who want to build and run the app on their own machines or share it privately with friends who trust them.

---

## 1. Overview

**Hiyo** is a local-first LLM inference application built with Swift and MLX.

Because this guide focuses on **local, user-signed builds**:
- You do **not** need to pay Apple $99/year.
- You do **not** need to upload anything to App Store Connect.
- The resulting app will show a warning when first opened (because it is not notarized by Apple), which is expected behavior for personal builds.

---

## 2. Prerequisites

Before you begin, ensure you have:

1.  **macOS Sonoma (14.0)** or later.
2.  **Xcode** (installed from the Mac App Store).
    -   *Note:* You must run Xcode at least once to install components.
3.  **Command Line Tools** for Xcode.
    -   Run this in Terminal to install:
        ```bash
        xcode-select --install
        ```
4.  **Homebrew** (Optional, but recommended for creating the DMG).
    -   See [brew.sh](https://brew.sh) to install.

Dependencies like **MLX** and **Swift Transformers** will be fetched automatically by Xcode / Swift Package Manager.

---

## 3. Clone the repository

Open your Terminal and run:

```bash
git clone https://github.com/hiyoai/hiyo.git
cd hiyo
```

---

## 4. Open and configure the project in Xcode

1.  Open the project by double-clicking `Package.swift` in the `hiyo` folder, or by running:
    ```bash
    open Package.swift
    ```
    Xcode will open and start resolving dependencies (this may take a minute).

2.  **Select the App Target:**
    -   In the top bar, ensure the scheme is set to **Hiyo** (the executable icon) and the destination is **My Mac**.

3.  **Configure Signing:**
    -   Click on the **Hiyo** project icon in the left file navigator (top root item).
    -   Select the **Hiyo** target in the main view.
    -   Go to the **Signing & Capabilities** tab.
    -   Under **Team**, select **None** or **Personal Team** (if you have a free Apple ID signed in).
    -   **Important:** If using "None", ensure "Sign to Run Locally" is selected (or it may default to Ad Hoc). For local builds, you do **not** need a Provisioning Profile.

---

## 5. Build and run the app locally

1.  Ensure the destination in the top bar is **My Mac**.
2.  Press **Cmd+B** (`⌘B`) to build.
3.  Press **Cmd+R** (`⌘R`) to run.

**First Run Warning:**
If you see a "Developer cannot be verified" or similar Gatekeeper warning:
- Click **OK**.
- Open **System Settings** -> **Privacy & Security**.
- Scroll down to the Security section and look for the message about Hiyo.
- Click **Open Anyway**.

---

## 6. Create a Release build

To create a standalone `.app` file optimized for performance:

1.  In Xcode, go to **Product** > **Scheme** > **Edit Scheme...** (or press `Cmd+<`).
2.  Select **Run** in the sidebar.
3.  Change **Build Configuration** to **Release**.
4.  Close the dialog.
5.  Build the app (`Cmd+B`).

**Locate the built app:**
The app is built into your `DerivedData` folder. To find it:
1.  In the Project Navigator (left sidebar), look for the **Products** group (it might be hidden or inside a folder depending on Xcode version with Packages).
2.  If you can't find it there, right-click the `Hiyo` product in the "Products" folder and select **Show in Finder**.
3.  Alternatively, using Terminal:
    ```bash
    # This finds the most recently modified Hiyo.app in DerivedData
    find ~/Library/Developer/Xcode/DerivedData -name "Hiyo.app" -type d -maxdepth 5 -print0 | xargs -0 ls -td | head -1
    ```

Copy this `Hiyo.app` to a convenient location (e.g., a `Build` folder on your Desktop) for the next steps.

---

## 7. Create a local signing identity (optional but recommended)

To sign the app so it runs consistently on your machine without "broken" signatures, create a self-signed certificate:

1.  Open **Keychain Access** (Command+Space, type "Keychain Access").
2.  Go to **Keychain Access** (menu) > **Certificate Assistant** > **Create a Certificate...**
3.  **Name:** `Hiyo Local Developer`
4.  **Identity Type:** Self Signed Root
5.  **Certificate Type:** Code Signing
6.  Click **Create**, then **Done**.

This certificate is now trusted on **your** Mac for code signing.

---

## 8. Sign the app locally

Now, sign your Release build with the certificate you just created.

Assuming you copied `Hiyo.app` to a folder named `Build` in the current directory:

```bash
# syntax: codesign --deep --force --options runtime --sign "Your Cert Name" /path/to/App
codesign --deep --force --options runtime \
  --sign "Hiyo Local Developer" \
  ./Build/Hiyo.app
```

**Verify the signature:**

```bash
codesign --verify --deep --strict --verbose=2 ./Build/Hiyo.app
```
You should see output ending in `valid on disk` and `satisfies its designated requirement`.

---

## 9. Create a .dmg installer

You can package the app into a `.dmg` for easy installation.

### Option A: Simple manual DMG (Disk Utility)
1.  Open **Disk Utility**.
2.  **File** > **New Image** > **Blank Image...**
3.  **Save As:** `Hiyo-Install`
4.  **Name:** `Hiyo`
5.  **Size:** 500 MB (or enough to fit the app).
6.  **Format:** Mac OS Extended (Journaled).
7.  Click **Save**.
8.  Open the mounted disk image in Finder.
9.  Drag your signed `Hiyo.app` into it.
10. Eject the disk image.
11. (Optional) Convert to read-only via Disk Utility -> Images -> Convert.

### Option B: Scripted DMG (using `create-dmg`)
This creates a professional-looking installer with a background and drag-drop target.

1.  Install `create-dmg` via Homebrew:
    ```bash
    brew install create-dmg
    ```

2.  Run the command (adjust paths as needed):
    ```bash
    create-dmg \
      --volname "Hiyo" \
      --window-pos 200 120 \
      --window-size 600 400 \
      --icon-size 100 \
      --app-drop-link 400 200 \
      Hiyo.dmg \
      ./Build/Hiyo.app
    ```

---

## 10. Install and run from the .dmg

1.  Double-click `Hiyo.dmg`.
2.  Drag `Hiyo.app` to the **Applications** folder (or the shortcut provided).
3.  Eject the DMG.
4.  Open `Hiyo` from your Applications folder.

**Gatekeeper Warning:**
Since this app is self-signed and not notarized by Apple, you might see:
> "Hiyo" can’t be opened because the developer cannot be verified.

**To bypass this (one time only):**
1.  Click **Done** or **Cancel**.
2.  **Right-click** (or Control-click) the Hiyo app in Applications.
3.  Select **Open** from the menu.
4.  Click **Open** in the dialog box that appears.

Future launches will open normally.

---

## 11. Troubleshooting

*   **"App is damaged and can't be opened":**
    *   This often happens with unsigned or improperly signed apps downloaded from the internet (Quarantine attribute).
    *   **Fix:** Run `xattr -cr /Applications/Hiyo.app` to clear quarantine attributes, then try right-click Open again.
    *   **Fix:** Re-sign the app on your machine using the steps in Section 8.

*   **"Developer cannot be verified":**
    *   This is expected. Use the **Right-click -> Open** trick explained in Section 10.

*   **Build failures:**
    *   Ensure you have the latest **Command Line Tools**: `xcode-select --install`.
    *   Ensure you are on macOS 14.0+ as required by MLX.

---

## 12. Security and trust model

*   **Not Notarized:** This build is not sent to Apple for malware scanning (notarization).
*   **Personal Use:** It is intended for your personal use.
*   **Trust:** By building from source, you are trusting the code in this repository and your own build environment, rather than a third-party developer signature.
*   **License:** This project is MIT licensed, allowing you to modify and distribute it, provided you adhere to the license terms.

---

## FAQ / Common Questions

**Q: Do I need an Apple Developer account?**
A: **No.** This guide uses a self-signed local certificate. You do not need to pay Apple or register for the Developer Program.

**Q: Why does macOS warn me about the developer?**
A: Because the app is not **notarized** by Apple. Notarization requires a paid developer account. Since you built and signed it yourself, macOS treats it as "unknown" until you explicitly trust it.

**Q: Can I share this .dmg with friends?**
A: Yes, but they will see the same "Developer cannot be verified" warnings and will need to use the "Right-click -> Open" method to launch it the first time. They must trust *you* as the source of the file.
