package com.boltearth.reactnativesdk

import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.os.Bundle
import com.boltearthsdk.BoltEarthUiSdk
import com.boltearthsdk.BoltLogoutResult
import com.boltearthsdk.SdkEnvironment
import com.boltearthsdk.SdkFontOverrides
import com.boltearthsdk.VehicleType
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.module.annotations.ReactModule
import org.json.JSONArray
import org.json.JSONObject

@ReactModule(name = BoltEarthUiSdkModule.NAME)
class BoltEarthUiSdkModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String = NAME

  @ReactMethod
  fun initialize(config: ReadableMap, promise: Promise) {
    try {
      val ctx = reactApplicationContext
      val userId =
        config.getString("userId")
          ?: throw IllegalArgumentException("initialize: userId is required")
      val sdkToken =
        config.getString("sdkToken")
          ?: throw IllegalArgumentException("initialize: sdkToken is required")

      val environment = when (
        if (config.hasKey("environment")) config.getString("environment")?.lowercase() else null
      ) {
        "production" -> SdkEnvironment.Production
        else -> SdkEnvironment.Development
      }
      val primaryColor =
        if (config.hasKey("primaryColor")) config.getString("primaryColor").orEmpty() else ""
      val localeLanguageTag =
        if (config.hasKey("localeLanguageTag")) config.getString("localeLanguageTag").orEmpty()
        else ""

      val fonts =
        if (config.hasKey("fontOverrides")) {
          parseFontOverrides(config.getMap("fontOverrides")!!)
        } else {
          SdkFontOverrides()
        }

      BoltEarthUiSdk.initialize(
        ctx,
        userId,
        sdkToken,
        environment,
        primaryColor,
        fonts,
        localeLanguageTag,
      )
      promise.resolve(null)
    } catch (e: IllegalArgumentException) {
      promise.reject("E_INITIALIZE_INVALID_ARGS", e.message, e)
    } catch (e: Exception) {
      promise.reject("E_INITIALIZE", e.message, e)
    }
  }

  @ReactMethod
  fun logout(promise: Promise) {
    try {
      BoltEarthUiSdk.logout(reactApplicationContext) { result ->
        promise.resolve(logoutResultToMap(result))
      }
    } catch (e: Exception) {
      promise.reject("E_LOGOUT", e.message, e)
    }
  }

  @ReactMethod
  fun openUsersBookingsList(promise: Promise) {
    try {
      val launchContext =
        reactApplicationContext.currentActivity
          ?: newTaskApplicationContext(reactApplicationContext)
      BoltEarthUiSdk.openUsersBookingsList(launchContext)
      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject("E_OPEN_BOOKINGS", e.message, e)
    }
  }

  @ReactMethod
  fun setLocale(localeLanguageTag: String, promise: Promise) {
    try {
      BoltEarthUiSdk.setLocale(reactApplicationContext, localeLanguageTag)
      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject("E_SET_LOCALE", e.message, e)
    }
  }

  @ReactMethod
  fun getCurrentLanguageCode(promise: Promise) {
    try {
      promise.resolve(BoltEarthUiSdk.getCurrentLocaleLanguageTag())
    } catch (e: Exception) {
      promise.reject("E_GET_LANGUAGE_CODE", e.message, e)
    }
  }

  @ReactMethod
  fun getSupportedLanguageCodes(promise: Promise) {
    try {
      val array = Arguments.createArray()
      BoltEarthUiSdk.getSupportedLocaleLanguageTags().forEach { array.pushString(it) }
      promise.resolve(array)
    } catch (e: Exception) {
      promise.reject("E_GET_SUPPORTED_LANGUAGES", e.message, e)
    }
  }

  @ReactMethod
  fun openChargerBookingFlow(
    vehicleId: String,
    vehicleType: String,
    initialSOCPercent: Int,
    promise: Promise,
  ) {
    try {
      val launchContext =
        reactApplicationContext.currentActivity
          ?: newTaskApplicationContext(reactApplicationContext)
      BoltEarthUiSdk.openChargerBookingFlow(
        launchContext,
        vehicleId,
        VehicleType.valueOf(vehicleType),
        initialSOCPercent,
      )
      promise.resolve(null)
    } catch (e: IllegalArgumentException) {
      promise.reject("BOLT_INVALID_VEHICLE_TYPE", e.message, e)
    } catch (e: Exception) {
      promise.reject("E_OPEN_CHARGER_BOOKING", e.message, e)
    }
  }

  /**
   * Opens the wallet flow (balance, transaction history, add money).
   * Mirrors iOS `BoltEarthBridge.presentWalletFlow`.
   */
  @ReactMethod
  fun presentWalletFlow(promise: Promise) {
    try {
      val launchContext =
        reactApplicationContext.currentActivity
          ?: newTaskApplicationContext(reactApplicationContext)
      BoltEarthUiSdk.presentWalletFlow(launchContext)
      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject("E_PRESENT_WALLET", e.message, e)
    }
  }

  /**
   * Fetches the OEM vehicle catalog. Resolves with an array of vehicle objects (each with
   * `externalKey`, `model`, `company`, `type`, `batteryCapacity`, …) to mirror the iOS
   * `fetchOEMVehicles` array contract. The native SDK returns the catalog wrapped in a JSON object;
   * the enclosed array (`response`, or `data` on newer builds) is unwrapped here.
   */
  @ReactMethod
  fun fetchOEMVehicles(promise: Promise) {
    try {
      BoltEarthUiSdk.fetchOEMVehicles(reactApplicationContext) { response ->
        val array = response.optJSONArray("response") ?: response.optJSONArray("data")
        promise.resolve(
          if (array != null) jsonArrayToWritableArray(array) else Arguments.createArray()
        )
      }
    } catch (e: Exception) {
      promise.reject("E_FETCH_OEM_VEHICLES", e.message, e)
    }
  }

  /**
   * Fetches charger details by Bolt charger ID. Resolves with the full API response object
   * (`status`, `message`, and `data` on success). Runs the SDK login gate internally.
   * Mirrors iOS `BoltEarthBridge.fetchCharger`.
   */
  @ReactMethod
  fun fetchCharger(chargerId: String, promise: Promise) {
    try {
      BoltEarthUiSdk.fetchCharger(reactApplicationContext, chargerId) { response ->
        promise.resolve(jsonObjectToWritableMap(response))
      }
    } catch (e: IllegalArgumentException) {
      promise.reject("BOLT_INVALID_CHARGER_ID", e.message, e)
    } catch (e: IllegalStateException) {
      promise.reject("E_NOT_INITIALIZED", e.message, e)
    } catch (e: Exception) {
      promise.reject("E_FETCH_CHARGER", e.message, e)
    }
  }

  /**
   * Returns static Bolt Earth support contact info (whatsapp, call, email).
   * Mirrors iOS `BoltEarthBridge.fetchContactSupportInfo`. No network call or prior
   * `initialize` required.
   */
  @ReactMethod
  fun fetchContactSupportInfo(promise: Promise) {
    try {
      promise.resolve(jsonObjectToWritableMap(BoltEarthUiSdk.fetchContactSupportInfo()))
    } catch (e: Exception) {
      promise.reject("E_FETCH_CONTACT_SUPPORT", e.message, e)
    }
  }

  private fun newTaskApplicationContext(appContext: Context): Context {
    return object : ContextWrapper(appContext) {
      override fun startActivity(intent: Intent) {
        if (intent.flags and Intent.FLAG_ACTIVITY_NEW_TASK == 0) {
          intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        baseContext.startActivity(intent)
      }

      override fun startActivity(intent: Intent, options: Bundle?) {
        if (intent.flags and Intent.FLAG_ACTIVITY_NEW_TASK == 0) {
          intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        baseContext.startActivity(intent, options)
      }
    }
  }

  private fun parseFontOverrides(m: ReadableMap): SdkFontOverrides {
    fun optInt(key: String): Int = if (m.hasKey(key)) m.getInt(key) else 0
    return SdkFontOverrides(
      optInt("light"),
      optInt("regular"),
      optInt("medium"),
      optInt("semiBold"),
      optInt("bold"),
    )
  }

  /** Recursively converts an [org.json.JSONObject] to a React [WritableMap]. */
  private fun jsonObjectToWritableMap(obj: JSONObject): WritableMap {
    val map = Arguments.createMap()
    val keys = obj.keys()
    while (keys.hasNext()) {
      val key = keys.next()
      when (val value = obj.get(key)) {
        is JSONObject -> map.putMap(key, jsonObjectToWritableMap(value))
        is JSONArray -> map.putArray(key, jsonArrayToWritableArray(value))
        is Boolean -> map.putBoolean(key, value)
        is Int -> map.putInt(key, value)
        is Long -> map.putDouble(key, value.toDouble())
        is Double -> map.putDouble(key, value)
        JSONObject.NULL -> map.putNull(key)
        else -> map.putString(key, value.toString())
      }
    }
    return map
  }

  /** Recursively converts an [org.json.JSONArray] to a React [WritableArray]. */
  private fun jsonArrayToWritableArray(arr: JSONArray): WritableArray {
    val out = Arguments.createArray()
    for (i in 0 until arr.length()) {
      when (val value = arr.get(i)) {
        is JSONObject -> out.pushMap(jsonObjectToWritableMap(value))
        is JSONArray -> out.pushArray(jsonArrayToWritableArray(value))
        is Boolean -> out.pushBoolean(value)
        is Int -> out.pushInt(value)
        is Long -> out.pushDouble(value.toDouble())
        is Double -> out.pushDouble(value)
        JSONObject.NULL -> out.pushNull()
        else -> out.pushString(value.toString())
      }
    }
    return out
  }

  private fun logoutResultToMap(result: BoltLogoutResult): WritableMap {
    val map = Arguments.createMap()
    when (result) {
      is BoltLogoutResult.Success -> map.putString("type", "success")
      is BoltLogoutResult.Failure -> {
        map.putString("type", "failure")
        val err = result.error
        map.putString("errorMessage", err?.message)
        map.putString("errorClass", err?.javaClass?.name)
      }
      else -> map.putString("type", "unknown")
    }
    return map
  }

  companion object {
    const val NAME = "BoltEarthUiSdk"
  }
}
