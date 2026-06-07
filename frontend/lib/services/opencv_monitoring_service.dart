import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'api_service.dart';

class OpenCVMonitoringService {
  bool _isMonitoring = false;
  bool _isFaceDetected = true;
  bool _isFaceOffCenter = false;
  int _consecutiveNoFaceFrames = 0;
  int _warningCount = 0;
  final int _maxWarnings = 3;

  Timer? _monitoringTimer;
  CameraController? _cameraController;

  final MethodChannel _openCvChannel = const MethodChannel(
    'adaptiq/opencv_detection',
  );

  String? _lastWarning;
  DateTime? _monitoringStartedAt;
  DateTime? _lastWarningAt;
  int _consecutiveViolationChecks = 0;
  bool _terminationTriggered = false;
  int _simulationTickCount = 0;
  bool _useOpenCvDetection = false;
  bool _isProcessingFrame = false;
  DateTime? _lastFrameProcessAt;

  final int _initialGracePeriodSeconds = 5;
  final int _warningDebounceSeconds = 4;
  final int _requiredViolationChecks = 3;

  Function(String)? onWarning;
  Function()? onForceQuit;
  Function(String)? onStatusUpdate;

  bool get isMonitoring => _isMonitoring;
  bool get isFaceDetected => _isFaceDetected;
  bool get isFaceOffCenter => _isFaceOffCenter;
  int get warningCount => _warningCount;
  int get maxWarnings => _maxWarnings;

  Future<bool> initializeCamera() async {
    print('OpenCV: initializeCamera entered');

    if (kIsWeb) {
      print('OpenCV: web detected, using simulation');
      onStatusUpdate?.call(
        'Monitoring simulation mode active (web not supported)',
      );
      _useOpenCvDetection = false;
      return false;
    }

    if (defaultTargetPlatform != TargetPlatform.android) {
      print('OpenCV: non-Android platform detected, using simulation');
      onStatusUpdate?.call('Monitoring simulation mode active (Android only)');
      _useOpenCvDetection = false;
      return false;
    }

    try {
      final cameras = await availableCameras();
      print('OpenCV: cameras found = ${cameras.length}');

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      print(
        'OpenCV: selected camera = ${frontCamera.name}, lens = ${frontCamera.lensDirection}',
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup
            .nv21, // Use NV21 for better compatibility with my device
      );

      await _cameraController!.initialize();
      print('OpenCV: camera initialized');

      final bool initialized =
          await _openCvChannel.invokeMethod<bool>('initOpenCv') ?? false;

      print('OpenCV: initOpenCv result = $initialized');
      _useOpenCvDetection = initialized;

      if (_useOpenCvDetection) {
        await _cameraController!.startImageStream(_processCameraFrame);
        print('OpenCV: image stream started');
        onStatusUpdate?.call('Monitoring active');
        return true;
      } else {
        print('OpenCV: OpenCV init failed, using simulation fallback');
        onStatusUpdate?.call(
          'Real detection unavailable, simulation fallback active',
        );
        return false;
      }
    } catch (e) {
      print('OpenCV: initializeCamera failed = $e');
      _useOpenCvDetection = false;
      onStatusUpdate?.call(
        'Camera/OpenCV init failed. Simulation fallback active.',
      );
      return false;
    }
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    if (!_isMonitoring || !_useOpenCvDetection) return;
    if (_isProcessingFrame) return;

    final now = DateTime.now();
    if (_lastFrameProcessAt != null &&
        now.difference(_lastFrameProcessAt!).inMilliseconds < 500) {
      return;
    }

    _isProcessingFrame = true;
    _lastFrameProcessAt = now;

    try {
      print('OpenCV: frame received ${image.width}x${image.height}');
      final Uint8List nv21Bytes = image.planes[0].bytes;

      print('OpenCV: calling native detectFace');
      final response = await _openCvChannel.invokeMethod<dynamic>(
        'detectFace',
        {'bytes': nv21Bytes, 'width': image.width, 'height': image.height},
      );

      print('OpenCV: native response = $response');

      if (response is Map) {
        final facePresent = response['facePresent'] == true;
        final offCenter = response['offCenter'] == true;
        final multipleFaces = response['multipleFaces'] == true;

        _isFaceDetected = facePresent;
        _isFaceOffCenter = multipleFaces ? true : offCenter;

        if (!_isFaceDetected) {
          onStatusUpdate?.call('No face detected');
        } else if (_isFaceOffCenter) {
          onStatusUpdate?.call('Face off-center');
        } else {
          onStatusUpdate?.call('Face detected');
        }
      } else {
        print('OpenCV: unexpected native response type');
      }
    } catch (e) {
      print('OpenCV: frame processing error = $e');
      onStatusUpdate?.call('OpenCV frame error: $e');
      // Do NOT permanently disable OpenCV here.
      // A single bad frame should not kill the real pipeline.
    } finally {
      _isProcessingFrame = false;
    }
  }

  // Uint8List _toNv21(CameraImage image) {
  //   final yPlane = image.planes[0].bytes;
  //   final uPlane = image.planes[1].bytes;
  //   final vPlane = image.planes[2].bytes;

  //   // Simple conversion attempt for common YUV420 layouts.
  //   // Good enough for debugging whether pipeline is flowing.
  //   return Uint8List.fromList([...yPlane, ...vPlane, ...uPlane]);
  // }

