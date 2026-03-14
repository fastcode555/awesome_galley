package com.awesome.awesome_galley

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.exifinterface.media.ExifInterface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "image_gallery/platform"
    private var openedFiles = mutableListOf<String>()
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "verifyFileAssociations" -> {
                    // File associations are configured in AndroidManifest.xml
                    result.success(null)
                }
                
                "openDefaultAppSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
                        startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", "Failed to open settings: ${e.message}", null)
                    }
                }
                
                "getOpenedFiles" -> {
                    result.success(openedFiles.toList())
                    openedFiles.clear()
                }
                
                "extractExifData" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath == null) {
                        result.error("INVALID_ARGUMENTS", "File path is required", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        val exifData = extractExifData(filePath)
                        result.success(exifData)
                    } catch (e: Exception) {
                        result.error("EXTRACTION_FAILED", "Failed to extract EXIF data: ${e.message}", null)
                    }
                }
                
                "getAndroidVersion" -> {
                    result.success(Build.VERSION.SDK_INT)
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Handle intent when activity is created
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW) {
            intent.data?.let { uri ->
                // Convert URI to file path
                val filePath = getFilePathFromUri(uri)
                if (filePath != null) {
                    openedFiles.add(filePath)
                }
            }
        }
    }
    
    private fun getFilePathFromUri(uri: Uri): String? {
        return try {
            when (uri.scheme) {
                "file" -> uri.path
                "content" -> {
                    // For content URIs, we need to use ContentResolver
                    // This is a simplified implementation
                    val cursor = contentResolver.query(uri, null, null, null, null)
                    cursor?.use {
                        if (it.moveToFirst()) {
                            val columnIndex = it.getColumnIndex("_data")
                            if (columnIndex >= 0) {
                                it.getString(columnIndex)
                            } else {
                                uri.toString()
                            }
                        } else {
                            uri.toString()
                        }
                    }
                }
                else -> uri.toString()
            }
        } catch (e: Exception) {
            null
        }
    }
    
    private fun extractExifData(filePath: String): Map<String, Any>? {
        return try {
            val exif = ExifInterface(filePath)
            val exifData = mutableMapOf<String, Any>()
            
            // Extract date taken
            exif.getAttribute(ExifInterface.TAG_DATETIME_ORIGINAL)?.let {
                exifData["dateTaken"] = it
            }
            
            // Extract camera make
            exif.getAttribute(ExifInterface.TAG_MAKE)?.let {
                exifData["cameraMake"] = it
            }
            
            // Extract camera model
            exif.getAttribute(ExifInterface.TAG_MODEL)?.let {
                exifData["cameraModel"] = it
            }
            
            // Extract focal length
            exif.getAttributeDouble(ExifInterface.TAG_FOCAL_LENGTH, 0.0).let {
                if (it > 0.0) {
                    exifData["focalLength"] = it
                }
            }
            
            // Extract aperture
            exif.getAttributeDouble(ExifInterface.TAG_F_NUMBER, 0.0).let {
                if (it > 0.0) {
                    exifData["aperture"] = it
                }
            }
            
            // Extract ISO
            exif.getAttribute(ExifInterface.TAG_ISO_SPEED)?.let {
                exifData["iso"] = it
            }
            
            // Extract exposure time
            exif.getAttribute(ExifInterface.TAG_EXPOSURE_TIME)?.let {
                exifData["exposureTime"] = it
            }
            
            // Extract GPS coordinates
            val latLong = FloatArray(2)
            if (exif.getLatLong(latLong)) {
                exifData["latitude"] = latLong[0].toDouble()
                exifData["longitude"] = latLong[1].toDouble()
            }
            
            if (exifData.isEmpty()) null else exifData
        } catch (e: IOException) {
            null
        }
    }
}
