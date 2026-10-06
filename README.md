# Star Wars Characters

Flutter Home Assignment — Gini-Apps

A Flutter application that displays Star Wars characters from the SWAPI API with infinite pagination, height-based rows, persistent favorite selection, final height sorting, adaptive layouts, and server-side character search.

## Implementation Status

**All required functionality (F1–F6), technical requirements (T1–T7), and the bonus search functionality were implemented.**

Before submission, the project was validated successfully with:

```text
flutter analyze
No issues found!

flutter test
+11: All tests passed!

flutter build apk --debug
Built build/app/outputs/flutter-apk/app-debug.apk
```

---

## Flutter & Dart Versions

Developed with:

- Flutter 3.47.6 (stable)
- Dart 3.13.5
- Sound null safety enabled

### Android

- compileSdk: 37
- targetSdk: 37
- minSdk: 26

### iOS

- Deployment target: iOS 26.0
- The iOS build was not tested locally because development was performed on Windows without access to macOS/Xcode.

---

## How to Run

### 1. Install dependencies

From the project root:

```powershell
flutter pub get
```

### 2. Start the Android emulator

The project was tested locally using the `Pixel_9a` Android Virtual Device.

Open the first PowerShell terminal and run:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel_9a
```

Wait until the Android emulator has fully started.

### 3. Run the Flutter application

Open a second PowerShell terminal in the project directory.

Verify the available devices:

```powershell
flutter devices
```

During local testing, the emulator device ID was `emulator-5554`.

Run:

```powershell
flutter run -d emulator-5554
```

If the emulator receives a different device ID, use the ID displayed by `flutter devices`.

Alternatively, when only one suitable device is connected:

```powershell
flutter run
```

### 4. Run static analysis

```powershell
flutter analyze
```

### 5. Run automated tests

```powershell
flutter test
```

### 6. Build Android APK

```powershell
flutter build apk --debug
```

The generated APK is located at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

---

## Architecture

The project follows a layered architecture with clear separation between **Data, Domain, and Presentation** responsibilities.

```text
lib/
├── core/
│   └── errors/
├── data/
│   ├── datasources/
│   ├── dtos/
│   └── repositories/
├── domain/
│   ├── models/
│   ├── repositories/
│   └── services/
└── presentation/
    ├── controllers/
    ├── providers/
    ├── screens/
    ├── state/
    └── widgets/
