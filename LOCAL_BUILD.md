# Lokale Build-Anleitung

Diese Anleitung baut LiveWallpaper so, dass die App lokal dauerhaft funktioniert, auch ohne Apple Developer Account.

## Kurzfassung

```sh
cd /Users/julianfink/Documents/new-world/LiveWallpaper
chmod +x Scripts/build-local.sh
Scripts/build-local.sh
```

Danach liegt die App hier:

```text
/Users/julianfink/Documents/new-world/LiveWallpaper/build/Release/LiveWallpaper.app
```

Kopiere oder verschiebe diese App nach:

```text
/Applications/LiveWallpaper.app
```

Starte sie danach einmal aus `/Applications`. Wenn du `Start at Login` aktivierst, bleibt der Login-Item-Pfad stabil.

Wenn `SMAppService.mainApp` für einen lokalen/ad-hoc signierten Build `notFound` meldet, nutzt LiveWallpaper automatisch einen lokalen LaunchAgent-Fallback in `~/Library/LaunchAgents/com.julianfink.LiveWallpaper.login.plist`.

## Warum nach /Applications?

macOS Login Items merken sich die App-Bundle-Identität und den App-Pfad. Wenn du die App aus `DerivedData` oder einem temporären Build-Ordner startest, kann der Start-at-Login-Eintrag später ins Leere zeigen.

Für lokalen Dauerbetrieb ist daher empfehlenswert:

1. Release bauen.
2. `LiveWallpaper.app` nach `/Applications` legen.
3. App aus `/Applications` starten.
4. In der App `Start at Login` aktivieren.

Wenn du später eine neue Version baust, ersetze die App in `/Applications`, starte diese neue Kopie einmal manuell und prüfe den Toggle erneut.

Der Start-at-Login-Toggle bevorzugt `SMAppService.mainApp`. Falls macOS diese lokale App-Kopie nicht über ServiceManagement registrieren kann, schreibt und lädt die App stattdessen einen User-LaunchAgent. In System Settings erscheint dieser Fallback unter `App Background Activity`, nicht zwingend in der oberen `Open at Login`-Liste. Das ist für lokale Nutzung robust; für öffentliche Distribution bleibt Developer-ID-Signierung plus Notarization der sauberere Weg.

## Ohne Apple Developer Account

Das Script signiert ad-hoc mit:

```sh
codesign --sign -
```

Das reicht für die lokale Nutzung auf deinem Mac. Für andere Nutzer kann Gatekeeper trotzdem warnen, weil die App nicht mit Developer ID signiert und nicht notarisiert ist.

## Mit Apple Developer Account

Für öffentliche Distribution:

1. Bundle Identifier im Xcode-Projekt auf deine echte Reverse-DNS-ID setzen.
2. `DEVELOPMENT_TEAM` in Xcode setzen.
3. Release mit Developer ID Application signieren.
4. Archiv notarizen.
5. App staplen oder in ein signiertes DMG packen.

Beispielhaft:

```sh
xcodebuild -project LiveWallpaper.xcodeproj -scheme LiveWallpaper -configuration Release archive -archivePath build/LiveWallpaper.xcarchive
xcrun notarytool submit build/LiveWallpaper.zip --keychain-profile YOUR_PROFILE --wait
xcrun stapler staple /Applications/LiveWallpaper.app
```

Passe die Befehle an dein Zertifikat, dein Notary-Profil und dein Distributionsformat an.

## Dock-Icon vs. Menüleisten-App

LiveWallpaper ist produktionsnah als Menüleisten-App gebaut. Deshalb ist `LSUIElement` aktiv und die App erscheint nicht im Dock.

Sichtbare Orte:

- Menüleiste
- Finder-App-Icon
- Login Items in den Systemeinstellungen

Wenn du während der Entwicklung ein Dock-Icon möchtest, setze in `LiveWallpaper/Info.plist` den Wert von `LSUIElement` temporär auf `false` oder entferne den Key.
