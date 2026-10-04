# Architectural & Design Decisions

This document explains the key engineering choices made while building this app, how we solved the core challenges, and what we would do differently in a large production app.

---

## 1. Why Clean Architecture and Bloc?

### Why Clean Architecture?
We organized the app into four clear layers:
- **Domain**: Pure Dart with zero Flutter or plugin dependencies. Holds the main data models (`NavigationRoute`, `UserLocation`), repository interfaces, and use cases.
- **Data**: Talks to the outside world—our OSRM client and native location calls.
- **Presentation**: UI widgets, screens, and BLoCs.
- **Core**: Shared utilities like math helpers, dependency injection (`GetIt`), network client (`Dio`), and app theme.

This separation means any part of the app can change without breaking the rest. For instance, swapping OSRM for another routing service only requires updating one file in the data layer.

### Why Bloc?
1. **Clear, predictable states**: Location, routing, and car animation have very specific stages (requesting permission $\to$ acquiring fix $\to$ ready; idle $\to$ loading $\to$ loaded; playing $\to$ paused $\to$ finished). With BLoC, every single state change happens through an explicit event.
2. **Preventing race conditions**: When a user picks a destination, an OSRM request starts. If they immediately pick another destination before the first one finishes, we use the `restartable()` transformer from `bloc_concurrency`. It cancels the older request right away so an old route never accidentally overwrites the new one.
3. **Throttling gestures**: To respect the public OSRM server's ~1 req/sec limit, we debounce destination selections by 600ms.
4. **Testable without the map UI**: Our car animation math runs inside `CarAnimationBloc`, completely independent of Flutter widgets. We can write fast unit tests for animation speed, distance updates, and heading angles without opening an emulator or creating a map.

---

## 2. Flutter ↔ Native Location Bridge

The brief strictly prohibited third-party location plugins (`geolocator`, `location`, `permission_handler`). Here is how we built the bridge from scratch in Kotlin:

### Platform Channels Used:
- **`MethodChannel` (`com.akt.navigation/location_method`)**: Used for one-time requests:
  - Checking if permissions are granted.
  - Asking the user for permission.
  - Checking if the device has GPS enabled.
  - Opening the phone's App Settings if permission was permanently denied.
  - Getting the user's current position once via `FusedLocationProviderClient`.
- **`EventChannel` (`com.akt.navigation/location_event`)**: Used for continuous live GPS streaming when navigating.

### Error Handling & Stream Safety:
- **No background battery drain**: In our native Kotlin code, the moment Flutter cancels the stream (or the user closes the screen), `onCancel()` immediately calls `fusedLocationClient.removeLocationUpdates(...)`. Location updates never run in the background unless explicitly needed.
- **Clean, typed errors**: Instead of throwing raw error strings to the UI, the native side returns specific error codes like `PERMISSION_DENIED`, `SERVICES_DISABLED`, and `LOCATION_TIMEOUT`. Our Dart `PlatformLocationService` catches these and converts them into strongly typed exceptions (`LocationPermissionDeniedException`, `LocationServicesDisabledException`, etc.).
- **What if location is turned off or denied?**: We don't crash or freeze the app. We show a clear explanation dialog. If the user chooses not to grant location or is running on an emulator without GPS, they can tap "Use Default" or pick points on the map manually to test the routing.

---

## 3. How the Car Movement & Rotation Math Works

Real routes from OSRM come with waypoints spaced unevenly—points might be 2 meters apart on a sharp corner, but 200 meters apart on a straight highway. If you simply animate point-to-point, the car jerks and speeds up/slows down erratically.

### Constant Speed Movement:
1. When a route is loaded, we measure the distance of every road segment using the **Haversine formula** and store the cumulative distance from the start.
2. We clean the data by filtering out duplicate points or points closer than 0.5 meters so they don't cause division-by-zero or `NaN` glitches.
3. Every 33ms (~30 frames per second), the car advances by:
   $$\text{Step Distance} = \text{Base Speed} \times \text{Speed Multiplier} \times \Delta t$$
4. We use binary search to quickly locate the active road segment for the car's current distance, and interpolate the exact `LatLng` coordinates smoothly along that segment.

### Shortest-Path Rotation:
When turning from $359^\circ$ to $1^\circ$, standard math would turn $358^\circ$ the wrong way around in a full circle. We calculate the shortest rotation using:
$$\Delta\theta = ((\theta_{\text{target}} - \theta_{\text{current}} + 540^\circ) \pmod{360^\circ}) - 180^\circ$$
This makes $359^\circ \to 1^\circ$ turn $+2^\circ$ smoothly in the natural direction.

---

## 4. How Build Flavors Are Set Up

We created two flavors on Android using Gradle `productFlavors`:
- **`dev` (Development)**:
  - App Name: `"NavTest Dev"`
  - Application ID: `com.akt.navigation.route_and_car_navigation.dev`
  - Has a visible red `"DEV"` watermark banner on the top-left of the screen.
  - Entry point: `lib/main_dev.dart`
- **`prod` (Production)**:
  - App Name: `"NavTest"`
  - Application ID: `com.akt.navigation.route_and_car_navigation`
  - Clean, unbadged production UI.
  - Entry point: `lib/main_prod.dart`

Because they have different application IDs, you can install both `dev` and `prod` on the exact same phone and compare them side by side.

The routing server URL comes directly from the `Environment` config class, so pointing to a different server requires changing one line of configuration rather than editing app code.

---

## 5. What We Would Change for a Real Production App

If we were launching this application to hundreds of thousands of daily users, we would add:
1. **Self-Hosted Routing Server**: The free public OSRM server is a shared demo with strict rate limits. For production, we would deploy our own dedicated OSRM or Valhalla cluster behind an autoscaling load balancer and cache common routes in Redis.
2. **Foreground Service with Persistent Notification**: Android aggressively kills apps running in the background. To keep navigation alive when the user locks their phone or switches apps, we would run a native Android Foreground Service with a persistent notification.
3. **Adaptive GPS Sampling**: Polling high-accuracy GPS every second drains battery quickly. In production, we would dynamically increase update intervals on straight highways and lower them near intersections, combining GPS with accelerometer and gyroscope sensors (dead reckoning).
4. **Offline Map Tile Caching**: Cache downloaded map tiles locally on disk using SQLite (`flutter_map_cache`) so the map works smoothly in tunnels or areas with poor cellular coverage.

---

## 6. What Was Left Out Due to Time

- **iOS Native Swift Code**: The assessment focused on Android as the required platform. We designed the Dart `LocationService` interface cleanly so that adding an iOS Swift implementation in the future won't require touching any Dart code.
- **Turn-by-Turn Voice Directions**: We focused our time on nail-down physics, constant-speed interpolation, and robust lifecycle handling rather than text-to-speech audio prompts.
