# Bundesbank Idle

Idle-Aufbauspiel rund um die Euro-Herstellung, gebaut mit **Godot 4.3**.
Fan-Spiel ohne Verbindung zur Deutschen Bundesbank.

APK: https://github.com/robertpahl1987-creator/bundesbank-idle/releases/latest/download/BundesbankIdle.apk

- `godot/` – das Spiel (`main.gd` Logik und Menüs, `world.gd` 3D-Werk)
- `keys/app.keystore` – Signaturschlüssel, damit Updates zur installierten App passen
- `legacy-webview-app/` – frühere HTML-Version (wird nicht mehr gebaut)
- `.github/workflows/build-apk.yml` – baut bei jeder Änderung automatisch die APK
