package com.example.mictlan_client

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    //1.- Heredamos de FlutterActivity para delegar el arranque al motor de Flutter.

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        //2.- Registramos un MethodChannel para exponer configuraciones nativas a Flutter.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.mictlan_client/config")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isGoogleMapsConfigured" -> result.success(isGoogleMapsConfigured())
                    else -> result.notImplemented()
                }
            }
    }

    //3.- isGoogleMapsConfigured revisa el metadata y confirma que exista un API key válido.
    private fun isGoogleMapsConfigured(): Boolean {
        return try {
            val info = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
            val value = info.metaData?.getString("com.google.android.geo.API_KEY").orEmpty()
            value.isNotBlank() && value != "YOUR_ANDROID_KEY"
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }
}
