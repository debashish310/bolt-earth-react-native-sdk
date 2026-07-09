//
// BoltEarthBridge.swift
//
// React Native → BoltEarthUiSdkCore bridge (iOS).
// Add this file to your React Native app's iOS target. Link BoltEarthUiSdkCore and React-Core (Pods).
//

import Foundation
import UIKit
import React
import BoltEarthUiSdkCore

/// Keys for dictionary passed from JS (`BoltEarthSDK.initialize(options)`).
private enum BoltBridgeConfigKey {
    static let clientID = "clientID"
    static let sdkToken = "sdkToken"
    static let environment = "environment"
    static let language = "language"
    static let sdkRegularFontName = "sdkRegularFontName"
    static let sdkBoldFontName = "sdkBoldFontName"
    static let sdkSemiBoldFontName = "sdkSemiBoldFontName"
    static let sdkThemeColorHex = "sdkThemeColorHex"
    static let verboseLoggingEnabled = "verboseLoggingEnabled"
}

/// Keys for dictionary passed from JS (`BoltEarthSDK.presentChargerFlow(options)`).
private enum BoltBridgeFlowKey {
    static let vehicleMapperKey = "vehicleMapperKey"
    static let vehicleType = "vehicleType"
    static let initialSOCPercent = "initialSOCPercent"
}

private func boltBridgeBool(forKey key: String, in dict: NSDictionary) -> Bool? {
    let raw = dict[key]
    guard raw != nil, !(raw is NSNull) else { return nil }
    if let b = raw as? Bool { return b }
    if let n = raw as? NSNumber { return n.boolValue }
    return nil
}

private func boltBridgeString(forKey key: String, in dict: NSDictionary) -> String? {
    let raw = dict[key]
    guard raw != nil, !(raw is NSNull) else { return nil }
    let text: String? = {
        if let s = raw as? String { return s }
        if let ns = raw as? NSString { return ns as String }
        return nil
    }()
    guard let t = text?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
    return t
}

private func boltBridgeFloat(forKey key: String, in dict: NSDictionary) -> Float? {
    let raw = dict[key]
    guard raw != nil, !(raw is NSNull) else { return nil }
    if let n = raw as? NSNumber { return n.floatValue }
    return nil
}

/// Maps JS vehicle type string to `SDKVehicleType`.
/// Valid values: `"TWO_WHEELER"`, `"THREE_WHEELER"`, `"FOUR_WHEELER"`.
private func boltBridgeVehicleType(_ raw: String?) -> BoltEarthSDK.SDKVehicleType? {
    switch raw?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
    case "TWO_WHEELER":   return .twoWheeler
    case "THREE_WHEELER": return .threeWheeler
    case "FOUR_WHEELER":  return .fourWheeler
    default:              return nil
    }
}

@objc(BoltEarthBridge)
final class BoltEarthBridge: NSObject {

    // MARK: Initialize (recommended)

    /// Use this from JS — avoid Obj-C selector name `initialize` (conflicts with `NSObject.initialize`).
    @objc(
        initializeWithOptions:resolve:reject:
    )
    func initializeWithOptions(
        _ options: NSDictionary,
        resolve resolve: @escaping RCTPromiseResolveBlock,
        reject reject: @escaping RCTPromiseRejectBlock
    ) {
        DispatchQueue.main.async {
            guard let clientID = boltBridgeString(forKey: BoltBridgeConfigKey.clientID, in: options),
                  let sdkToken = boltBridgeString(forKey: BoltBridgeConfigKey.sdkToken, in: options) else {
                reject(
                    "BOLT_MISSING_FIELDS",
                    "`clientID` and `sdkToken` are required in the options object.",
                    nil
                )
                return
            }

            let envRaw = boltBridgeString(forKey: BoltBridgeConfigKey.environment, in: options) ?? "staging"
            let env: BoltEarthSDK.Configuration.Environment = envRaw.lowercased() == "production"
                ? .production
                : .staging

            let language = boltBridgeString(forKey: BoltBridgeConfigKey.language, in: options)
            let reg = boltBridgeString(forKey: BoltBridgeConfigKey.sdkRegularFontName, in: options)
            let bold = boltBridgeString(forKey: BoltBridgeConfigKey.sdkBoldFontName, in: options)
            let semi = boltBridgeString(forKey: BoltBridgeConfigKey.sdkSemiBoldFontName, in: options)
            let hex = boltBridgeString(forKey: BoltBridgeConfigKey.sdkThemeColorHex, in: options)
            let verboseLogging = boltBridgeBool(forKey: BoltBridgeConfigKey.verboseLoggingEnabled, in: options) ?? false

            let config = BoltEarthSDK.Configuration(
                clientID: clientID,
                sdkToken: sdkToken,
                environment: env,
                language: language,
                sdkRegularFontName: reg,
                sdkBoldFontName: bold,
                sdkSemiBoldFontName: semi,
                sdkThemeColorHex: hex,
                verboseLoggingEnabled: verboseLogging
            )

            do {
                try BoltEarthSDK.initialize(config: config)
                resolve(NSNull())
            } catch let e as BoltEarthSDK.InitializationError {
                reject("BOLT_INIT_VALIDATION", e.localizedDescription, nil)
            } catch {
                reject("BOLT_INIT", error.localizedDescription, nil)
            }
        }
    }

