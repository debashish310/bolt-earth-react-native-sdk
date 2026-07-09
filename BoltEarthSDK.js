/**
 * BoltEarthSdk — JavaScript façade over native modules:
 * - iOS: `BoltEarthBridge` (`BoltEarthUiSdkCore`) — package id resolved inside native SDK from the host bundle + environment.
 * - Android: `BoltEarthUiSdk` (`BoltEarthUiSdkModule` — userId, sdkToken, sdkPackage, flows, …).
 *
 * Copy into your RN app (e.g. `src/native/BoltEarthSDK.js`) or publish from your SDK package.
 *
 * Prerequisites (iOS):
 * - BoltEarthUiSdkCore framework + BoltEarthUiSdkCoreResources.bundle in the host app.
 * - `BoltEarthBridge.swift` + `BoltEarthBridge.m` in the iOS target.
 * - Optional typography: ship .ttf in the app target, declare under `UIAppFonts`, and pass matching
 *   PostScript-style names (`sdkRegularFontName`, etc.).
 *
 * Prerequisites (Android):
 * - React Native library that registers native module `BoltEarthUiSdk` (see BoltEarthUiSdkModule).
 * - Host app Gradle / Hilt / Bolt UI SDK per integration docs.
 */

import { NativeModules, Platform } from 'react-native';

const BoltEarthBridge = NativeModules.BoltEarthBridge;
const BoltEarthUiSdk = NativeModules.BoltEarthUiSdk;

const iosReady = Platform.OS === 'ios' && BoltEarthBridge != null;
const androidReady = Platform.OS === 'android' && BoltEarthUiSdk != null;

const warnNativeUnavailable = async () => {
  if (__DEV__) {
    console.warn(
      '[BoltEarthSDK] Native BoltEarth module is not available on this platform or failed to link.',
    );
  }
};

/**
 * @typedef {object} BoltInitializeOptions
 * @property {string} clientID
 * @property {string} sdkToken
 * @property {'staging'|'production'} [environment='staging'] — **iOS only** (forwarded to native `BoltEarthSDK.Configuration`).
 * @property {string|null} [language] — ISO 639-1 alpha-2; omit or null for device default (`localeLanguageTag` on Android).
 * @property {string} [sdkRegularFontName] — **iOS only**
 * @property {string} [sdkBoldFontName] — **iOS only**
 * @property {string} [sdkSemiBoldFontName] — **iOS only**
 * @property {string} [sdkThemeColorHex] — theme accent (`primaryColor` on Android when set).
 * @property {boolean} [verboseLoggingEnabled] — **iOS only**
 * @property {string} [appPackageId] — **Android only**, required by `BoltEarthUiSdk.initialize` (application package name).
 * @property {{ light?: number, regular?: number, medium?: number, semiBold?: number, bold?: number }} [fontOverrides]
 *   **Android only** — forwarded to `BoltEarthUiSdk.initialize` when present.
 */

/**
 * @typedef {'TWO_WHEELER'|'THREE_WHEELER'|'FOUR_WHEELER'} BoltVehicleType
 * Vehicle type string passed to `presentChargerFlow`.
 * Must match one of the three recognised values exactly (case-insensitive on iOS native side).
 */

/**
 * @typedef {object} BoltPresentChargerOptions
 * @property {string} vehicleMapperKey — `externalKey` of the selected OEM vehicle (from `fetchOEMVehicles`).
 * @property {BoltVehicleType} vehicleType — vehicle category string.
 * @property {number} [initialSOCPercent=0] — current battery state-of-charge, 0–100.
 */

function initConfigFromBoltOptions(options) {
  const base = {
    userId: options.clientID,
    sdkToken: options.sdkToken,
    sdkPackage: options.appPackageId,
  };
  if (options.sdkThemeColorHex != null && options.sdkThemeColorHex !== '') {
    base.primaryColor = options.sdkThemeColorHex;
  }
  if (options.language != null && options.language !== '') {
    base.localeLanguageTag = options.language;
  }
  if (options.fontOverrides != null) {
    base.fontOverrides = options.fontOverrides;
  }
  return base;
}