```

### Data Layer

Responsible for external communication and persistence.

- `SwapiApiClient` handles HTTP communication with SWAPI.
- DTOs parse API responses and map them into domain models.
- Repository implementations connect data sources to domain abstractions.
- Favorite persistence is handled through a dedicated local data source using `shared_preferences`.

Widgets never access or parse JSON directly.

### Domain Layer

Contains application models, repository abstractions, and business rules.

Responsibilities include:

- Character and paginated character models.
- Character height parsing.
- Unknown and invalid height handling.
- Height-based sorting.
- Repository interfaces.

### Presentation Layer

Contains:

- Riverpod providers.
- Application controller.
- Immutable UI state.
- Screens and reusable widgets.

Business state is managed outside the widgets.

Dart 3 sealed classes are used to represent application states and failures, and pattern matching is used when handling and rendering those states.

---

## State Management — Riverpod 3

**Riverpod 3** was chosen for state management and dependency injection because it provides predictable state updates, explicit dependency injection, testability, and clear separation between business logic and UI.

The screen renders application state exposed by the controller.

`setState` is not used for business state. Widget-local objects such as `ScrollController` and `TextEditingController` remain presentation concerns.

Dependencies are provided through Riverpod and can be replaced with fake implementations during testing.

---

## Pagination

The application loads the first SWAPI people page on launch.

When the user approaches the bottom of the list, the next page is loaded and appended to the existing characters.

The application **always follows the exact `next` URL returned by SWAPI** and never constructs page URLs manually.

Previously requested URLs are tracked to prevent duplicate page requests.

When `next` becomes `null`, pagination stops and the complete collection is sorted by height.

---

## Character Heights & Sorting

SWAPI represents character height as a string.

Numeric heights are safely parsed and used both for display and for the logical height of each row.

Examples:

```text
Yoda             66 cm  -> 66 px row
Luke Skywalker  172 cm  -> 172 px row
Chewbacca       228 cm  -> 228 px row
```

If the API returns `"unknown"`, `"none"`, or another invalid height value:

- The displayed height is `unknown`.
- The character remains in the list.
- The row uses a fixed height of 80 logical pixels.
- The application does not crash.

Characters remain in the original server order while additional pages are available.

Only after the final page has been loaded is the complete collection sorted from shortest to tallest, with unknown heights placed last.

---

## Favorite

The application supports exactly **one favorite character or no favorite**.

Behavior:

- Tap a character -> it becomes the favorite.
- Tap another character -> it replaces the previous favorite.
- Tap the current favorite again -> the favorite is cleared.

The favorite is identified using the character's SWAPI `url`, rather than its current position in the list.

This keeps the favorite associated with the correct character after pagination, sorting, searching, and application restarts.

The favorite URL is persisted locally using `shared_preferences` and restored before the character list is displayed.

If no favorite has previously been saved, the application starts with no selected favorite.

---

## Loading & Error Handling

The application explicitly handles:

- Initial loading.
- Initial loading failure.
- Loaded content.
- Pagination loading.
- Pagination failure.
- Search loading.
- Search failure.

When another page is loading, the already-loaded list remains available and scrollable.

If loading a subsequent page fails, existing characters are preserved and the failed request can be retried.

The application uses typed failures for network, timeout, server, data, cancellation, and persistence errors.

HTTP requests use configured timeouts.

---

## SWAPI & Fallback

Primary API:

```text
https://swapi.dev/api/
```

Fallback API:

```text
https://swapi.py4e.com/api/
```

The fallback is available when the primary SWAPI service cannot be reached.

Pagination continues to follow the URL supplied by the API rather than generating page URLs manually.

---

## Bonus — Server-Side Search

The bonus search functionality is implemented.

Search uses SWAPI's server-side `?search=` endpoint rather than filtering already-loaded characters locally.

Implemented behavior:

- Server-side search.
- Approximately 300 ms debounce.
- Cancellation or ignoring of stale search requests.
- Paginated search results.
- Infinite scrolling within search results.
- Loading and error states.
- Empty-result state.
- Favorite selection within search results.
- Height sorting after the final search page.
- Clearing the search restores the already-loaded main collection without refetching it.

---

## Adaptive UI

The application uses Material 3 components and is designed for:

- Android and iOS.
- Phones and tablets.
- Portrait and landscape orientations.

Application state is managed outside the screen widget so that orientation changes retain the loaded pages, favorite, search term, and scroll position.

---

# Requirements Checklist

## Functional Requirements

### F1 — List & Infinite Scroll — DONE

- **DONE** — Page 1 loads on launch.
- **DONE** — Server order is preserved while pagination is active.
- **DONE** — The next page loads near the bottom of the list.
- **DONE** — New characters are appended to the existing list.
- **DONE** — The exact server-provided `next` URL is followed.
- **DONE** — Duplicate page requests are prevented.
- **DONE** — Pagination stops when `next` is null.

### F2 — Character Row — DONE

- **DONE** — Character name and height are displayed.
- **DONE** — Row logical height corresponds to numeric character height.
- **DONE** — Unknown/invalid heights display `unknown`.
- **DONE** — Unknown heights use an 80 px row.
- **DONE** — Invalid height values do not crash or remove the character.

### F3 — Loading & Errors — DONE

- **DONE** — Initial loading state.
- **DONE** — Pagination loading state.
- **DONE** — Existing content remains available during pagination.
- **DONE** — Typed error handling.
- **DONE** — Retry behavior for failed requests.
- **DONE** — Already-loaded data is preserved after pagination failure.

### F4 — Sort After Last Page — DONE

- **DONE** — Server order is preserved before the final page.
- **DONE** — Sorting occurs only after `next` becomes null.
- **DONE** — Numeric heights are sorted shortest to tallest.
- **DONE** — Unknown heights are placed last.

### F5 — Favorite — DONE

- **DONE** — Exactly one favorite or no favorite.
- **DONE** — Selecting another character replaces the favorite.
- **DONE** — Tapping the current favorite clears it.
- **DONE** — Favorite is visually distinct.
- **DONE** — Character URL is used as the unique identifier.
- **DONE** — Favorite remains correct after sorting and pagination.
- **DONE** — Favorite works with search results.
- **DONE** — Favorite URL is persisted locally.
- **DONE** — Favorite is restored after restarting the application.

### F6 — Adaptive UI — DONE

- **DONE** — Phone layout.
- **DONE** — Tablet layout.
- **DONE** — Portrait orientation.
- **DONE** — Landscape orientation.
- **DONE** — Material 3 UI.
- **DONE** — Loaded pages are retained during orientation changes.
- **DONE** — Scroll position is retained during orientation changes.
- **DONE** — Favorite is retained during orientation changes.
- **DONE** — Search term is retained during orientation changes.

---

## Technical Requirements

### T1 — Current Flutter — DONE

- **DONE** — Flutter 3.47.6.
- **DONE** — Dart 3.13.5.
- **DONE** — Sound null safety.
- **DONE** — `flutter_lints`.
- **DONE** — Dart 3 sealed classes.
- **DONE** — Pattern matching for application state and errors.
- **DONE** — `flutter analyze` passes with no issues.

### T2 — State Management — DONE

- **DONE** — Riverpod 3.
- **DONE** — Screen renders an immutable application state model.
- **DONE** — No `setState` for business state.
- **DONE** — No global mutable singletons.
- **DONE** — Dependencies are provided through Riverpod.

### T3 — Layers — DONE

- **DONE** — Data layer.
- **DONE** — Domain layer.
- **DONE** — Presentation layer.
- **DONE** — HTTP logic is separated from widgets.
- **DONE** — DTOs are separated from domain models.
- **DONE** — Widgets never parse JSON.
- **DONE** — API dependency is injected and replaceable with a fake during tests.

### T4 — Async — DONE

- **DONE** — Dio is used for HTTP requests.
- **DONE** — Request timeouts are configured.
- **DONE** — Typed application errors.
- **DONE** — Stale search requests are cancelled or ignored.
- **DONE** — Network operations are asynchronous and do not block the UI thread.

### T5 — Persistence — DONE

- **DONE** — `shared_preferences` is used for favorite persistence.
- **DONE** — Favorite is stored using the character URL.
- **DONE** — Stored favorite is restored before the character list is displayed.

### T6 — Tests — DONE

- **DONE** — Height parsing tests.
- **DONE** — Unknown/invalid height tests.
- **DONE** — Sorting tests including unknown heights.
- **DONE** — Pagination logic tests using a fake repository/API boundary.
- **DONE** — Duplicate concurrent page request protection is tested.
- **DONE** — All automated tests pass.

```text
flutter test
+11: All tests passed!
```

### T7 — Platform Targets — DONE

Android:

- **DONE** — compileSdk 37.
- **DONE** — targetSdk 37.
- **DONE** — minSdk 26.
- **DONE** — Android debug APK builds successfully.

iOS:

- **DONE** — Deployment target configured to iOS 26.0.
- The iOS build was not tested locally because development was performed on Windows without access to macOS/Xcode.

---

## Bonus Search Checklist — DONE

- **DONE** — Search field above the list.
- **DONE** — Server-side `?search=` filtering.
- **DONE** — Approximately 300 ms debounce.
- **DONE** — Stale request cancellation/ignoring.
- **DONE** — Paginated search.
- **DONE** — Infinite scrolling for search results.
- **DONE** — Search loading state.
- **DONE** — Search error state.
- **DONE** — Empty search state.
- **DONE** — Favorite behavior within search results.
- **DONE** — Sort after the final search page.
- **DONE** — Clearing search restores the cached main list without refetching loaded pages.

---

## Tests & Validation

The following validation was completed successfully before submission:

```text
flutter analyze
No issues found!

flutter test
+11: All tests passed!

flutter build apk --debug
Built build/app/outputs/flutter-apk/app-debug.apk
```

---

## Packages Used

- `flutter_riverpod` — state management and dependency injection.
- `dio` — HTTP communication, timeouts, and request cancellation.
- `shared_preferences` — local favorite persistence.
- `flutter_lints` — static analysis and lint rules.

---

## AI Tools

ChatGPT was used as an AI development assistant.

---

## Known Issues / Environment Notes

Development and testing were performed on **Windows**.

Android static analysis, automated tests, and the Android debug build were successfully verified.

The iOS deployment target is configured to **iOS 26.0**. The iOS build was not tested locally because macOS/Xcode was not available.

SWAPI may occasionally respond slowly or be temporarily unavailable. The application includes loading states, request timeouts, typed error handling, retry behavior, and the provided fallback API.