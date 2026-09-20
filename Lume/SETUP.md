# Lume — build & run

This is a native SwiftUI iOS project (iOS 26+, Liquid Glass) generated as source only — there's no `.xcodeproj` checked in, because it was written in a Linux sandbox with no Xcode available to produce/verify one. You'll generate it with **XcodeGen** on your Mac; that's a five-minute, one-time step.

## 1. Install tools (once)

```bash
brew install xcodegen
```

Xcode 26+ required (for the iOS 26 SDK / Liquid Glass APIs).

## 2. Generate and open the project

```bash
cd Lume
xcodegen generate
open Lume.xcodeproj
```

## 3. Set your team

In Xcode, select the **Lume** target → *Signing & Capabilities* → set your Apple Developer **Team** for both the `Lume` and `LumeWidgets` targets (they must match — they share an App Group).

The App Group (`group.com.dodopok.lume`) and Sign in with Apple capability are already declared in `Lume/Lume.entitlements` / `LumeWidgets/LumeWidgets.entitlements`. If Xcode complains the App Group isn't registered to your team, enable "Automatically manage signing" — it'll provision it.

## 4. Run

Pick the **Lume** scheme, a phone simulator or device running iOS 26+, and Run. First launch goes straight into onboarding.

## What's real vs. what needs your review

- **All data is local** (SwiftData, stored in the app group container) — nothing talks to a backend.
- **Live Activity / Dynamic Island**: real ActivityKit, starts on the first water log of the day, "+300" works straight from the Dynamic Island via an App Intent.
- **Calendar**: "Conectar" on the Agenda pulls in real events from the iPhone's Calendar app (EventKit) — this is the native equivalent of "conectar Google Agenda": once she's added her Google account under Settings → Calendar, it shows up here automatically, read-only.
- **Wishlist link paste**: uses Apple's LinkPresentation for title/image (reliable almost everywhere) and a best-effort regex scrape of the page for price (works on many shops, not all — falls back to manual entry exactly like the design calls for).
- **Fonts**: the mockup specifies Newsreader/Nunito Sans/IBM Plex Mono. Rather than bundle and license-check third-party font files sight-unseen, this build uses Apple's own equivalents — New York (serif) for headlines, SF Pro for UI text, SF Mono for the tracked-out labels. Same warm-editorial pairing, zero risk of a broken font embed. If you'd rather have the exact original fonts, drop the `.ttf` files into `Lume/Resources/Fonts`, register them in `Info.plist` under `UIAppFonts`, and swap the `.system(design:)` calls in `Design/LumeType.swift` for `.custom(_:size:)`.
- **Not yet built**: push notifications / iCloud sync (the design explicitly says data stays on-device "until you choose to sync," so this was left as a future opt-in rather than guessed at).

## Project layout

```
Lume/
  project.yml          — XcodeGen spec (source of truth for the Xcode project)
  Lume/                — app target (Features/, Design/, Services/, App/)
  LumeWidgets/          — widget extension (Live Activity + Dynamic Island)
  Shared/               — SwiftData models, color tokens, date/currency-adjacent
                          shared code compiled into both targets
```

Nothing here has been compiled or run — I don't have Xcode/macOS in this sandbox. Please build it and tell me what breaks; SwiftUI/SwiftData/ActivityKit API surfaces are the most likely place for a small signature mismatch to hide.