/** Builds the ReadableMap keys expected by `BoltEarthUiSdkModule.initialize`. */
function toNativeInitMap(config) {
  const map = {
    userId: config.userId,
    sdkToken: config.sdkToken,
  };
  if (config.sdkPackage != null) {
    map.sdkPackage = config.sdkPackage;
  }
  if (config.primaryColor != null) {
    map.primaryColor = config.primaryColor;
  }
  if (config.localeLanguageTag != null) {
    map.localeLanguageTag = config.localeLanguageTag;
  }
  if (config.fontOverrides != null) {
    map.fontOverrides = config.fontOverrides;
  }
  return map;
}

/** @returns {Promise<void>} */
export async function initializeWithOptions(options) {
  const o = options ?? {};
  if (iosReady) {
    return BoltEarthBridge.initializeWithOptions(o);
  }
  if (androidReady) {
    if (!o.clientID || !o.sdkToken || !o.appPackageId) {
      throw new Error(
        '[BoltEarthSDK] initializeWithOptions on Android requires clientID, sdkToken, and appPackageId.',
      );
    }
    BoltEarthUiSdk.initialize(toNativeInitMap(initConfigFromBoltOptions(o)));
    return;
  }
  return warnNativeUnavailable();
}

/**
 * Legacy one-shot initializer (no Promise; on iOS failures only visible in Xcode console).
 *
 * **iOS:** `initializeLegacy(clientID, sdkToken, environment?, language?)`
 * — matches `BoltEarthBridge.initializeLegacy` (extra args after `language` are ignored).
 *
 * **Android:** `initializeLegacy(clientID, sdkToken, appPackageId, environment?, language?)`
 * — `environment` is accepted for API symmetry; forwarded keys depend on what
 * `BoltEarthUiSdk.initialize` supports (typically `userId`, `sdkToken`, `sdkPackage`, `localeLanguageTag`).
 *
 * @param {string} clientID
 * @param {string} sdkToken
 * @param {...*} rest — platform-specific trailing arguments (see above).
 */
export function initializeLegacy(clientID, sdkToken, ...rest) {
  if (iosReady) {
    const [environment = 'staging', language = null] = rest;
    BoltEarthBridge.initializeLegacy(clientID, sdkToken, environment, language);
    return;
  }
  if (androidReady) {
    const [appPackageId, /* environment */, language = null] = rest;
    if (!appPackageId) {
      if (__DEV__) {
        console.warn(
          '[BoltEarthSDK] Android initializeLegacy requires appPackageId as the third argument.',
        );
      }
      return;
    }
    const cfg = {
      userId: clientID,
      sdkToken,
      sdkPackage: appPackageId,
    };
    if (language != null && language !== '') {
      cfg.localeLanguageTag = language;
    }
    BoltEarthUiSdk.initialize(toNativeInitMap(cfg));
    return;
  }
}

/**
 * Opens the charger booking flow.
 *
 * **iOS** requires `options` with `vehicleMapperKey` and `vehicleType`.
 * Throws `BOLT_PRESENT_VALIDATION` if the mapper key is empty or SOC is out of range,
 * and `BOLT_INVALID_VEHICLE_TYPE` if `vehicleType` is not a recognised string.
 *
 * @param {BoltPresentChargerOptions} options
 * @returns {Promise<void>}
 */
export async function presentChargerFlow(options) {
  if (iosReady) {
    const o = options ?? {};
    return BoltEarthBridge.presentChargerFlow(o);
  }
  if (androidReady) {
    return BoltEarthUiSdk.openChargerBookingFlow();
  }
  return warnNativeUnavailable();
}

/**
 * @param {{ bookingId?: string | null }} [options] — forwarded on **iOS** only; unused on Android.
 * @returns {Promise<void>}
 */
export async function presentBookingHistoryFlow(options) {
  if (iosReady) {
    return BoltEarthBridge.presentBookingHistoryFlow(options ?? {});
  }
  if (androidReady) {
    if (__DEV__ && options?.bookingId) {
      console.warn(
        '[BoltEarthSDK] bookingId is not used by BoltEarthUiSdk.openUsersBookingsList.',
      );
    }
    return BoltEarthUiSdk.openUsersBookingsList();
  }
  return warnNativeUnavailable();
}

/**
 * Fetches the OEM vehicle list (iOS and Android).
 *
 * Each entry contains at least:
 *   `externalKey` (String), `model`, `company`, `companyModel`, `type`,
 *   `batteryCapacity`, `imageUrl` (String, optional).
 * iOS exposes charging rates as `obc`/`dc`; Android exposes them as `powerRating`/`dcCapacity`.
 *
 * Pass `externalKey` as `vehicleMapperKey` to `presentChargerFlow`.
 *
 * @returns {Promise<Array<Object>>}
 */
