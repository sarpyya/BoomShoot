package com.example.bs

import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.bs/back_handler"
    private lateinit var channel: MethodChannel
    private var backInvokedCallback: Any? = null // Store callback for cleanup

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            if (call.method == "exitApp") {
                Log.d("MainActivity", "MethodChannel: exitApp called")
                finish() // Close the activity
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("MainActivity", "onCreate: Setting up back button handling")

        // For API 33+, use OnBackInvokedCallback
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                // Dynamically create OnBackInvokedCallback
                backInvokedCallback = object : android.window.OnBackInvokedCallback {
                    override fun onBackInvoked() {
                        Log.d("MainActivity", "OnBackInvoked: Back button pressed")
                        handleBackPress()
                    }
                }
                // Register the callback
                onBackInvokedDispatcher.registerOnBackInvokedCallback(
                    android.window.OnBackInvokedDispatcher.PRIORITY_DEFAULT,
                    backInvokedCallback as android.window.OnBackInvokedCallback
                )
                Log.d("MainActivity", "Registered OnBackInvokedCallback")
            } catch (e: Exception) {
                Log.e("MainActivity", "Failed to register OnBackInvokedCallback", e)
            }
        }
    }

    @Deprecated("Deprecated in API 33, but required for older APIs")
    override fun onBackPressed() {
        Log.d("MainActivity", "onBackPressed: Back button pressed (API < 33)")
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            handleBackPress()
        } else {
            super.onBackPressed()
        }
    }

    override fun onDestroy() {
        Log.d("MainActivity", "onDestroy: Cleaning up")
        // Unregister OnBackInvokedCallback if it exists
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && backInvokedCallback != null) {
            try {
                onBackInvokedDispatcher.unregisterOnBackInvokedCallback(
                    backInvokedCallback as android.window.OnBackInvokedCallback
                )
                Log.d("MainActivity", "Unregistered OnBackInvokedCallback")
            } catch (e: Exception) {
                Log.e("MainActivity", "Failed to unregister OnBackInvokedCallback", e)
            }
        }
        super.onDestroy()
    }

    private fun handleBackPress() {
        Log.d("MainActivity", "handleBackPress: Invoking MethodChannel")
        channel.invokeMethod(
            "onBackPressed",
            null,
            object : MethodChannel.Result {
                override fun success(result: Any?) {
                    Log.d("MainActivity", "MethodChannel success: $result")
                    val shouldExit = result as? Boolean ?: false
                    if (shouldExit) {
                        finish()
                    }
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    Log.e("MainActivity", "MethodChannel error: $errorCode, $errorMessage")
                }

                override fun notImplemented() {
                    Log.w("MainActivity", "MethodChannel not implemented")
                }
            }
        )
    }
}