# VPN Client for Proton VPN

A Flutter application that connects to Proton VPN's free tier using the WireGuard protocol.

## Features

- Login with Proton VPN credentials (supports 2FA)
- Fetches list of free servers from Proton VPN API
- Generates WireGuard configuration for selected server
- Connects and disconnects WireGuard tunnel
- Displays connection status, upload/download speeds, and connected time
- System tray integration (Linux)
- Persistent notification (Android)
- Kill switch (placeholder)
- Minimalist, modern UI with Varela Round font

## Design

- Background: #050505 (near-black)
- Surface: #121212 or #1A1A1A
- Primary accent: #FFD700 (yellow)
- Secondary accent: #1E90FF (dodger blue)
- Font: Varela Round

## Dependencies

- Flutter (latest stable)
- Provider (state management)
- flutter_secure_storage (secure credential storage)
- wireguard_flutter (WireGuard tunnel management)
- system_tray (Linux system tray)
- flutter_local_notifications (Android persistent notifications)
- http (API requests)
- google_fonts (Varela Round font)
- pointycastle (X25519 key generation)
- connectivity_plus (network state)

## Building

### Prerequisites

- Flutter SDK installed (https://flutter.dev/docs/get-started/install)
- Android SDK (for Android build)
- Linux development tools (for Linux build)

### Android

1. Ensure you have Android Studio installed and an Android device/emulator set up.
2. Run:
   ```bash
   flutter build apk --release
   ```
3. The APK will be available at `build/app/outputs/flutter-apk/app-release.apk`

### Linux

1. Ensure you have the necessary dependencies for building Flutter Linux apps:
   ```bash
   sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
   ```
2. Run:
   ```bash
   flutter build linux --release
   ```
3. The binary will be available at `build/linux/x64/release/bundle/`

## Running

### Android

1. Install the APK on your device:
   ```bash
   flutter install
   ```
2. Grant the necessary permissions (especially for VPN and notification access).

### Linux

**Important**: The WireGuard interface requires root privileges to create. You have two options:

#### Option 1: Run with sudo (not recommended for security)

```bash
sudo ./build/linux/x64/release/bundle/vpn
```

#### Option 2: Set up polkit to allow your user to manage WireGuard without password

Create a file `/etc/polkit-1/rules.d/10-vpn.rules` with the following content:

```javascript
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.NetworkManager.wireguard" ||
         action.id == "org.freedesktop.NetworkManager.settings.modify.system" ||
         action.id == "org.freedesktop.NetworkManager.settings.modify.own") &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
```

Then add your user to the wheel group (or adjust the group as needed):

```bash
sudo usermod -aG wheel $USER
```

After that, you can run the app without sudo:

```bash
./build/linux/x64/release/bundle/vpn
```

## Notes

- This app uses the Proton VPN API. If the API changes, the app may break.
- The kill switch feature is currently a placeholder and needs to be implemented using platform-specific code.
- The system tray and persistent notification are basic implementations and can be enhanced.
- For WireGuard key generation, we use the `pointycastle` package to generate X25519 key pairs.
- The app stores credentials securely using `flutter_secure_storage`.

## Troubleshooting

- If you encounter issues with the WireGuard connection, ensure that the WireGuard kernel module is loaded (`sudo modprobe wireguard`).
- On Linux, check the logs with `journalctl -u wg-quick@*` or use `wg show` to see the interface status.
- On Android, ensure that the VPN permission is granted and that the VPN service is started.

## License

This project is open source and available under the MIT License.