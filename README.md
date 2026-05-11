# BoltEarth React Native SDK

## Installation

```bash
npm install @boltearth/react-native-sdk
```

## iOS

```bash
cd ios
pod install
```

## Usage

```javascript
import BoltEarthSDK from '@boltearth/react-native-sdk';

await BoltEarthSDK.initialize();
```
# ANDROID Bolt Earth React Native SDK — Short integration reference

## Gradle: what you must add

### 1. Hilt (required — Bolt UI activities are Hilt-based)

| Where | What |
|--------|------|
| **`android/settings.gradle`** | Inside `pluginManagement { plugins { … } }`: `id("com.google.dagger.hilt.android") version "2.54"` (+ keep RN `includeBuild` for the gradle plugin). |
| **`android/build.gradle`** `buildscript.dependencies` | `classpath("com.google.dagger:hilt-android-gradle-plugin:2.54")` and pin Kotlin: `classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")`. |
| **`android/app/build.gradle`** | Plugins: `com.google.dagger.hilt.android`, `org.jetbrains.kotlin.kapt`. |
| **`android/app/build.gradle`** `dependencies` | `implementation("com.google.dagger:hilt-android:2.54")`, `kapt("com.google.dagger:hilt-android-compiler:2.54")`. |
| **`MainApplication`** | `@HiltAndroidApp` on your `Application` class (manifest `android:name` must point to it). |

### 2. Host app module (`:app`)

- **`buildFeatures { dataBinding true }`**  
- **Java / Kotlin 17** (`compileOptions` + `kotlinOptions`)  
- **`kapt { correctErrorTypes true }`**

### 3. Maven repositories (`android/build.gradle`, `allprojects { repositories { … } }`)

Bolt’s UI SDK **must not** resolve via JitPack under `io.github.boltearth` (you can get **401** or wrong resolution). Add:

```gradle
google()
mavenCentral()

maven { url "https://adilkhanboltearth.github.io/boltearthuisdk/releases" }

maven { url "https://maven.juspay.in/jp-build-packages/hyper-sdk/" }

maven {
    url "https://www.jitpack.io"
    content { excludeGroup "io.github.boltearth" }
}
```

**Juspay** — Maven URL above; required for transitive deps of the Bolt UI stack.  
**Hilt** — see table in §1.

### 4. Bolt Earth UI SDK on `:app` (explicit, matches upstream example)

```gradle
implementation("io.github.boltearth:bolt-earth-ui-sdk:1.0.0") {
    exclude group: "com.github.theGlenn.flipper-android-no-op", module: "soloadernoop"
}
```

**Version** (`1.0.0` here) — confirm with Bolt Earth for production; bump when they release.

---

## npm / Node vs Gradle (when New Architecture codegen runs)

Gradle may run **`node`** for library codegen. If Android Studio builds fail with **“Cannot run program 'node'”**, set **one** of:

- `nodejs.executable=/absolute/path/to/node` in **`android/local.properties`**, or  
- **`NODE_BINARY`** env to that path, or  
- In **`android/app/build.gradle`** → `react { nodeExecutableAndArgs.set([absolutePathToNode]) }`

---

## JavaScript (minimal)

The JS bridge mirrors the native **`BoltEarthUiSdk`** surface: **`initialize`**, **`logout`**, **`openChargerBookingFlow`**, **`openUsersBookingsList`**, plus **`isBoltEarthUiSdkAvailable`**.

```ts
import {
  initialize,
  logout,
  openChargerBookingFlow,
  openUsersBookingsList,
  isBoltEarthUiSdkAvailable,
} from '@boltearth/react-native-sdk';

// Android only
initialize({ userId, sdkToken, sdkPackage, primaryColor, localeLanguageTag, fontOverrides });
await openChargerBookingFlow();
await openUsersBookingsList();
await logout();
```
