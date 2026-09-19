# CLAUDE.md

## Project Overview

GolfBuddy — an iOS app that helps golfers coordinate weekend rounds with friends. Built with SwiftUI targeting iOS 17+.

### Key Features
- User profiles with handicap and home course
- Friend requests and friend management
- Weekend status: "Looking to Play", "Already Playing", "Seeking an Additional Player"
- Visibility controls (hide status from friends)
- Optional sharing of course and playing partners
- 20 public golf courses within 30 miles of Chicago

## Architecture

SwiftUI app using MVVM with a singleton `DataService` for state management.

```
GolfBuddy/
  App/              - App entry point (GolfBuddyApp.swift)
  Models/           - User, Course, FriendRequest, WeekendStatus
  Services/         - DataService (state), CourseService (course data)
  Theme/            - AppTheme (green + cream color system)
  Views/
    Auth/           - Login / Sign Up
    Profile/        - Profile display and editing
    Friends/        - Friends list, requests, search/add
    Status/         - Weekend status dashboard and setter
    Courses/        - Course browsing and details
```

## Development

- **Platform**: iOS 17+
- **Framework**: SwiftUI
- **Language**: Swift 5.9+
- **Open in Xcode**: Open the `GolfBuddy/` folder or create a new Xcode project and add the source files
- **Build**: Cmd+B in Xcode
- **Run**: Cmd+R in Xcode (Simulator or device)

## CalendarCaddy API (v1)

The shared backend for the iOS app and the Muse connector, in `functions/`:

- `functions/src/api.ts` — single HTTPS Cloud Function (`api`) with routes:
  `GET /health`, `POST /v1/teetimes/search`, `GET /v1/friends/looking`
- `functions/src/teetimes.ts` — `TeeTimeProvider` abstraction (mirrors the iOS
  protocol). `MockTeeTimeProvider` is active until the Lightspeed partnership
  is signed; `LightspeedTeeTimeProvider` is the drop-in (auto-selected when
  `LIGHTSPEED_CLIENT_ID`/`LIGHTSPEED_CLIENT_SECRET` are set).
- Auth: Firebase ID token (`Authorization: Bearer`) or service API key
  (`X-API-Key` = `CALENDARCADDY_SERVICE_KEY`) for server-to-server callers.
- Full contract: `docs/calendarcaddy-api.yaml` (OpenAPI 3.0).
- Deploy: `cd functions && npm run deploy` (Firebase).

## Code Style

- SwiftUI with MVVM pattern
- `@EnvironmentObject` for dependency injection of DataService
- Green (#2E8B38) and cream (#FAF5E6) color palette defined in AppTheme
- Rounded design system with card-based layouts
- Follow consistent naming conventions
- Keep functions focused and single-purpose
