# Lume — build & run

Native SwiftUI iOS project (iOS 26+, Liquid Glass). `Lume.xcodeproj` is checked in, but it's generated from `project.yml` via **XcodeGen** — if you change `project.yml` (new files, new targets, entitlements), regenerate before building:

```bash
brew install xcodegen   # once
xcodegen generate
```

## 1. Open and set your team

```bash
open Lume.xcodeproj
```

In Xcode, set the Apple Developer **Team** on all three targets — **Lume**, **LumeWidgets**, **LumeShare** — under *Signing & Capabilities*. They must match: the app and its two extensions share an App Group (`group.com.dodopok.lume`).

If Xcode complains the App Group isn't registered to your team, enable "Automatically manage signing" — it'll provision it.

## 2. Run

Pick the **Lume** scheme, a phone simulator or device running iOS 26+, and Run. First launch goes straight into onboarding.

## What's real vs. what needs review

- **All data is local** (SwiftData, stored in the app group container) — nothing talks to a backend.
- **Live Activity / Dynamic Island**: real ActivityKit, starts on the first water log of the day, "+300" works straight from the Dynamic Island via an App Intent.
- **Calendar**: "Conectar" on the Agenda pulls in real events from the iPhone's Calendar app (EventKit) — the native equivalent of "conectar Google Agenda": once a Google account is added under iPhone Settings → Calendar, it shows up here automatically, read-only.
- **Wishlist link paste**: Apple's LinkPresentation for title/image, plus a best-effort scrape for price — falls back to manual entry when a shop blocks it, matching the original design intent. The Share Extension (`LumeShare`) sends links here from any other app.
- **Books/Movies**: Google Books search backs the Livros tab; see `Lume/Services/GoogleBooksService.swift` and `EntertainmentSearchService.swift` for what each integration actually calls.
- **Fonts**: the original mockup specified Newsreader/Nunito Sans/IBM Plex Mono. This build uses Apple's own equivalents instead — New York (serif), SF Pro, SF Mono — to avoid bundling/licensing third-party font files sight-unseen. Swap them for the real fonts in `Lume/Design/LumeType.swift` if you'd rather.
- **Not built**: push notifications, iCloud/multi-device sync — data intentionally stays on-device until an explicit future opt-in.

## Project layout

```
project.yml       — XcodeGen spec (source of truth for the Xcode project)
Lume.xcodeproj/    — generated project (regenerate with `xcodegen generate`)
Lume/              — app target (Features/, Design/, Services/, App/)
LumeWidgets/       — widget extension (Live Activity + Dynamic Island)
LumeShare/         — Share Extension
Shared/            — SwiftData models + tokens compiled into all three targets
```

Large parts of this were written without access to a Mac/Xcode, so if something doesn't build, it's most likely a small SwiftUI/SwiftData/ActivityKit API signature mismatch — check there first.
