package com.example.final_year_project_mobile_app


import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterFragmentActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine)
  }
}