  Future<bool> startMonitoring(int quizSessionId) async {
    print('OpenCV: startMonitoring called');

    if (_isMonitoring) {
      print('OpenCV: monitoring already active');
      onStatusUpdate?.call('Monitoring already active');
      return true;
    }

    try {
      final bool cameraInitialized = await initializeCamera();

      if (!cameraInitialized) {
        print('OpenCV: real detection unavailable, simulation fallback active');
        onStatusUpdate?.call(
          'Real detection unavailable, simulation fallback active',
        );
      }

      _isMonitoring = true;
      _warningCount = 0;
      _lastWarning = null;
      _monitoringStartedAt = DateTime.now();
      _lastWarningAt = null;
      _consecutiveViolationChecks = 0;
      _terminationTriggered = false;
      _simulationTickCount = 0;
      _isFaceDetected = true;
      _isFaceOffCenter = false;

      _monitoringTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        _checkMonitoringStatus(quizSessionId);
      });

      print('OpenCV: monitoring timer started');
      onStatusUpdate?.call('Monitoring active');
      return true;
    } catch (e) {
      print('OpenCV: startMonitoring error = $e');
      onStatusUpdate?.call('Error starting monitoring: $e');
      return false;
    }
  }

  void stopMonitoring() {
    print('OpenCV: stopMonitoring called');

    _monitoringTimer?.cancel();
    _monitoringTimer = null;

    _cameraController?.stopImageStream().catchError((e) {
      print('OpenCV: stopImageStream error = $e');
    });

    _cameraController?.dispose().catchError((e) {
      print('OpenCV: camera dispose error = $e');
    });

    _cameraController = null;
    _isMonitoring = false;
    _isFaceDetected = true;
    _isFaceOffCenter = false;
    _consecutiveNoFaceFrames = 0;
    _monitoringStartedAt = null;
    _lastWarningAt = null;
    _consecutiveViolationChecks = 0;
    _terminationTriggered = false;
    _simulationTickCount = 0;
    _useOpenCvDetection = false;
    _isProcessingFrame = false;
    _lastFrameProcessAt = null;

    onStatusUpdate?.call('Monitoring stopped');
  }

  void _simulateFaceDetection() {
    _simulationTickCount++;
    final int cycleTick = _simulationTickCount % 20;

    final bool faceDetected = cycleTick < 14;
    final bool faceOffCenter = cycleTick >= 8 && cycleTick < 14;

    if (faceDetected != _isFaceDetected) {
      _isFaceDetected = faceDetected;
      if (!_isFaceDetected) {
        _consecutiveNoFaceFrames = 1;
      } else {
        _consecutiveNoFaceFrames = 0;
      }
    } else if (!_isFaceDetected) {
      _consecutiveNoFaceFrames++;
    }

    _isFaceOffCenter = _isFaceDetected && faceOffCenter;
  }

  void _checkMonitoringStatus(int quizSessionId) {
    if (!_isMonitoring) return;

    try {
      if (_monitoringStartedAt != null) {
        final elapsedSeconds = DateTime.now()
            .difference(_monitoringStartedAt!)
            .inSeconds;

        if (elapsedSeconds < _initialGracePeriodSeconds) {
          _isFaceDetected = true;
          _consecutiveNoFaceFrames = 0;
          _consecutiveViolationChecks = 0;
          onStatusUpdate?.call('Monitoring active');
          return;
        }
      }

      if (_useOpenCvDetection) {
        print(
          'OpenCV: monitoring check using real detection | faceDetected=$_isFaceDetected offCenter=$_isFaceOffCenter',
        );
      } else {
        print('OpenCV: monitoring check using simulation');
        _simulateFaceDetection();
      }

      final bool isLookingAway = !_isFaceDetected || _isFaceOffCenter;

      if (isLookingAway) {
        _consecutiveViolationChecks++;
        print(
          'OpenCV: violation detected, count=$_consecutiveViolationChecks / $_requiredViolationChecks',
        );
      } else {
        _consecutiveViolationChecks = 0;
      }

      if (_consecutiveViolationChecks >= _requiredViolationChecks &&
          _canIssueWarning()) {
        if (!_isFaceDetected) {
          _addWarning(
            'face_left_frame',
            'Face left camera frame',
            quizSessionId,
          );
        } else {
          _addWarning(
            'looking_away',
            'Face is too far off-center',
            quizSessionId,
          );
        }
        _consecutiveViolationChecks = 0;
      }
    } catch (e) {
      print('OpenCV: monitoring check error = $e');
      onStatusUpdate?.call('Monitoring check error: $e');
    }
  }

  bool _canIssueWarning() {
    if (_lastWarningAt == null) return true;

    final secondsSinceLastWarning = DateTime.now()
        .difference(_lastWarningAt!)
        .inSeconds;

    return secondsSinceLastWarning >= _warningDebounceSeconds;
  }

  void _addWarning(String warningType, String reason, int quizSessionId) async {
    if (!_isMonitoring) return;
    if (_terminationTriggered) return;
    if (!_canIssueWarning()) return;

    _lastWarning = reason;
    _lastWarningAt = DateTime.now();
    _warningCount++;

    print('OpenCV: warning $_warningCount/$_maxWarnings -> $reason');

    try {
      await ApiService.reportMovementViolation(
        warningType,
        reason,
        quizSessionId,
      );
      onWarning?.call('Warning $_warningCount/$_maxWarnings: $reason');
    } catch (e) {
      print('OpenCV: error reporting warning = $e');
      onStatusUpdate?.call('Error reporting warning: $e');
    }

    if (_warningCount >= _maxWarnings) {
      _terminationTriggered = true;
      print('OpenCV: max warnings reached, force quitting');
      onForceQuit?.call();
      stopMonitoring();
    }
  }

  void addTestWarning(String reason, int quizSessionId) {
    _addWarning('test_warning', reason, quizSessionId);
  }

  void resetWarnings() {
    _warningCount = 0;
    _lastWarning = null;
    onStatusUpdate?.call('Warnings reset');
  }

  void dispose() {
    stopMonitoring();
  }
}
