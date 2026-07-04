import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// A screen that allows users to take a picture using the phone camera
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key});

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController? _controller;
  XFile? _capturedFile;
  bool _isInitialized = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Initialize camera
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera found on this device.');
        return;
      }

      _controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e, stackTrace) {
      debugPrint('Camera initialization failed: $e');
      debugPrint('$stackTrace');
      if (mounted) {
        setState(() => _cameraError = e.toString());
      }
    }
  }

  // Capture current frame
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final file = await _controller!.takePicture();
      setState(() => _capturedFile = file);
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  // Dispose camera controller and reset orientation
  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, // Revert to portrait mode
    ]);
    _controller?.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
    if (_cameraError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.redAccent, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Camera failed to initialize',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  _cameraError!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _cameraError = null;
                      _isInitialized = false;
                    });
                    _initializeCamera();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview or captured image
          Positioned.fill(
            child: _capturedFile == null
                ? LayoutBuilder(builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          // aspectRatio: 4/3,
                          child: CameraPreview(_controller!),
                        ),
                      ),
                    );
                  })
                : Image.file(
                    File(_capturedFile!.path),
                    fit: BoxFit.contain,
                  ),
          ),

          // Camera controls
          SafeArea(
            maintainBottomViewPadding: false,
            child: Stack(
              children: [
                // Close button 
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      shape: const CircleBorder(),
                    ),
                  ),
                ),

                // Shutter button
                Align(
                  alignment: const Alignment(0.92, 0.0),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: _capturedFile == null
                        ? GestureDetector(
                            onTap: _takePicture,
                            child: Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: Center(
                                child: Container(
                                  height: 60,
                                  width: 60,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => setState(() => _capturedFile = null),
                                icon: const Icon(Icons.refresh),
                                color: Colors.white,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  shape: const CircleBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              IconButton(
                                onPressed: () => Navigator.pop(context, _capturedFile),
                                icon: const Icon(Icons.check),
                                color: Colors.white,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: const CircleBorder(),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
