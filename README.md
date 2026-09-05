# Verse — Local Music Player

A sleek, local-first music player built with Flutter, targeting **Android** and **Linux Desktop** from a single codebase.

**Design Reference:** Spotify (layout, navigation, mini-player) + Apple Music (synced lyrics UX).

---

## 🎵 Features

- **Local-First & Offline:** Scans and plays audio files directly on your device (`.mp3`, `.flac`, `.wav`, `.m4a`, `.ogg`) with zero network dependencies for playback.
- **Synced Lyrics:** Real-time line-by-line synced lyrics using `.lrc` files (bundled local `.lrc` or auto-fetch from public LRCLIB API with offline caching).
- **Embedded Artwork Extraction:** Extracts embedded ID3/APIC artwork directly from audio files with dynamic UI theming.
- **Cross-Platform Single Codebase:** Platform-agnostic `LibraryScanner` architecture with tailored native backends for Android (MediaStore via `on_audio_query`) and Linux (fast directory walk with ID3 parsing).
- **Modern State Management:** Powered by `flutter_riverpod`.

---

## 🚀 Version Roadmap

- [x] **v0.1 — Skeleton & Platform Scan:** Platform-agnostic `LibraryScanner` interface, Android & Linux scanning backends, data models (`Song`, `Album`, `Artist`), verification UI.
- [x] **v0.2 — Basic Playback & Dynamic UI:** `just_audio` engine integration, native Linux `libmpv` backend, persistent floating mini-player, animated equalizer, and full-screen Now Playing modal sheet.
- [x] **v0.3 — Metadata & Art Extraction:** SQLite local index (`sqflite`/`sqflite_common_ffi`), disk-cached cover art extraction, incremental re-scans via modification timestamps, and `AlbumArtWidget`.
- [ ] **v0.4 — Spotify-like Shell UI:** Bottom navigation, tabs, persistent mini-player, and full-screen Now Playing screen with blurred background.
- [ ] **v0.5 — Queue & Background Playback:** Up-next queue management, shuffle/repeat, and Android `audio_service` lockscreen/notification controls.
- [ ] **v0.6 — Lyrics: Parsing & Local Files:** Timed `.lrc` parser, local file matching, synchronized auto-scrolling, and tap-to-seek.
- [ ] **v0.7 — Lyrics: API Fetch & Caching:** LRCLIB fallback lookup with persistent SQLite caching.
- [ ] **v0.8 — Search & Settings:** Instant library search and configurable music directories.
- [ ] **v0.9 — Resilience Pass:** Degraded input handling and comprehensive test coverage.
- [ ] **v1.0 — Polish & Release Candidate:** Release builds for Android APK and Linux binary.

---

## 🛠️ Tech Stack

| Component | Technology |
|---|---|
| Framework | Flutter (3.47+) / Dart (3.13+) |
| State Management | `flutter_riverpod` |
| Local Database | `sqflite` (Android) / `sqflite_common_ffi` (Linux) |
| Audio Engine | `just_audio` + `audio_service` + `just_audio_media_kit` |
| Android Library | `on_audio_query` + `permission_handler` |
| Linux Library | Recursive directory walker + ID3 metadata parsing |
| Target Min Android SDK | API 26 (Android 8.0 Oreo+) |
