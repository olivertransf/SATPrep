# Studium

Native **iOS / iPadOS / macOS** SAT practice app (Swift, SwiftUI) plus a **browser PWA** in [`studium-web/`](studium-web/) (React, TypeScript, Vite) for the same question bank, flashcards, reference material, stats, and offline-friendly assets.

## Links

- **Repository:** https://github.com/olivertransf/Studium  
- **Web app (source):** [`studium-web/`](studium-web/) — build with `npm run build` and host the `dist/` output on any static host (PWA).

## Features

- **Smart filtering**: Program, module, primary class, skill, difficulty, seen status, and Bluebook source
- **Progress**: Track seen questions and correct / incorrect attempts
- **Statistics**: Accuracy overall and by module, difficulty, class, and skill (Settings → Statistics on Apple; Stats tab on web)
- **iCloud sync** (Apple app): Progress across your signed-in devices
- **Full content**: Passages, stems, choices, and explanations; math notation rendered correctly
- **Reference & vocab**: Reference sheets and vocab flashcards
- **Dark mode** and layouts tuned for iPhone and iPad

## Requirements (native app)

- iOS 17.0+ / iPadOS 17.0+ / macOS (see Xcode target)
- Xcode 15.0+
- Swift 5.0+

## Setup (native app)

1. Clone the repository
2. Open `Studium.xcodeproj` in Xcode
3. Enable the **iCloud** capability (Signing & Capabilities)
4. Build and run on a device or simulator

## Setup (web PWA)

```bash
cd studium-web
npm install
npm run dev
```

Production build:

```bash
cd studium-web
npm run build
```

Serve the `studium-web/dist` directory from your host.

## Usage (native)

1. **Practice**: Set filters, then start a quiz from Practice
2. **Answer**: Choose an option and submit to see the explanation
3. **Navigate**: Back / Next between items
4. **Stats**: **Settings → Statistics**
5. **Sync**: Turn on iCloud in Settings to sync progress across devices

## License

MIT License — see [LICENSE](LICENSE).
