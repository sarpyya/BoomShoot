package com.example.bs

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.window.OnBackInvokedCallback
import android.window.OnBackInvokedDispatcher

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.bs/back_handler"
    private lateinit var channel: MethodChannel
    private val onBackInvokedCallback = object : OnBackInvokedCallback {
        override fun onBackInvoked() {
            android.util.Log.d("MainActivity", "onBackInvoked: Back button pressed")
            handleBackPress()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            if (call.method == "exitApp") {
                android.util.Log.d("MainActivity", "MethodChannel: exitApp called")
                finish() // Close the activity
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        android.util.Log.d("MainActivity", "onCreate: Setting up back button handling")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Clear any existing OnBackInvokedCallbacks (including Flutter's default)
            val dispatcherField = try {
                onBackInvokedDispatcher::class.java.getDeclaredField("mOnBackInvokedCallbacks")
            } catch (e: NoSuchFieldException) {
                android.util.Log.e("MainActivity", "Failed to access mOnBackInvokedCallbacks field", e)
                null
            }

            if (dispatcherField != null) {
                try {
                    dispatcherField.isAccessible = true
                    @Suppress("UNCHECKED_CAST")
                    val callbacks = dispatcherField.get(onBackInvokedDispatcher) as? MutableList<OnBackInvokedCallback>
                    callbacks?.clear()
                    android.util.Log.d("MainActivity", "Cleared existing OnBackInvokedCallbacks")
                } catch (e: Exception) {
                    android.util.Log.e("MainActivity", "Failed to clear OnBackInvokedCallbacks", e)
                }
            }

            // Register our custom OnBackInvokedCallback
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT,
                onBackInvokedCallback
            )
            android.util.Log.d("MainActivity", "Registered custom OnBackInvokedCallback")
        }
    }

    @Deprecated("Deprecated in API 33, but required for older APIs")
    override fun onBackPressed() {
        android.util.Log.d("MainActivity", "onBackPressed: Back button pressed (API < 33)")
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            handleBackPress()
        } else {
            super.onBackPressed()
        }
    }

    override fun onDestroy() {
        android.util.Log.d("MainActivity", "onDestroy: Unregistering OnBackInvokedCallback")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            onBackInvokedDispatcher.unregisterOnBackInvokedCallback(onBackInvokedCallback)
        }
        super.onDestroy()
    }

    private fun handleBackPress() {
        android.util.Log.d("MainActivity", "handleBackPress: Invoking MethodChannel")
        channel.invokeMethod(
            "onBackPressed",
            null,
            object : MethodChannel.Result {
                override fun success(result: Any?) {
                    android.util.Log.d("MainActivity", "MethodChannel success: $result")
                    val shouldExit = result as? Boolean ?: false
                    if (shouldExit) {
                        finish()
                    }
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    android.util.Log.e("MainActivity", "MethodChannel error: $errorCode, $errorMessage")
                }

                override fun notImplemented() {
                    android.util.Log.w("MainActivity", "MethodChannel not implemented")
                }
            }
        )
    }
}