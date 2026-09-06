# Battle Royale Mobile

A free-to-build, original battle-royale prototype for Android made with Godot 4.5.1. It is inspired by the mobile battle-royale genre, but does not use Free Fire's copyrighted characters, maps, logos, sounds, or other proprietary assets.

## Current features

- Playable top-down battle royale arena
- 18 enemy bots with basic chase and shooting AI
- Player health, ammo, kills and elimination state
- Shooting with mouse on desktop
- Touch-friendly movement buttons and FIRE button
- Ammo and medkit pickups
- Shrinking safe zone with outside-zone damage
- Victory when all bots are eliminated
- Automatic Android APK build through GitHub Actions
- No paid assets or external services required for the prototype

## Run locally

1. Install Godot 4.5.1.
2. Open the project folder.
3. Open `Main.tscn`.
4. Press Play.

Desktop controls: WASD/arrow keys to move and hold the left mouse button to shoot.

## Android APK

Open GitHub → Actions → **Build Android APK** → **Run workflow**. When the workflow finishes, download the `BattleRoyaleMobile-APK` artifact.

## Next development stages

1. Replace procedural shapes with original 3D models and animations.
2. Add weapons, reloads, inventory and weapon switching.
3. Add buildings, vehicles, parachute/drop system and larger map.
4. Add multiplayer networking with a dedicated server.
5. Add lobby, matchmaking, accounts and progression.
6. Add original audio, VFX, cosmetics and optimization for low-end Android phones.
