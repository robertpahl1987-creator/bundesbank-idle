# Bundesbank Idle

Idle-Aufbauspiel rund um die Euro-Herstellung: 3D-Werk mit Münzhalle, Druckhalle,
Tresorlager, Fuhrpark, Sicherheitsmerkmalen und Schutz gegen Überfälle.
Fan-Spiel ohne Verbindung zur Deutschen Bundesbank.

## Installieren

1. Unter **Releases** die neueste `BundesbankIdle.apk` aufs Handy laden.
2. Öffnen und installieren („Installation aus unbekannten Quellen“ einmal erlauben).

## Automatische Updates

Bei jedem Start fragt die App hier nach einer neuen Version. Gibt es eine,
erscheint „Update verfügbar“ – ein Tipp auf **Installieren** lädt und installiert sie.
Der Spielstand bleibt erhalten. Manuell: im Spiel unter **Bank → App & Updates**.

Jede Änderung an `main` baut automatisch eine neue APK und veröffentlicht sie als Release.

## Spiel ändern

Das komplette Spiel steckt in `app/src/main/assets/index.html`.

Hinweis: Die App wird mit dem Schlüssel `app/debug.keystore` signiert. Er liegt
öffentlich im Repository, damit Updates immer zur installierten App passen.