    // MARK: Initialize (positional, legacy)

    @objc(
        initializeLegacy:sdkToken:environment:language:
    )
    func initializeLegacyBridge(
        _ clientID: String,
        sdkToken: String,
        environment: String,
        language: String?
    ) {
        DispatchQueue.main.async {
            let envLower = environment.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let env: BoltEarthSDK.Configuration.Environment =
                envLower == "production" ? .production : .staging

            let lang = language.flatMap { raw -> String? in
                let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                return t.isEmpty ? nil : t
            }

            do {
                try BoltEarthSDK.initialize(
                    config: .init(
                        clientID: clientID,
                        sdkToken: sdkToken,
                        environment: env,
                        language: lang
                    )
                )
            } catch {
                NSLog("[BoltEarthBridge] initializeLegacy failed: \(error.localizedDescription)")
            }
        }
    }

    @objc(setLanguageCode:resolve:reject:)
    func setLanguageBridge(
        _ code: NSString?,
        resolve resolve: @escaping RCTPromiseResolveBlock,
        reject reject: @escaping RCTPromiseRejectBlock
    ) {
        DispatchQueue.main.async {
            if let code {
                let s = code as String
                let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
                BoltEarthSDK.setLanguage(trimmed.isEmpty ? nil : trimmed)
            } else {
                BoltEarthSDK.setLanguage(nil)
            }
            resolve(NSNull())
        }
    }

