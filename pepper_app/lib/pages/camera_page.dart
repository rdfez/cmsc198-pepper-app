import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key});

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController? _controller;
  XFile? _capturedFile;
  bool _isInitialized = false;
  bool _isGuideVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initializeCamera() async {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      
      if (mounted) {
        setState(() => _isInitialized = true);
      }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, // Revert to portrait mode
    ]);
    _controller?.dispose();
    super.dispose();
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

@override
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   Widget build(BuildContext context) {
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
          // Camera preview or captured image display
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
          // Guidelines (either top-view or side-view)
          // if (_capturedFile == null && _isGuideVisible)
          //   Positioned.fill(
          //     child: CustomPaint(
          //       painter: CameraGuidePainter(
          //         isVisible: true,
          //       ),
          //     ),
          //   ),
          
          // Control panel 
          Positioned(
            top: 20,
            bottom: 20,
            right: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                ),
                
                // Capture, guidelines
                Column(
                  children: [
                    // For camera preview 
                    if (_capturedFile == null) ...[
                      // CIRCULAR SHUTTER BUTTON
                      GestureDetector(
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
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                // Dims the button if in live mode
                                color:  Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                    ] else ...[
                      // For capured image 
                      // Retake
                      IconButton(
                        onPressed: () => setState(() => _capturedFile = null),
                        icon: const Icon(Icons.refresh),
                        color: Colors.white, 
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: const CircleBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Approve
                      IconButton(
                        onPressed: () => Navigator.pop(context, _capturedFile),
                        icon: const Icon(Icons.check),
                        color: Colors.white, 
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: const CircleBorder(),
                        ),

                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
