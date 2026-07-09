// BoltEarthBridge.m
//
// Objective-C shim so React Native discovers the Swift `BoltEarthBridge` native module.
// Add to your RN iOS target next to `BoltEarthBridge.swift`; ensure Swift/Obj‑C bridging is enabled.
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(BoltEarthBridge, NSObject)

// Promise API (preferred) — options: clientID, sdkToken, environment?, language?, sdk* font names?, sdkThemeColorHex?
RCT_EXTERN_METHOD(initializeWithOptions:(NSDictionary *)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

// Fire-and-forget legacy (errors only in native console)
RCT_EXTERN_METHOD(initializeLegacy:(NSString *)clientID
                  sdkToken:(NSString *)sdkToken
                  environment:(NSString *)environment
                  language:(nullable NSString *)language)

RCT_EXTERN_METHOD(setLanguageCode:(NSString *)code
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(currentLanguageCode:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(supportedLanguageCodes:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(setVerboseLoggingEnabled:(BOOL)enabled)

RCT_EXTERN_METHOD(verboseLoggingEnabled:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

// options: vehicleMapperKey (String), vehicleType (String), initialSOCPercent (Number, optional)
RCT_EXTERN_METHOD(presentChargerFlow:(NSDictionary *)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(presentBookingHistoryFlow:(nullable NSDictionary *)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(fetchOEMVehicles:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(fetchCharger:(NSString *)chargerId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(presentWalletFlow:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(logout:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

@end
