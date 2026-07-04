import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pepper_app/theme/theme.dart';
import 'package:pepper_app/pages/howto_page.dart';
import 'package:pepper_app/pages/camera_page.dart';
import 'package:pepper_app/utils/analyzer.dart';
import 'package:pepper_app/pages/result_page.dart';
import 'package:pepper_app/utils/loading_overlay.dart';

// Home page of the app, where users can choose to take a picture or upload from gallery
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isAnalyzing = false;
  final String _modelPath = 'assets/models/fruit_model.onnx';

   @override
  void initState() {
    super.initState();
  }

  // Upload from gallery
  Future<void> _handleGalleryUpload() async {
    var status = await Permission.photos.request();
    if (status.isGranted) {
      final selectedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (selectedFile == null) return;
      await _analyzeFile(File(selectedFile.path));
    } else {
      print("Gallery permission denied");
    }
  }
  
  // Use camera
  Future<void> _handleUseCamera() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {  
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => 
              TakePictureScreen(),
        ),
      ).then((result) {
        if (result != null && result is XFile) {
          _analyzeFile(File(result.path));
        }
      });
    } else {
      print("Camera permission denied");
    }
  }

  // Analyze image file from gallery or camera
  Future<void> _analyzeFile(File imageFile) async {
    setState(() => _isAnalyzing = true);
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      final analyzer = PepperAnalyzer();
      final byteData = await rootBundle.load(_modelPath);
      await analyzer.loadModel(byteData.buffer.asUint8List());
      print('Starting analysis...');
      final results = await analyzer.analyze(imageFile);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnalysisResultsPage(
              imageFile: imageFile,
              result: results,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error processing image: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and title
                    Image.asset(
                      'assets/images/logo.png',
                      width: 200,                
                      height: 200,               
                      fit: BoxFit.cover,         
                    ),
                    Text(
                      'Welcome to PepSee',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 40),
                    // Buttons for camera and gallery
                    ElevatedButton(
                      onPressed: () {
                        _handleUseCamera();
                      },
                      style: AppButtonStyles.primary,
                      child: const Text('Use Camera'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        _isAnalyzing ? null : _handleGalleryUpload();
                      },
                      style: AppButtonStyles.primary,
                      child: const Text('Upload from Gallery'),
                    ),
                    const SizedBox(height: 20),
                    // Button for instructions
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HowToPage(),
                          ),
                        );
                      },
                      child: const Text('View Instructions'),
                    ),
                  ],
                ),
              ),

              // SHOW LOADING OVERLAY
              if (_isAnalyzing) const AnalysisLoadingOverlay(),
            ],
          )
        ),
      ),
    );
  }
}
