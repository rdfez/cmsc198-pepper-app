import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pepper_app/theme/theme.dart';
import 'package:pepper_app/pages/howto_page.dart';
import 'package:pepper_app/pages/camera_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pepper_app/utils/dimension_calculator.dart';
import 'package:pepper_app/pages/result_page.dart';
import 'package:pepper_app/utils/loading_overlay.dart';
class HomePage extends StatefulWidget {
  // const HomePage({super.key, required this.title});
  const HomePage({super.key, required this.title});

  final String title;
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isAnalyzing = false;
  String _modelPath = 'assets/fruit_model.onnx';
  // String? _partToAnalyze = 'Fruit';
  // final List<String> _pepperParts = ['Fruit', 'Fruit', 'Flesh'];

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
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Text(
                        'Pepper Characterization App',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 40),
                      // Text(
                      //   'Select a part to analyze',
                      //   style: Theme.of(context).textTheme.bodyMedium,
                      // ),
                      // DropdownMenu<String>(
                      //   initialSelection: _partToAnalyze,
                      //   // label: const Text('Part to Analyze'),
                      //   onSelected: (String? newValue) {
                      //     setState(() {
                      //       _partToAnalyze = newValue;
                            
                      //       if (_partToAnalyze == 'Fruit') {
                      //         _modelPath = 'assets/fruit_model.onnx';
                      //       // } else if (_partToAnalyze == 'Fruit') {
                      //       //   _modelPath = 'assets/best_fruit.onnx';
                      //       // } else if (_partToAnalyze == 'Flesh') {
                      //       //   _modelPath = 'assets/best_flesh.onnx';
                      //       }
                      //     });
                      //   },
                      //   // 3. Map your options to DropdownMenuEntry widgets
                      //   dropdownMenuEntries: _pepperParts.map<DropdownMenuEntry<String>>((String value) {
                      //     return DropdownMenuEntry<String>(
                      //       value: value,
                      //       label: value,
                      //       style: MenuItemButton.styleFrom(
                      //         foregroundColor: appTheme.colorScheme.onPrimary,
                      //       ),
                      //     );
                      //   }).toList(),
                      //   textStyle: TextStyle(color: appTheme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                      //   // Style the dropdown input box
                      //   inputDecorationTheme: InputDecorationTheme(
                      //     filled: true,
                      //     fillColor: appTheme.colorScheme.primary,
                      //     border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //       borderSide: BorderSide.none,
                      //     ),
                      //   ),
                      //   // Style the floating overlay menu panel
                      //   menuStyle: MenuStyle(
                      //     backgroundColor: WidgetStateProperty.all(appTheme.colorScheme.secondary),
                      //     elevation: WidgetStateProperty.all(8),
                      //   ),
                      // ),
                      // const SizedBox(height: 40),
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
                          _handleGalleryUpload();
                        },
                        // _isAnalyzing ? null : _handleGalleryUpload,
                        style: AppButtonStyles.primary,
                        child: const Text('Upload from Gallery'),
                      ),

                      const SizedBox(height: 20),
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
