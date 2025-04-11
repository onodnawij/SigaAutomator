name: Flutter Release Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    name: Build Flutter APK & Windows Installer
    runs-on: windows-latest

    env:
      STORE_PASSWORD: ${{ secrets.STORE_PASSWORD }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.29.2'
          cache: true

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Cache Gradle & Android build
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
            ~/.android/build-cache
          key: gradle-${{ runner.os }}-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
          restore-keys: gradle-${{ runner.os }}-

      - name: Install dependencies
        run: flutter pub get

      - name: Create .env file
        run: |
          echo "SUPABASE_PROJ=${{ secrets.SUPABASE_PROJ }}" >> .env
          echo "SUPABASE_KEY=${{ secrets.SUPABASE_KEY }}" >> .env
          echo "TELEGRAM_BOT_TOKEN=${{ secrets.TELEGRAM_BOT_TOKEN }}" >> .env
          echo "TELEGRAM_CHAT_ID=${{ secrets.TELEGRAM_CHAT_ID }}" >> .env
          echo "KEYSTORE_FILE=${{ secrets.KEYSTORE_FILE }}" >> .env
          echo "STORE_PASSWORD=${{ secrets.STORE_PASSWORD }}" >> .env
          echo "KEY_PASSWORD=${{ secrets.KEY_PASSWORD }}" >> .env
          echo "KEY_ALIAS=${{ secrets.KEY_ALIAS }}" >> .env

      - name: Decode and decrypt keystore zip
        run: |
          echo "${{ secrets.KEYSTORE_ZIP }}" | base64 -d > keystore.zip.gpg
          gpg --batch --yes --passphrase "${{ secrets.STORE_PASSWORD }}" --output keystore.zip --decrypt keystore.zip.gpg
          unzip -o keystore.zip -d android/app

      - name: Build APK (split per ABI)
        run: flutter build apk --split-per-abi --dart-define-from-file=.env

      - name: Rename APKs
        shell: bash
        run: |
          VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //g' | cut -d"+" -f1)
          mkdir renamed-apks
          for file in build/app/outputs/flutter-apk/app-*-release.apk; do
            abi=$(basename "$file" | cut -d'-' -f2)
            cp "$file" "renamed-apks/SigaAutomator-${VERSION}_${abi}.apk"
          done

      - name: Build Windows app
        run: flutter build windows --dart-define-from-file=.env

      - name: Modify Inno Setup Script with version and output path
        shell: bash
        run: |
          VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //g' | cut -d"+" -f1)
          OUTPUT_PATH=$(pwd | sed 's/\\/\//g')  # Convert backslashes for Windows path
          sed -i "s/^AppVersion=.*/AppVersion=${VERSION}/" build_tools/pack_windows.iss
          sed -i "s|^OutputDir=.*|OutputDir=\"${OUTPUT_PATH}/windows-installer\"|" build_tools/pack_windows.iss
          sed -i "s/^OutputBaseFilename=.*/OutputBaseFilename=SigaAutomator-${VERSION}_win_64/" build_tools/pack_windows.iss
          mkdir -p windows-installer

      - name: Install Inno Setup
        run: choco install innosetup --yes

      - name: Build Windows Installer
        run: iscc build_tools\\pack_windows.iss

      - name: Upload APK Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: sigaautomator-apks
          path: renamed-apks

      - name: Upload Windows Installer
        uses: actions/upload-artifact@v4
        with:
          name: sigaautomator-windows-installer
          path: windows-installer/*.exe
