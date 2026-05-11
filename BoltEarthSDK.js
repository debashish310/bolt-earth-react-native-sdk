/**
 * BoltEarthSdk — JavaScript façade over native modules:
 * - iOS: `BoltEarthBridge` (same JS behavior as the original sample below).
 * - Android: `BoltEarthUiSdk` (`BoltEarthUiSdkModule` — userId, sdkToken, openChargerBookingFlow, …).
 *
 * Copy into your RN app (e.g. `src/native/BoltEarthSDK.js`) or publish from your SDK package.
 *
 * Prerequisites (iOS):
 * - BoltEarthUiSdkCore framework + BoltEarthUiSdkCoreResources.bundle in the host app.
 * - `BoltEarthBridge.swift` + `BoltEarthBridge.m` in the iOS target.
 * - Optional typography: ship .ttf in the app target, declare under `UIAppFonts` relative to the
 *   bundle (this app bundles `Roboto-{Regular,Bold,SemiBold}.ttf`), and pass matching
 *   PostScript-style names (`sdkRegularFontName`, etc.).
 *
 * Prerequisites (Android):
 * - React Native library that registers native module `BoltEarthUiSdk` (see BoltEarthUiSdkModule).
 * - Host app Gradle / Hilt / Bolt UI SDK per integration docs.
 */

import { NativeModules, Platform } from 'react-native';

const { BoltEarthBridge } = NativeModules;
const BoltEarthUiSdk = NativeModules.BoltEarthUiSdk;

const androidReady = Platform.OS === 'android' && BoltEarthUiSdk != null;

const notIOS = async () => {
  if (__DEV__) {
    console.warn('[BoltEarthSDK] Native bridge is available on iOS only.');
  }
};

/**
 * @typedef {object} BoltInitializeOptions
 * @property {string} clientID
 * @property {string} sdkToken
 * @property {string} appPackageId
 * @property {'staging'|'production'} [environment='staging']
 * @property {string|null} [language] — ISO 639-1 alpha-2; omit or null for device default
 * @property {string} [sdkRegularFontName]
 * @property {string} [sdkBoldFontName]
 * @property {string} [sdkSemiBoldFontName]
 * @property {string} [sdkThemeColorHex]
 * @property {{ light?: number, regular?: number, medium?: number, semiBold?: number, bold?: number }} [fontOverrides]
 *   Android only — forwarded to `BoltEarthUiSdk.initialize` when present.
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
  if (Platform.OS === 'ios') {
    return BoltEarthBridge.initializeWithOptions(options ?? {});
  }
  if (androidReady) {
    const o = options;
    if (o == null || !o.clientID || !o.sdkToken || !o.appPackageId) {
      throw new Error(
        '[BoltEarthSDK] initializeWithOptions requires clientID, sdkToken, and appPackageId.',
      );
    }
    BoltEarthUiSdk.initialize(toNativeInitMap(initConfigFromBoltOptions(o)));
    return;
  }
  return notIOS();
}

/**
 * Legacy one-shot initializer (no Promise; failures only visible in Xcode console on iOS).
 */
export function initializeLegacy(
  clientID,
  sdkToken,
  appPackageId,
  environment = 'staging',
  language = null,
) {
  if (Platform.OS === 'ios') {
    BoltEarthBridge.initializeLegacy(
      clientID,
      sdkToken,
      appPackageId,
      environment,
      language,
    );
    return;
  }
  if (androidReady) {
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

/** @returns {Promise<void>} */
export async function presentChargerFlow() {
  if (Platform.OS === 'ios') {
    return BoltEarthBridge.presentChargerFlow();
  }
  if (androidReady) {
    return BoltEarthUiSdk.openChargerBookingFlow();
  }
  return notIOS();
}

/**
 * @param {{ bookingId?: string | null }} [options]
 * @returns {Promise<void>}
 */
export async function presentBookingHistoryFlow(options) {
  if (Platform.OS === 'ios') {
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
  return notIOS();
}

/** @param {string | null | undefined} code */
export async function setLanguage(code) {
  if (Platform.OS === 'ios') {
    return BoltEarthBridge.setLanguageCode(code ?? null);
  }
  if (androidReady) {
    return;
  }
  return notIOS();
}

/** @returns {Promise<string>} */
export async function getCurrentLanguageCode() {
  if (Platform.OS === 'ios') {
    return BoltEarthBridge.currentLanguageCode();
  }
  if (androidReady) {
    return 'en';
  }
  await notIOS();
  return 'en';
}

/** @returns {Promise<string[]>} */
export async function getSupportedLanguageCodes() {
  if (Platform.OS === 'ios') {
    return BoltEarthBridge.supportedLanguageCodes();
  }
  if (androidReady) {
    return [];
  }
  await notIOS();
  return [];
}

export function setVerboseLoggingEnabled(enabled) {
  if (Platform.OS === 'ios') {
    BoltEarthBridge.setVerboseLoggingEnabled(!!enabled);
    return;
  }
  if (androidReady) {
    return;
  }
}

/** @returns {Promise<boolean>} */
export async function getVerboseLoggingEnabled() {
  if (Platform.OS === 'ios') {
    return BoltEarthBridge.verboseLoggingEnabled();
  }
  if (androidReady) {
    return false;
  }
  await notIOS();
  return false;
}

/**
 * Ends server session (best-effort) and clears native credentials. Values from `initializeWithOptions` remain for re-login.
 *
 * @returns {Promise<boolean>} `true` if the native logout HTTP response was treated as successful; `false` otherwise. Local session is cleared either way.
 */
export async function logout() {
  if (Platform.OS === 'ios') {
    return BoltEarthBridge.logout();
  }
  if (androidReady) {
    const result = await BoltEarthUiSdk.logout();
    return result?.type === 'success';
  }
  await notIOS();
  return false;
}

const BoltEarthSDK = {
  initializeWithOptions,
  initialize: initializeLegacy,
  initializeLegacy,
  presentChargerFlow,
  presentBookingHistoryFlow,
  logout,
  setLanguage,
  getCurrentLanguageCode,
  getSupportedLanguageCodes,
  setVerboseLoggingEnabled,
  getVerboseLoggingEnabled,
};

export default BoltEarthSDK;
