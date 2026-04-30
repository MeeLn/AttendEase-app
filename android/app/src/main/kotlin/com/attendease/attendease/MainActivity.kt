package com.attendease.attendease

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "attendease/face_recognition"
    private val faceRequestCode = 9001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasRegisteredFace" -> handleHasRegisteredFace(call, result)
                    "registerFace" -> launchFaceActivity(call, result, FaceRecognitionActivity.MODE_REGISTER)
                    "recognizeFace" -> launchFaceActivity(call, result, FaceRecognitionActivity.MODE_RECOGNIZE)
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleHasRegisteredFace(call: MethodCall, result: MethodChannel.Result) {
        val userKey = call.argument<String>("userKey")
        if (userKey.isNullOrBlank()) {
            result.error("invalid_args", "Missing user key.", null)
            return
        }
        val exists = FaceFileStore.getFaceFile(this, userKey).exists()
        result.success(exists)
    }

    private fun launchFaceActivity(
        call: MethodCall,
        result: MethodChannel.Result,
        mode: String,
    ) {
        val userKey = call.argument<String>("userKey")
        if (userKey.isNullOrBlank()) {
            result.error("invalid_args", "Missing user key.", null)
            return
        }
        if (pendingResult != null) {
            result.error("busy", "A face recognition request is already in progress.", null)
            return
        }

        pendingResult = result
        val intent = Intent(this, FaceRecognitionActivity::class.java).apply {
            putExtra(FaceRecognitionActivity.EXTRA_MODE, mode)
            putExtra(FaceRecognitionActivity.EXTRA_USER_KEY, userKey)
        }
        startActivityForResult(intent, faceRequestCode)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != faceRequestCode) {
            return
        }

        val callback = pendingResult ?: return
        pendingResult = null

        val payload = hashMapOf<String, Any?>(
            "success" to (resultCode == Activity.RESULT_OK),
            "message" to data?.getStringExtra(FaceRecognitionActivity.EXTRA_MESSAGE),
            "faceRegistered" to data?.getBooleanExtra(FaceRecognitionActivity.EXTRA_FACE_REGISTERED, false),
        )
        callback.success(payload)
    }
}
