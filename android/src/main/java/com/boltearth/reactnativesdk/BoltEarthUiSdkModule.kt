package com.boltearth.reactnativesdk

import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.os.Bundle
import com.boltearthsdk.BoltEarthUiSdk
import com.boltearthsdk.BoltLogoutResult
import com.boltearthsdk.SdkEnvironment
import com.boltearthsdk.SdkFontOverrides
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableMap
import com.facebook.react.module.annotations.ReactModule

@ReactModule(name = BoltEarthUiSdkModule.NAME)
class BoltEarthUiSdkModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String = NAME

  @ReactMethod
  fun initialize(config: ReadableMap) {
    val ctx = reactApplicationContext
    val userId =
      config.getString("userId") ?: throw IllegalArgumentException("initialize: userId is required")
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
      if (config.hasKey("localeLanguageTag")) config.getString("localeLanguageTag").orEmpty() else ""

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
  }

  @ReactMethod
  fun logout(promise: Promise) {
    BoltEarthUiSdk.logout(reactApplicationContext) { result ->
      promise.resolve(logoutResultToMap(result))
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
  fun openChargerBookingFlow(promise: Promise) {
    try {
      val launchContext =
        reactApplicationContext.currentActivity
          ?: newTaskApplicationContext(reactApplicationContext)
      BoltEarthUiSdk.openChargerBookingFlow(launchContext)
      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject("E_OPEN_CHARGER_BOOKING", e.message, e)
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
