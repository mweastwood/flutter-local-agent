package com.mweastwood.local_agent

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.ImagePart
import com.google.mlkit.genai.prompt.TextPart
import com.google.mlkit.genai.prompt.generateContentRequest
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** LocalAgentPlugin */
class LocalAgentPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val ioScope = CoroutineScope(Dispatchers.IO)

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.mweastwood.local_agent")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val model = Generation.getClient()

        when (call.method) {
            "checkStatus" -> {
                ioScope.launch {
                    try {
                        val status = model.checkStatus()
                        val statusStr = when (status) {
                            FeatureStatus.AVAILABLE -> "available"
                            FeatureStatus.DOWNLOADABLE -> "downloadable"
                            FeatureStatus.DOWNLOADING -> "downloading"
                            else -> "unavailable"
                        }
                        withContext(Dispatchers.Main) {
                            result.success(statusStr)
                        }
                    } catch (e: Exception) {
                        Log.e("LocalAgentPlugin", "Error checking status: ${e.message}", e)
                        withContext(Dispatchers.Main) {
                            result.success("unavailable")
                        }
                    }
                }
            }
            "triggerDownload" -> {
                ioScope.launch {
                    try {
                        model.download().collect { downloadStatus ->
                            Log.d("LocalAgentPlugin", "Download status: $downloadStatus")
                        }
                    } catch (e: Exception) {
                        Log.e("LocalAgentPlugin", "Error triggering download: ${e.message}", e)
                    }
                }
                result.success(null)
            }
            "generateContent" -> {
                val promptText = call.argument<String>("prompt")
                val imageBytes = call.argument<ByteArray>("image")
                val temperature = call.argument<Double>("temperature")?.toFloat() ?: 0.7f
                val maxOutputTokens = call.argument<Int>("maxOutputTokens") ?: 1024

                if (promptText == null) {
                    result.error("invalid_argument", "prompt is missing", null)
                    return
                }

                ioScope.launch {
                    var bitmap: Bitmap? = null
                    try {
                        bitmap = if (imageBytes != null && imageBytes.isNotEmpty()) {
                            BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                        } else {
                            null
                        }

                        val response = if (bitmap != null) {
                            model.generateContent(
                                generateContentRequest(ImagePart(bitmap), TextPart(promptText)) {
                                    this.temperature = temperature
                                    this.maxOutputTokens = maxOutputTokens
                                }
                            )
                        } else {
                            model.generateContent(
                                generateContentRequest(TextPart(promptText)) {
                                    this.temperature = temperature
                                    this.maxOutputTokens = maxOutputTokens
                                }
                            )
                        }

                        val responseText = response.candidates.firstOrNull()?.text ?: ""

                        withContext(Dispatchers.Main) {
                            result.success(responseText)
                        }
                    } catch (e: Throwable) {
                        Log.e("LocalAgentPlugin", "Error generating content: ${e.message}", e)
                        withContext(Dispatchers.Main) {
                            result.error("generation_failed", e.message, null)
                        }
                    } finally {
                        bitmap?.recycle()
                    }
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