    @objc(currentLanguageCode:reject:)
    func currentLanguageBridge(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            resolve(BoltEarthSDK.currentLanguageCode)
        }
    }

    @objc(supportedLanguageCodes:reject:)
    func supportedLanguagesBridge(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            resolve(BoltEarthSDK.supportedLanguageCodes)
        }
    }

    // MARK: Verbose logs

    @objc(setVerboseLoggingEnabled:)
    func setVerboseLoggingBridge(_ enabled: Bool) {
        BoltEarthSDK.verboseLoggingEnabled = enabled
    }

    @objc(verboseLoggingEnabled:reject:)
    func readVerboseLoggingBridge(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            resolve(BoltEarthSDK.verboseLoggingEnabled)
        }
    }

    // MARK: Flows

    /// Options keys:
    ///   - `vehicleMapperKey` (String, required) — `externalKey` of the selected OEM vehicle.
    ///   - `vehicleType` (String, required) — `"TWO_WHEELER"`, `"THREE_WHEELER"`, or `"FOUR_WHEELER"`.
    ///   - `initialSOCPercent` (Number, optional, default 0) — current battery SOC, 0–100.
    @objc(presentChargerFlow:resolve:reject:)
    func presentChargerFlowBridge(
        _ options: NSDictionary,
        resolve resolve: @escaping RCTPromiseResolveBlock,
        reject reject: @escaping RCTPromiseRejectBlock
    ) {
        DispatchQueue.main.async {
            guard let mapperKey = boltBridgeString(forKey: BoltBridgeFlowKey.vehicleMapperKey, in: options) else {
                reject("BOLT_MISSING_FIELDS", "`vehicleMapperKey` is required in the options object.", nil)
                return
            }

            let vehicleTypeRaw = boltBridgeString(forKey: BoltBridgeFlowKey.vehicleType, in: options)
            guard let vehicleType = boltBridgeVehicleType(vehicleTypeRaw) else {
                reject(
                    "BOLT_INVALID_VEHICLE_TYPE",
                    "`vehicleType` must be one of \"TWO_WHEELER\", \"THREE_WHEELER\", or \"FOUR_WHEELER\". Got: \(vehicleTypeRaw ?? "nil").",
                    nil
                )
                return
            }

            let soc = boltBridgeFloat(forKey: BoltBridgeFlowKey.initialSOCPercent, in: options) ?? 0

            guard let top = Self.resolveTopMostViewController() else {
                reject("BOLT_NO_VC", "Could not resolve a presenting view controller.", nil)
                return
            }

            do {
                try BoltEarthSDK.presentChargerFlow(
                    from: top,
                    vehicleMapperKey: mapperKey,
                    vehicleType: vehicleType,
                    initialSOCPercent: soc
                )
                resolve(NSNull())
            } catch let e as BoltEarthSDK.PresentFlowError {
                reject("BOLT_PRESENT_VALIDATION", e.localizedDescription, nil)
            } catch {
                reject("BOLT_PRESENT", error.localizedDescription, nil)
            }
        }
    }

    @objc(
        presentBookingHistoryFlow:resolve:reject:
    )
    func presentBookingHistoryBridge(
        _ options: NSDictionary?,
        resolve resolve: @escaping RCTPromiseResolveBlock,
        reject reject: @escaping RCTPromiseRejectBlock
    ) {
        DispatchQueue.main.async {
            guard let top = Self.resolveTopMostViewController() else {
                reject("BOLT_NO_VC", "Could not resolve a presenting view controller.", nil)
                return
            }

            let _ = options // NSDictionary retained for RN API compatibility (booking deep-link removed)

            BoltEarthSDK.presentBookingHistoryFlow(from: top, animated: true)
            resolve(NSNull())
        }
    }

    // MARK: OEM Vehicles

    /// Fetches the OEM vehicle list. Returns an array of vehicle dictionaries.
    /// Each entry contains: `externalKey`, `model`, `company`, `companyModel`, `type`,
    /// `batteryCapacity`, `obc`, `dc`, and optionally `imageUrl`.
    @objc(fetchOEMVehicles:reject:)
    func fetchOEMVehiclesBridge(
        _ resolve: @escaping RCTPromiseResolveBlock,
        reject reject: @escaping RCTPromiseRejectBlock
    ) {
        BoltEarthSDK.fetchOEMVehicles { vehicles in
            resolve(vehicles)
        }
    }

    // MARK: Charger

    /// Fetches charger details by Bolt charger ID.
    /// Rejects with `BOLT_INVALID_CHARGER_ID` synchronously if the ID format is unrecognised.
    /// Network/server errors are resolved as the raw response dict (check `status` and `message`).
    @objc(fetchCharger:resolve:reject:)
    func fetchChargerBridge(
        _ chargerId: NSString,
        resolve resolve: @escaping RCTPromiseResolveBlock,
        reject reject: @escaping RCTPromiseRejectBlock
    ) {
        do {
            try BoltEarthSDK.fetchCharger(byId: chargerId as String) { result in
                resolve(result)
            }
        } catch let e as BoltEarthSDK.ChargerFetchError {
            reject("BOLT_INVALID_CHARGER_ID", e.localizedDescription, nil)
        } catch {
            reject("BOLT_CHARGER_FETCH", error.localizedDescription, nil)
        }
    }

    // MARK: Wallet

    @objc(presentWalletFlow:reject:)
    func presentWalletFlowBridge(
        _ resolve: @escaping RCTPromiseResolveBlock,
        reject reject: @escaping RCTPromiseRejectBlock
    ) {
        DispatchQueue.main.async {
            guard let top = Self.resolveTopMostViewController() else {
                reject("BOLT_NO_VC", "Could not resolve a presenting view controller.", nil)
                return
            }
            do {
                try BoltEarthSDK.presentWalletFlow(from: top)
                resolve(NSNull())
            } catch {
                reject("BOLT_WALLET", error.localizedDescription, nil)
            }
        }
    }

    // MARK: Session

    /// Resolves with `true` when the native logout HTTP call succeeds (see `BoltEarthSDK.logout`). Local credentials are always cleared on the native side.
    @objc(logout:reject:)
    func logoutBridge(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        BoltEarthSDK.logout { success in
            resolve(success)
        }
    }

    // MARK: - Top VC

    private static func resolveTopMostViewController() -> UIViewController? {
        guard let scenes = UIApplication.shared.connectedScenes as? Set<UIWindowScene> else {
            return fallbackRoot().map { walkLeafPresented(from: $0) }
        }

        let windows = scenes.flatMap { $0.windows }
        guard let root = windows.first(where: { $0.isKeyWindow })?.rootViewController
                ?? windows.first?.rootViewController
                ?? fallbackRoot() else {
            return nil
        }
        return walkLeafPresented(from: root)
    }

    private static func fallbackRoot() -> UIViewController? {
        UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? UIApplication.shared.windows.first?.rootViewController
    }

    private static func walkLeafPresented(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return walkLeafPresented(from: presented)
        }
        if let nav = vc as? UINavigationController, let visible = nav.visibleViewController {
            return walkLeafPresented(from: visible)
        }
        if let tab = vc as? UITabBarController, let sel = tab.selectedViewController {
            return walkLeafPresented(from: sel)
        }
        return vc
    }

    @objc static func requiresMainQueueSetup() -> Bool {
        false
    }
}
