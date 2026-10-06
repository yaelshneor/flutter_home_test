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
- iOS was not built locally because development was performed on Windows without access to macOS/Xcode.
- The iOS project is included for evaluation and can be built on macOS.

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

You can verify that the emulator is available with:

```powershell
flutter devices
```

During local testing the emulator device ID was `emulator-5554`.

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

The project follows a layered architecture with separation between **Data, Domain, and Presentation** responsibilities.

```text
lib/
├── core/
│   └── errors/
│
├── data/
│   ├── datasources/
│   ├── dtos/
│   └── repositories/
│
├── domain/
│   ├── models/
│   ├── repositories/
│   └── services/
│
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

- Character model.
- Paginated character model.
- Character height parsing.
- Unknown/invalid height handling.
- Height-based sorting.
- Repository interfaces.

The domain layer determines how character heights are interpreted and how the final list is sorted.

### Presentation Layer

Contains:

- Riverpod providers.
- Application controller.
- Immutable UI state.
- Screens and reusable widgets.

Business state is managed outside the widgets.

Dart 3 sealed classes are used to represent application states and failures, and pattern matching is used when handling/rendering those states.

---

## State Management — Riverpod 3

**Riverpod 3** was chosen for state management and dependency injection.

It provides:

- Predictable state updates.
- Explicit dependency injection.
- Easy replacement of dependencies with fakes during tests.
- Separation between UI and business logic.
- No need for global mutable singletons.

The screen renders application state exposed by the controller.

`setState` is not used for business state. Widget-local objects such as `ScrollController` and `TextEditingController` remain presentation concerns.

---

## Pagination

The application loads the first SWAPI people page when it starts.

While the user scrolls toward the bottom, the application requests the next page and appends the new characters.

The application **always follows the exact `next` URL returned by SWAPI**.

Page URLs are never manually constructed.

Previously requested URLs are tracked to prevent the same page from being requested twice.

When:

```text
next == null
```

pagination stops and the complete list is sorted by height.

---

## Character Heights

SWAPI returns character height as a string.

Numeric heights are safely parsed and used both for display and for the logical height of the row.

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

---

## Sorting

Characters remain in the original server order while additional pages are available.

The application does **not** continuously sort partially loaded data.

Only after the final page has been loaded is the entire collection sorted:

1. Numeric heights from shortest to tallest.
2. Unknown heights last.

---

## Favorite

The application supports exactly **one favorite character or no favorite**.

Behavior:

- Tap a character -> it becomes the favorite.
- Tap another character -> it replaces the previous favorite.
- Tap the current favorite again -> the favorite is cleared.

The favorite is identified using the character's SWAPI `url` rather than its current list index.

This allows the favorite to remain associated with the correct character after:

- Pagination.
- Sorting.
- Searching.
- Application restart.

The favorite URL is persisted locally using `shared_preferences` and restored when the application is started again.

If no favorite has previously been saved, the application starts with no selected favorite.

---

## Loading & Error Handling

The application represents loading and failure conditions explicitly.

Supported states include:

- Initial loading.
- Initial loading failure.
- Loaded content.
- Pagination loading.
- Pagination failure.
- Search loading.
- Search failure.

When loading another page, the already-loaded list remains available and scrollable.

If loading a subsequent page fails, existing characters are preserved and the failed request can be retried.

The application uses typed failures for:

- Network errors.
- Timeouts.
- Server errors.
- Invalid data.
- Cancelled requests.
- Persistence failures.

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

Search uses SWAPI's server-side search endpoint rather than filtering the already-loaded characters locally.

Example:

```text
GET /api/people/?search=Luke
```

Implemented search behavior:

- Server-side search.
- Approximately 300 ms debounce.
- Protection against stale search responses.
- Cancellation/ignoring of superseded requests.
- Paginated search results.
- Infinite scrolling within search results.
- Loading states.
- Error handling.
- Empty-result state.
- Favorite selection in search results.
- Sorting after the final search page.
- Clearing the search restores the already-loaded main list without refetching it.

---

## Adaptive UI

The application uses Material 3 components and is designed for:

- Android.
- iOS.
- Phones.
- Tablets.
- Portrait orientation.
- Landscape orientation.

Application state is managed outside the screen widget, so rebuilding the interface after an orientation change does not discard the loaded character data, favorite, or search term.

The scroll controller remains associated with the screen state during orientation changes to preserve the scrolling context.

---

# Requirements Checklist

## Functional Requirements

### F1 — List & Infinite Scroll — DONE

- **DONE** — Page 1 loads on launch.
- **DONE** — Server order is preserved while pagination is active.
- **DONE** — The next page loads near the bottom of the list.
- **DONE** — New characters are appended to existing characters.
- **DONE** — The exact server-provided `next` URL is followed.
- **DONE** — Duplicate page requests are prevented.
- **DONE** — Pagination stops when `next` is null.

### F2 — Character Row — DONE

- **DONE** — Character name is displayed.
- **DONE** — Character height is displayed.
- **DONE** — Row logical height corresponds to numeric character height.
- **DONE** — Unknown/invalid heights display `unknown`.
- **DONE** — Unknown heights use an 80 px row.
- **DONE** — Invalid height values do not crash or remove the character.

### F3 — Loading & Errors — DONE

- **DONE** — Initial loading state.
- **DONE** — Pagination loading state.
- **DONE** — Existing content remains available during pagination.
- **DONE** — Typed error states.
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
- **DONE** — Loaded application state is retained during orientation changes.
- **DONE** — Favorite and search state are retained during orientation changes.

---

## Technical Requirements

### T1 — Current Flutter — DONE

- **DONE** — Flutter 3.47.6.
- **DONE** — Dart 3.13.5.
- **DONE** — Sound null safety.
- **DONE** — `flutter_lints`.
- **DONE** — Dart 3 sealed classes.
- **DONE** — Pattern matching for application state/errors.
- **DONE** — `flutter analyze` passes with no issues.

### T2 — State Management — DONE

- **DONE** — Riverpod 3.
- **DONE** — Application state represented by an immutable state model.
- **DONE** — No `setState` for business state.
- **DONE** — No global mutable singletons.
- **DONE** — Dependencies provided through Riverpod.

### T3 — Layers — DONE

- **DONE** — Data layer.
- **DONE** — Domain layer.
- **DONE** — Presentation layer.
- **DONE** — HTTP logic separated from widgets.
- **DONE** — DTOs separated from domain models.
- **DONE** — Widgets never parse JSON.
- **DONE** — API dependency is injected and replaceable with a fake during tests.

### T4 — Async — DONE

- **DONE** — Dio used for HTTP requests.
- **DONE** — Request timeouts.
- **DONE** — Typed application errors.
- **DONE** — Stale search requests are cancelled or ignored.
- **DONE** — Network work is asynchronous and does not perform blocking work on the UI thread.

### T5 — Persistence — DONE

- **DONE** — `shared_preferences` used for favorite persistence.
- **DONE** — Favorite stored using character URL.
- **DONE** — Stored favorite restored on application startup.

### T6 — Tests — DONE

- **DONE** — Height parsing tests.
- **DONE** — Unknown/invalid height tests.
- **DONE** — Sorting tests.
- **DONE** — Unknown-height sorting tests.
- **DONE** — Pagination tests using a fake repository/API boundary.
- **DONE** — Duplicate concurrent page request protection tested.
- **DONE** — All automated tests pass.

Submission validation:

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
- iOS build was not locally verified because development was performed on Windows without macOS/Xcode.

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

Before submission, the following commands were run successfully:

```powershell
flutter analyze
```

Result:

```text
No issues found!
```

Tests:

```powershell
flutter test
```

Result:

```text
+11: All tests passed!
```

Android build:

```powershell
flutter build apk --debug
```

Result:

```text
Built build/app/outputs/flutter-apk/app-debug.apk
```

---

## Packages Used

### flutter_riverpod

Used for application state management and dependency injection.

### dio

Used for HTTP communication, request timeouts, and request cancellation.

### shared_preferences

Used to persist the selected favorite character URL locally.

### flutter_lints

Used for Flutter/Dart static analysis and lint rules.

---

## AI Tools

**ChatGPT** was used during development for assistance with:

- Implementation planning.
- Architecture review.
- Debugging.
- Code review.
- Test planning.

The submitted project was validated using Flutter static analysis, automated tests, and an Android debug build.

---

## Known Issues / Environment Notes

Development and local testing were performed on **Windows**.

Android static analysis, automated tests, and the Android debug APK build were successfully verified before submission.

The iOS deployment target is configured to **iOS 26.0**, but the iOS application was not built locally because macOS/Xcode was not available. The iOS project is included so it can be built and evaluated on macOS.

The public SWAPI service may occasionally respond slowly or be temporarily unavailable. The application therefore includes loading states, request timeouts, typed error handling, retry behavior, and the provided fallback API.