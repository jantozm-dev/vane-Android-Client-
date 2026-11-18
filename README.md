# Vane for Android

An unofficial Android client for [Vane](https://github.com/ItzCrazyKns/Vane)
(formerly Perplexica), the open-source, self-hosted AI answer engine. Built
with Flutter and Material 3.

All traffic stays between this app and **your own** Vane instance — no
third-party servers are involved.

## Features

- Smooth Material 3 / Material You UI with dynamic color, light & dark themes
- Streaming answers over the Vane Search API (`POST /api/search` with
  `stream: true`)
- Cited sources shown as chips; tap for title, snippet, and open-in-browser
- Follow-up questions with conversation history
- Locally saved search history (per device) with delete + undo
- Provider picker for chat and embedding models
- Search options: sources (web / academic / discussions), optimization mode
  (speed / balanced / quality), custom system instructions

## Requirements

- A running Vane Docker instance reachable from your phone
  (e.g. `http://192.168.1.50:3000`)
- At least one chat model **and** one embedding model configured in the Vane
  dashboard

> If Vane is running on the same machine that runs Docker Desktop, use the
> LAN IP of that machine, not `localhost`, when entering the address.

## Building

```bash
flutter pub get
flutter build apk --release
```

Or run on a connected device:

```bash
flutter run
```

## Connecting

1. Start the app and enter your instance address on the connect screen
   (for example `192.168.1.50:3000`).
2. Pick a chat model and an embedding model in **Settings → Models**.
3. Ask away. Sources stream in first, then the cited answer.

## Project layout

```
lib/
  main.dart               App bootstrap and theming
  models/                 API and history data models
  services/               Settings persistence and the Vane HTTP/NDJSON client
  storage/                Local history store (SharedPreferences)
  state/                  App state: connection, streaming session, history
  screens/                Root tabs, connect gate, search thread, history, settings
  widgets/                Composer, markdown answer renderer, source sheets
```

MIT licensed, same as upstream Vane.
