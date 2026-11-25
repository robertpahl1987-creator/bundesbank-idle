# Bundesbank Idle

Idle-Aufbauspiel rund um die Euro-Herstellung, gebaut mit der Spiele-Engine **Godot 4.3**:
3D-Werk mit Münzhalle, Druckhalle, Tresorlager, Fuhrpark, Sicherheitsmerkmalen und
Schutz gegen Überfälle. Fan-Spiel ohne Verbindung zur Deutschen Bundesbank.

## Installieren

APK direkt laden:
https://github.com/robertpahl1987-creator/bundesbank-idle/releases/latest/download/BundesbankIdle.apk

## Automatische Updates

Beim Start prüft das Spiel, ob es eine neue Version gibt, und bietet sie zum Herunterladen an.
Der Spielstand wird automatisch gespeichert (alle 5 Sekunden, nach jedem Kauf und beim Schließen).

## Aufbau

- `godot/` – das Spiel (Godot-Projekt, Hauptdateien `main.gd` und `world.gd`)
- `keys/app.keystore` – Signaturschlüssel, damit Updates zur installierten App passen
- `legacy-webview-app/` – frühere Version als HTML-App (wird nicht mehr gebaut)
- `.github/workflows/build-apk.yml` – baut bei jeder Änderung automatisch die APK
