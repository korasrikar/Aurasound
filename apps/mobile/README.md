# AuraSound mobile (Flutter) — starter

Starter project for the Android and iOS app. It contains the app skeleton and a
**basic player module** (`lib/player/`) that the rest of the app builds on.

> **Verification status:** the Dart code in this folder was written in a sandbox
> without the Flutter/Dart SDK, so it has **not been compiled or tested yet**.
> The first task after cloning is to run the commands in "Verify" below and fix
> anything the analyzer reports.

## Layout

```
apps/mobile/
├── pubspec.yaml / analysis_options.yaml
├── lib/
│   ├── main.dart                 # wires the engine and controller into the app
│   ├── app.dart                  # MaterialApp, light/dark theme
│   ├── data/demo_catalog.dart    # placeholder tracks (replace with the playback API)
│   ├── player/                   # THE PLAYER MODULE — no UI code, no network code
│   │   ├── track.dart            # Track model
│   │   ├── playback_queue.dart   # pure-Dart queue: order, shuffle, repeat, cursor
│   │   ├── playback_engine.dart  # abstract engine interface (the seam for tests and swaps)
│   │   ├── just_audio_engine.dart# production engine on just_audio (ExoPlayer / AVPlayer)
│   │   ├── playback_snapshot.dart# immutable state the UI renders
│   │   └── player_controller.dart# app-facing commands; owns the queue
│   └── features/
│       ├── home/home_screen.dart
│       └── player/player_screen.dart   # mini player + full-screen player
└── test/player/                  # unit tests (queue logic; controller with a fake engine)
```

Layering rule: `features/` depends on `player/`; `player/` depends on nothing in
`features/`. The engine is the only file that imports `just_audio`, so the audio
stack can be swapped (or wrapped by `audio_service`) without touching the UI.

## Design choices

- **Gapless:** the play order is one `ConcatenatingAudioSource`. The native
  player transitions between items without re-creating the decoder.
- **Shuffle and repeat live in Dart**, not in the engine. This keeps the queue
  logic testable and identical across platforms. Shuffle reorders by rebuilding
  the engine sequence (keeping the current position); add/remove edit the
  sequence in place so playback does not glitch.
- **Previous restarts the track** when more than 3 seconds in (standard behaviour).

## Not implemented yet (tracked in docs/06-roadmap-and-team.md)

| Feature | Plan |
|---|---|
| Background audio + lock-screen controls | Wrap the engine in an `audio_service` `BaseAudioHandler`; declare the Android foreground service and iOS `audio` background mode. **Required before any real release.** |
| Crossfade | Two `AudioPlayer`s with a volume ramp at track boundaries. |
| Equalizer | `AudioPipeline` with `AndroidEqualizer` (and the Darwin equivalent once verified). |
| DRM (Widevine / FairPlay / PlayReady) | Validate in a spike whether just_audio's DRM hooks are enough; otherwise a native Media3 / AVPlayer path via platform channel. |
| Hi-Res FLAC, ALAC | Verify on low-end Android devices; device capability detection decides the ladder. |
| Offline downloads | Encrypted files plus Keystore/Secure Enclave key wrapping; a separate `downloads/` module. |

## Run it

Prerequisites: Flutter 3.22 or newer (Dart 3.4+).

```bash
cd apps/mobile

# 1. The platform folders (android/, ios/) are not in this starter. Generate them in
#    a scratch directory and copy them in, so existing lib/ files are not touched:
flutter create --platforms=android,ios --org in.aurasound --project-name aurasound /tmp/aurasound_scaffold
cp -r /tmp/aurasound_scaffold/android /tmp/aurasound_scaffold/ios .

# 2. Fetch packages
flutter pub get

# 3. Verify (the step that has not been run yet)
dart format --set-exit-if-changed lib test
flutter analyze
flutter test

# 4. Run on a device or emulator
flutter run
```

Platform notes:

- `just_audio` supports Android, iOS, and macOS (and web). Windows and Linux desktop need a different engine. The desktop companion is planned for Phase 3.
- Android needs `INTERNET` permission (the generated manifest includes it).

## Verify checklist

- [ ] `flutter analyze` reports no errors (warnings are acceptable for the first pass)
- [ ] `flutter test` passes (queue ordering, repeat, edit operations, controller behaviour)
- [ ] Demo tracks play gaplessly between tracks on a real Android device
- [ ] Shuffle toggle keeps the current position and does not restart the track
- [ ] Lock-screen controls work (only after the audio_service integration)
