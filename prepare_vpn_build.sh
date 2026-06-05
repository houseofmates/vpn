#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Starting VPN‑app build preparation on $(hostname)"
echo "──────────────────────────────────────────────────────────────"

########################################
# 1. Remove Flutter snap if present
########################################
echo "🗑️  Removing Flutter snap (if installed)…"
if snap list flutter &>/dev/null; then
    sudo snap remove flutter
    hash -r  # clear command location cache
else
    echo "   Flutter snap not found, skipping."
fi

########################################
# 2. Install Flutter from official tarball
########################################
FLUTTER_HOME="$HOME/flutter"

if [ ! -d "$FLUTTER_HOME/bin" ]; then
    echo "📦  Downloading Flutter stable tarball…"
    FLUTTER_TAR="flutter_linux_3.24.3-stable.tar.xz"
    cd "$HOME"
    wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_TAR}"
    tar xf "$FLUTTER_TAR"
    # The tarball extracts to a directory named "flutter"
    if [ -d "flutter" ]; then
        mv flutter "$FLUTTER_HOME"
    else
        echo "❌  Extraction failed – no 'flutter' directory found."
        exit 1
    fi
    rm "$FLUTTER_TAR"
else
    echo "✅  Flutter already present in $FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"
echo "🔹  Using Flutter: $($FLUTTER_HOME/bin/flutter --version 2>/dev/null || true)"

########################################
# 3. Install system packages for Linux build
########################################
echo "📥  Installing required APT packages…"
sudo apt-get update
sudo apt-get install -y \
    libsecret-1-dev \
    libayatana-appindicator3-dev \
    libgtk-3-dev \
    libglib2.0-dev \
    clang \
    libc++-dev \
    make \
    pkg-config \
    wireguard          # provides wg command (optional, we’ll use pure‑Dart keys)

########################################
# 4. Prepare Android SDK
########################################
ANDROID_SDK="$HOME/android-sdk"
CMDLINE_TOOLS="$ANDROID_SDK/cmdline-tools"
LATEST_TOOLS="$CMDLINE_TOOLS/latest"

echo "🤖  Configuring Android SDK at $ANDROID_SDK…"
flutter config --android-sdk "$ANDROID_SDK"

if [ ! -d "$LATEST_TOOLS" ]; then
    echo "⬇️  Installing Android command‑line tools…"
    mkdir -p "$CMDLINE_TOOLS"
    cd "$CMDLINE_TOOLS"
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
    unzip -q commandlinetools-linux-9477386_latest.zip
    # The zip extracts into a folder called "cmdline-tools" – rename it to "latest"
    if [ -d "cmdline-tools" ]; then
        mv cmdline-tools latest
    else
        echo "❌  Unexpected zip structure – 'cmdline-tools' directory not found."
        exit 1
    fi
    rm commandlinetools-linux-9477386_latest.zip
    cd "$OLDPWD"
else
    echo "✅  Android command‑line tools already present."
fi

echo "📜  Accepting Android SDK licences…"
yes | sudo "$LATEST_TOOLS/bin/sdkmanager" --licenses || true
# Note: --licenses may return non‑zero even on success, we ignore the exit code.

########################################
# 5. Write Gradle configuration files
########################################
echo "📝  Writing Gradle configuration…"

cat > android/build.gradle.kts <<'GRADLE_EOF'
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
GRADLE_EOF

cat > android/app/build.gradle.kts <<'GRADLE_EOF'
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.vpn"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        coreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.example.vpn"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.0.4"
}

flutter {
    source = "../.."
}
GRADLE_EOF

########################################
# 6. Patch wireguard_service.dart for real X25519 key generation
########################################
WP_FILE="lib/services/wireguard_service.dart"
if [ -f "$WP_FILE" ]; then
    echo "🔧  Patching $WP_FILE for proper key generation…"
    # Backup the original
    cp "$WP_FILE" "${WP_FILE}.bak.$(date +%s)"

    # Replace the whole generateX25519KeyPair function
    sed -i '/^  Future<Map<String, String>> generateX25519KeyPair() async {/,/^  }/c\
  /// Generates a new X25519 key pair for WireGuard using pointycastle.\
  Future<Map<String, String>> generateX25519KeyPair() async {\
    final keyPairGenerator = X25519KeyPairGenerator();\
    final secureRandom = SecureRandom('"'"'Fortuna'"'"');\
    final seed = KeyGenerationParameters(secureRandom, 256);\
    keyPairGenerator.init(seed);\
    final asymmetricKeyPair = keyPairGenerator.generateKeyPair();\
    final privKey = (asymmetricKeyPair.privateKey as X25519PrivateKey).encode();\
    final pubKey = (asymmetricKeyPair.publicKey as X25519PublicKey).encode();\
    import '"'"'dart:convert'"'"';\\
    final privB64 = base64UrlEncode(privKey);\
    final pubB64 = base64UrlEncode(pubKey);\
    return {'"'"'privateKey'"'"': privB64, '"'"'publicKey'"'"': pubB64};\
  }' "$WP_FILE"

    # Add pointycastle import if missing
    if ! grep -q "import 'package:pointycastle/pointycastle.dart';" "$WP_FILE"; then
        sed -i "/^import 'package:flutter\/material.dart';/a import 'package:pointycastle/pointycastle.dart';" "$WP_FILE"
    fi
    echo "✅  Patch applied."
else
    echo "⚠️  $WP_FILE not found – skipping key generation patch."
fi

########################################
# 7. Get Flutter dependencies
########################################
echo "📦  Running flutter pub get…"
flutter pub get

########################################
# 8. Build Linux release
########################################
echo "🐧  Building Linux release…"
flutter build linux --release

########################################
# 9. Build Android APK release
########################################
echo "📱  Building Android APK release…"
flutter build apk --release

echo ""
echo "✅  All builds completed successfully!"
echo "   Linux bundle: build/linux/x64/release/bundle/"
echo "   Android APK : build/app/outputs/flutter-apk/app-release.apk"
