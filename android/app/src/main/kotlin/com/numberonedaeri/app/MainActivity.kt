package com.numberonedaeri.app

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Android 15+ edge-to-edge (Play Console 권장)
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