export async function fetchOEMVehicles() {
  if (iosReady) {
    return BoltEarthBridge.fetchOEMVehicles();
  }
  if (androidReady) {
    return BoltEarthUiSdk.fetchOEMVehicles();
  }
  return warnNativeUnavailable();
}

/**
 * Fetches charger details by Bolt charger ID (iOS and Android).
 *
 * Rejects with `BOLT_INVALID_CHARGER_ID` if the ID format is not recognised.
 * Network/server errors are resolved as the raw response object (check `status` and `message`).
 * On Android the SDK login gate runs internally before the network call.
 *
 * @param {string} chargerId — e.g. `"BE123456"` or `"BOLT_ABC123"`.
 * @returns {Promise<Object>} Full API response including `status`, `message`, and `data` on success.
 */
export async function fetchCharger(chargerId) {
  if (iosReady) {
    return BoltEarthBridge.fetchCharger(chargerId);
  }
  if (androidReady) {
    return BoltEarthUiSdk.fetchCharger(chargerId);
  }
  return warnNativeUnavailable();
}

/**
 * Opens the wallet flow (balance, transaction history, add money) — iOS and Android.
 *
 * **iOS:** rejects with `BOLT_WALLET` if the SDK raises an error during initialisation (e.g. missing
 * user data), or `BOLT_NO_VC` if no presenting view controller can be resolved.
 * **Android:** rejects with `E_PRESENT_WALLET` if the flow can't be launched.
 *
 * @returns {Promise<void>}
 */
export async function presentWalletFlow() {
  if (iosReady) {
    return BoltEarthBridge.presentWalletFlow();
  }
  if (androidReady) {
    return BoltEarthUiSdk.presentWalletFlow();
  }
  return warnNativeUnavailable();
}

/** @param {string | null | undefined} code */
export async function setLanguage(code) {
  if (iosReady) {
    return BoltEarthBridge.setLanguageCode(code ?? null);
  }
  if (androidReady) {
    return;
  }
  return warnNativeUnavailable();
}

/** @returns {Promise<string>} */
export async function getCurrentLanguageCode() {
  if (iosReady) {
    return BoltEarthBridge.currentLanguageCode();
  }
  if (androidReady) {
    return 'en';
  }
  await warnNativeUnavailable();
  return 'en';
}

/** @returns {Promise<string[]>} */
export async function getSupportedLanguageCodes() {
  if (iosReady) {
    return BoltEarthBridge.supportedLanguageCodes();
  }
  if (androidReady) {
    return [];
  }
  await warnNativeUnavailable();
  return [];
}

export function setVerboseLoggingEnabled(enabled) {
  if (iosReady) {
    BoltEarthBridge.setVerboseLoggingEnabled(!!enabled);
    return;
  }
  if (androidReady) {
    return;
  }
}

/** @returns {Promise<boolean>} */
export async function getVerboseLoggingEnabled() {
  if (iosReady) {
    return BoltEarthBridge.verboseLoggingEnabled();
  }
  if (androidReady) {
    return false;
  }
  await warnNativeUnavailable();
  return false;
}

/**
 * Ends server session (best-effort) and clears native credentials. Values from `initializeWithOptions`
 * remain for re-init / re-login where applicable.
 *
 * @returns {Promise<boolean>} `true` if the native logout HTTP response was treated as successful;
 *   `false` otherwise. Local session is cleared either way where implemented natively.
 */
export async function logout() {
  if (iosReady) {
    return BoltEarthBridge.logout();
  }
  if (androidReady) {
    const result = await BoltEarthUiSdk.logout();
    return result?.type === 'success';
  }
  await warnNativeUnavailable();
  return false;
}

const BoltEarthSDK = {
  initializeWithOptions,
  initialize: initializeLegacy,
  initializeLegacy,
  presentChargerFlow,
  presentBookingHistoryFlow,
  presentWalletFlow,
  fetchOEMVehicles,
  fetchCharger,
  logout,
  setLanguage,
  getCurrentLanguageCode,
  getSupportedLanguageCodes,
  setVerboseLoggingEnabled,
  getVerboseLoggingEnabled,
};

export default BoltEarthSDK;