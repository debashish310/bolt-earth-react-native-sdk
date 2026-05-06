/**
 * BoltEarthSdk — JavaScript façade over `BoltEarthBridge` native module (iOS).
 *
 * Copy this file into your RN app (e.g. `src/native/BoltEarthSDK.js`).
 *
 * Prerequisites (iOS):
 * - BoltEarthUiSdkCore framework + BoltEarthUiSdkCoreResources.bundle in the host app.
 * - `BoltEarthBridge.swift` + `BoltEarthBridge.m` in the iOS target.
 * - Optional typography: ship .ttf in the app target, declare under `UIAppFonts` relative to the
 *   bundle (this app bundles `Roboto-{Regular,Bold,SemiBold}.ttf`), and pass matching
 *   PostScript-style names (`sdkRegularFontName`, etc.).
 */

import { NativeModules, Platform } from 'react-native';

const { BoltEarthBridge } = NativeModules;

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
 */

/** @returns {Promise<void>} */
export async function initializeWithOptions(options) {
  if (Platform.OS !== 'ios') return notIOS();
  return BoltEarthBridge.initializeWithOptions(options ?? {});
}

/**
 * Legacy one-shot initializer (no Promise; failures only visible in Xcode console).
 */
export function initializeLegacy(
  clientID,
  sdkToken,
  appPackageId,
  environment = 'staging',
  language = null,
) {
  if (Platform.OS !== 'ios') return;
  BoltEarthBridge.initializeLegacy(
    clientID,
    sdkToken,
    appPackageId,
    environment,
    language,
  );
}

/** @returns {Promise<void>} */
export async function presentChargerFlow() {
  if (Platform.OS !== 'ios') return notIOS();
  return BoltEarthBridge.presentChargerFlow();
}

/**
 * @param {{ bookingId?: string | null }} [options]
 * @returns {Promise<void>}
 */
export async function presentBookingHistoryFlow(options) {
  if (Platform.OS !== 'ios') return notIOS();
  return BoltEarthBridge.presentBookingHistoryFlow(options ?? {});
}

/** @param {string | null | undefined} code */
export async function setLanguage(code) {
  if (Platform.OS !== 'ios') return notIOS();
  return BoltEarthBridge.setLanguageCode(code ?? null);
}

/** @returns {Promise<string>} */
export async function getCurrentLanguageCode() {
  if (Platform.OS !== 'ios') {
    await notIOS();
    return 'en';
  }
  return BoltEarthBridge.currentLanguageCode();
}

/** @returns {Promise<string[]>} */
export async function getSupportedLanguageCodes() {
  if (Platform.OS !== 'ios') {
    await notIOS();
    return [];
  }
  return BoltEarthBridge.supportedLanguageCodes();
}

export function setVerboseLoggingEnabled(enabled) {
  if (Platform.OS !== 'ios') return;
  BoltEarthBridge.setVerboseLoggingEnabled(!!enabled);
}

/** @returns {Promise<boolean>} */
export async function getVerboseLoggingEnabled() {
  if (Platform.OS !== 'ios') {
    await notIOS();
    return false;
  }
  return BoltEarthBridge.verboseLoggingEnabled();
}

const BoltEarthSDK = {
  initializeWithOptions,
  initialize: initializeLegacy,
  initializeLegacy,
  presentChargerFlow,
  presentBookingHistoryFlow,
  setLanguage,
  getCurrentLanguageCode,
  getSupportedLanguageCodes,
  setVerboseLoggingEnabled,
  getVerboseLoggingEnabled,
};

export default BoltEarthSDK;
