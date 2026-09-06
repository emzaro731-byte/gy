# Battle Zone: Offline

An original offline 3D battle-royale game for Android made with Godot 4.5.1.

## Current features

- Fully offline gameplay
- Procedural 3D world with buildings, trees and pickups
- Player movement, sprint, shooting and reload
- 20 offline enemy bots with chase and shooting AI
- Health, ammo, kills and enemy HUD
- Mobile FIRE, RELOAD and SPRINT controls
- Shrinking safe zone and outside-zone damage
- Victory and defeat states
- Android APK build through GitHub Actions
- No accounts, networking, Supabase, Firebase, ads or remote APIs
- Original procedural game content; no Free Fire proprietary assets

## Run locally

1. Install Godot 4.5.1.
2. Open the project folder.
3. Open `Main3D.tscn`.
4. Press Play.

## Android APK

GitHub Actions builds `BattleRoyaleMobile.apk` automatically from the `main` branch. The workflow installs Godot 4.5.1 Android export templates, Java 17, Android SDK Platform 35 and a CI debug keystore before exporting the APK.

## Development

The project is being expanded with original 3D models, animations, weapons, effects, vehicles, inventory and Android optimization while remaining offline-first.
