package com.example.videorecord


import android.content.ContentValues
import android.media.MediaScannerConnection
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.os.StatFs
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.channels.FileChannel

class MainActivity : FlutterActivity() {
    private val STORAGE_CHANNEL = "com.example.videorecord/storage"
    private val MEDIA_CHANNEL = "com.example.videorecord/media"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Storage Channel Handler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
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

        // Media Channel Handler for saving videos to the gallery
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "addToGallery") {
                    val path: String? = call.argument("path")
                    if (path != null) {
                        addVideoToGallery(path, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is required", null)
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

    private fun addVideoToGallery(path: String, result: MethodChannel.Result) {
        try {
            val file = File(path)
            val dcimDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM), "Camera")

            if (!dcimDir.exists()) {
                dcimDir.mkdirs()
            }

            val newFile = File(dcimDir, file.name)

            // Copy the video to the DCIM/Camera directory
            copyFile(file, newFile)

            // Notify the media scanner to index the new file
            MediaScannerConnection.scanFile(
                this,
                arrayOf(newFile.absolutePath),
                arrayOf("video/mp4")
            ) { scannedPath, uri ->
                if (uri != null) {
                    result.success("Video added to gallery at: $scannedPath")
                } else {
                    result.error("FAILED", "Failed to add video to gallery", null)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            result.error("FAILED", "Error adding video to gallery: ${e.message}", null)
        }
    }

    private fun copyFile(sourceFile: File, destFile: File) {
        if (!destFile.parentFile.exists()) destFile.parentFile.mkdirs()

        if (!destFile.exists()) {
            destFile.createNewFile()
        }

        FileInputStream(sourceFile).use { input ->
            FileOutputStream(destFile).use { output ->
                val sourceChannel: FileChannel = input.channel
                val destChannel: FileChannel = output.channel
                destChannel.transferFrom(sourceChannel, 0, sourceChannel.size())
            }
        }
    }
}
