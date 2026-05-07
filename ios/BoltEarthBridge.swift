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
    static let appPackageId = "appPackageId"
    static let environment = "environment"
    static let language = "language"
    static let sdkRegularFontName = "sdkRegularFontName"
    static let sdkBoldFontName = "sdkBoldFontName"
    static let sdkSemiBoldFontName = "sdkSemiBoldFontName"
    static let sdkThemeColorHex = "sdkThemeColorHex"
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

@objc(BoltEarthBridge)
final class BoltEarthBridge: NSObject {

    // MARK: Initialize (recommended)

    /// Use this from JS — avoid Obj-C selector name `initialize` (conflicts with `NSObject.initialize`).
    @objc(
        initializeWithOptions:resolve:reject:
    )
    func initializeWithOptions(
        _ options: NSDictionary,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        DispatchQueue.main.async {
            guard let clientID = boltBridgeString(forKey: BoltBridgeConfigKey.clientID, in: options),
                  let sdkToken = boltBridgeString(forKey: BoltBridgeConfigKey.sdkToken, in: options),
                  let appPackageId = boltBridgeString(forKey: BoltBridgeConfigKey.appPackageId, in: options) else {
                reject(
                    "BOLT_MISSING_FIELDS",
                    "`clientID`, `sdkToken`, and `appPackageId` are required in the options object.",
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

            let config = BoltEarthSDK.Configuration(
                clientID: clientID,
                sdkToken: sdkToken,
                appPackageId: appPackageId,
                environment: env,
                language: language,
                sdkRegularFontName: reg,
                sdkBoldFontName: bold,
                sdkSemiBoldFontName: semi,
                sdkThemeColorHex: hex
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
        initializeLegacy:sdkToken:appPackageId:environment:language:
    )
    func initializeLegacyBridge(
        _ clientID: String,
        sdkToken: String,
        appPackageId: String,
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
                        appPackageId: appPackageId,
                        environment: env,
                        language: lang
                    )
                )
            } catch {
                NSLog("[BoltEarthBridge] initializeLegacy failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: Language

    @objc(setLanguageCode:resolve:reject:)
    func setLanguageBridge(
        _ code: NSString?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
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

    @objc(presentChargerFlow:reject:)
    func presentChargerFlowBridge(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            guard let top = Self.resolveTopMostViewController() else {
                reject("BOLT_NO_VC", "Could not resolve a presenting view controller.", nil)
                return
            }
            BoltEarthSDK.presentChargerFlow(from: top)
            resolve(NSNull())
        }
    }

    @objc(
        presentBookingHistoryFlow:resolve:reject:
    )
    func presentBookingHistoryBridge(
        _ options: NSDictionary?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        DispatchQueue.main.async {
            guard let top = Self.resolveTopMostViewController() else {
                reject("BOLT_NO_VC", "Could not resolve a presenting view controller.", nil)
                return
            }

            let bid: String? = {
                guard let opts = options else { return nil }
                return boltBridgeString(forKey: "bookingId", in: opts)
            }()

            BoltEarthSDK.presentBookingHistoryFlow(from: top, animated: true)
            resolve(NSNull())
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

    private static func windowsFromConnectedScenes() -> [UIWindow] {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
    }

    private static func resolveTopMostViewController() -> UIViewController? {
        let windows = windowsFromConnectedScenes()
        guard let root = windows.first(where: { $0.isKeyWindow })?.rootViewController
                ?? windows.first?.rootViewController else {
            return nil
        }
        return walkLeafPresented(from: root)
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
