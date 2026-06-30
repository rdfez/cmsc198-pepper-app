import 'package:flutter/material.dart';
import 'package:pepper_app/theme/theme.dart';
import 'package:pepper_app/pages/howto_page.dart';
import 'package:pepper_app/pages/camera_page.dart';

class HomePage extends StatefulWidget {
  // const HomePage({super.key, required this.title});
  const HomePage({super.key, required this.title});

  final String title;
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isAnalyzing = false;

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
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => 
                                  TakePictureScreen(),
                            ),
                          );
                        },
                        style: AppButtonStyles.primary,
                        child: const Text('Use Camera'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
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
                // if (_isAnalyzing) const AnalysisLoadingOverlay(),
            ],
          )
        ),
      ),
    );
  }
}
