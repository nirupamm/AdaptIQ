package com.example.frontend

import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import org.opencv.android.OpenCVLoader
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.MatOfRect
import org.opencv.core.Rect
import org.opencv.core.Size
import org.opencv.imgproc.Imgproc
import org.opencv.objdetect.CascadeClassifier
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "adaptiq/opencv_detection"
    private val logTag = "AdaptIQ"
    private var faceCascade: CascadeClassifier? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initOpenCv" -> {
                        Log.d(logTag, "initOpenCv called from Flutter")
                        val ok = initOpenCvAndCascade()
                        Log.d(logTag, "initOpenCv returning: $ok")
                        result.success(ok)
                    }

                    "detectFace" -> {
                        try {
                            Log.d(logTag, "detectFace called from Flutter")

                            val bytes = call.argument<ByteArray>("bytes")
                            val width = call.argument<Int>("width") ?: 0
                            val height = call.argument<Int>("height") ?: 0

                            Log.d(
                                logTag,
                                "detectFace input width=$width height=$height bytes=${bytes?.size ?: 0}"
                            )

                            if (bytes == null || width <= 0 || height <= 0) {
                                result.success(
                                    mapOf(
                                        "facePresent" to false,
                                        "offCenter" to false,
                                        "multipleFaces" to false,
                                        "error" to "invalid_input"
                                    )
                                )
                            } else {
                                result.success(detectFace(bytes, width, height))
                            }
                        } catch (e: Exception) {
                            Log.e(logTag, "detectFace exception: ${e.message}", e)
                            result.success(
                                mapOf(
                                    "facePresent" to false,
                                    "offCenter" to false,
                                    "multipleFaces" to false,
                                    "error" to (e.message ?: "detect_error")
                                )
                            )
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun initOpenCvAndCascade(): Boolean {
        return try {
            Log.d(logTag, "OpenCV init started")

            val openCvOk = OpenCVLoader.initDebug()
            Log.d(logTag, "OpenCVLoader.initDebug() = $openCvOk")

            if (!openCvOk) {
                Log.e(logTag, "OpenCV init FAILED")
                return false
            }

            if (faceCascade != null) {
                Log.d(logTag, "Cascade already loaded")
                return true
            }

            val cascadeFile = File(filesDir, "haarcascade_frontalface_default.xml")
            Log.d(logTag, "Cascade file path: ${cascadeFile.absolutePath}")

            if (!cascadeFile.exists() || cascadeFile.length() == 0L) {
                Log.d(logTag, "Copying cascade from app assets...")

                assets.open("haarcascade_frontalface_default.xml").use { inputStream ->
                    FileOutputStream(cascadeFile).use { outputStream ->
                        val buffer = ByteArray(4096)
                        var bytesRead: Int
                        while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                            outputStream.write(buffer, 0, bytesRead)
                        }
                        outputStream.flush()
                    }
                }
            }

            Log.d(
                logTag,
                "Cascade exists=${cascadeFile.exists()} size=${cascadeFile.length()}"
            )

            if (!cascadeFile.exists() || cascadeFile.length() == 0L) {
                Log.e(logTag, "Cascade file invalid or empty")
                return false
            }

            val classifier = CascadeClassifier(cascadeFile.absolutePath)
            if (classifier.empty()) {
                Log.e(logTag, "Cascade classifier is EMPTY")
                return false
            }

            faceCascade = classifier
            Log.d(logTag, "Cascade loaded successfully")
            true
        } catch (e: Exception) {
            Log.e(logTag, "OpenCV init exception: ${e.message}", e)
            false
        }
    }

    private fun detectFace(bytes: ByteArray, width: Int, height: Int): Map<String, Any> {
        val cascade = faceCascade ?: return mapOf(
            "facePresent" to false,
            "offCenter" to false,
            "multipleFaces" to false,
            "error" to "cascade_not_loaded"
        )

        var yuv: Mat? = null
        var gray: Mat? = null
        var faces: MatOfRect? = null

        return try {
            yuv = Mat(height + height / 2, width, CvType.CV_8UC1)
            yuv.put(0, 0, bytes)

            gray = Mat()
            Imgproc.cvtColor(yuv, gray, Imgproc.COLOR_YUV2GRAY_NV21)
            Imgproc.equalizeHist(gray, gray)

            faces = MatOfRect()
            cascade.detectMultiScale(
                gray,
                faces,
                1.15,
                5,
                0,
                Size(60.0, 60.0),
                Size()
            )

            val detectedFaces: Array<Rect> = faces.toArray()
            val facePresent = detectedFaces.isNotEmpty()
            val multipleFaces = detectedFaces.size > 1

            var offCenter = false
            

            Log.d(
                logTag,
                "Faces detected=${detectedFaces.size}, facePresent=$facePresent, offCenter=$offCenter, multipleFaces=$multipleFaces"
            )

            mapOf(
                "facePresent" to facePresent,
                "offCenter" to offCenter,
                "multipleFaces" to multipleFaces
            )
        } catch (e: Exception) {
            Log.e(logTag, "detectFace OpenCV exception: ${e.message}", e)
            mapOf(
                "facePresent" to false,
                "offCenter" to false,
                "multipleFaces" to false,
                "error" to (e.message ?: "opencv_detect_error")
            )
        } finally {
            faces?.release()
            gray?.release()
            yuv?.release()
        }
    }
}