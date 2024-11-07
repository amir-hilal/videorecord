package com.example.videorecord

import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.videorecord/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAvailableStorage") {
                val availableStorage = getAvailableStorage()
                if (availableStorage != null) {
                    result.success(availableStorage)
                } else {
                    result.error("UNAVAILABLE", "Could not get available storage.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getAvailableStorage(): Long? {
        return try {
            val stat = StatFs(Environment.getDataDirectory().path)
            val availableBlocks = stat.availableBlocksLong
            val blockSize = stat.blockSizeLong
            availableBlocks * blockSize
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
