package com.r0rt1z2.froggy

import android.os.Bundle
import android.view.KeyEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var tvMenuOpen = false
    private var tvMenuChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        tvMenuChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "froggy/tv_menu"
        )
        tvMenuChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setTvMenuOpen" -> {
                    tvMenuOpen = call.argument<Boolean>("open") == true
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode == KeyEvent.KEYCODE_BACK && tvMenuOpen) {
            if (event.action == KeyEvent.ACTION_UP) {
                tvMenuChannel?.invokeMethod("backPressed", null)
            }
            return true
        }
        return super.dispatchKeyEvent(event)
    }
}
