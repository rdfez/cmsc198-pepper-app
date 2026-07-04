import 'package:flutter/material.dart';

// How to Use Page
class HowToPage extends StatelessWidget {
  const HowToPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandOlive = Color(0xFF849363);
    const Color brandDarkGreen = Color(0xFF3B5210);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('How to Use', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: brandDarkGreen,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: brandDarkGreen.withValues(alpha: 0.2), height: 1.0),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 500 : double.infinity),
                child: LayoutBuilder(
                  builder: (context, constraints){
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, 
                                  children: [
                                    const SizedBox(height: 12),

                                    // Home
                                    const Center(
                                      child: Text(
                                        'Image Source Options',
                                        style: TextStyle(
                                          color: brandDarkGreen,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildImageContainer('assets/images/howto_home.png'),
                                    const SizedBox(height:12),
                                    _buildItem('Select the Source', 'Choose whether to capture a photo using your phone camera or select an image from your local files', brandDarkGreen, brandOlive),
                                    Divider(color: brandOlive.withValues(alpha: 0.3), thickness: 1),
                                    const SizedBox(height: 12),

                                    // Take photo section
                                    const Center(
                                      child: Text(
                                        'Take Photo',
                                        style: TextStyle(
                                          color: brandDarkGreen,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildImageContainer('assets/images/howto_capture1.png'),
                                    const SizedBox(height:12),
                                    _buildItem('Setup', 'Layout the pepper fruits properly. If fruit measurements are needed, include a 30cm ruler for size reference.  For best results, ensure adequate lighting and the subjects must be within the frame completely. ', brandDarkGreen, brandOlive),
                                    _buildItem('Capture', 'Once satsfied with the setup, tap the camera shutter button.', brandDarkGreen, brandOlive),
                                    Divider(color: brandOlive.withValues(alpha: 0.3), thickness: 1),
                                    const SizedBox(height: 12),
                                    const Center(
                                      child: Text(
                                        'After Capture',
                                        style: TextStyle(
                                          color: brandDarkGreen,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildImageContainer('assets/images/howto_capture2.png'),
                                    const SizedBox(height:12),
                                    _buildItem('Retake', 'Tap to take another photo if the image is blurry.', brandDarkGreen, brandOlive),
                                    _buildItem('Approve', 'Tap if the image is sharp and all the subjects are clearly visible.', brandDarkGreen, brandOlive),
                                    const SizedBox(height: 12),
                                    Divider(color: brandOlive.withValues(alpha: 0.3), thickness: 1),
                                    const SizedBox(height: 12),
                                    
                                    // Upload section
                                    const Center(
                                      child: Text(
                                        'Gallery Upload',
                                        style: TextStyle(
                                          color: brandDarkGreen,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildImageContainer('assets/images/howto_gallery.png'),
                                    const SizedBox(height:12),
                                    _buildItem('Select from Gallery', 'Choose which image to upload from your local files.', brandDarkGreen, brandOlive),
                                    const SizedBox(height: 12),
                                    Divider(color: brandOlive.withValues(alpha: 0.3), thickness: 1),
                                    const SizedBox(height: 12),
                                  
                                    // Export 
                                    const Center(
                                      child: Text(
                                        'Download Results',
                                        style: TextStyle(
                                          color: brandDarkGreen,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildImageContainer('assets/images/howto_export.png'),
                                    const SizedBox(height:12),
                                    _buildItem('Export CSV', 'Tap to download the analysis results as a CSV file.', brandDarkGreen, brandOlive),
                                  ],
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                )
              ),
            )
          ],
        )
      ),
    );
  }

  // For Instruction widget
  Widget _buildItem(String boldText, String regularText, Color primaryColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$boldText: ',
              style: TextStyle(
                color: primaryColor, 
                fontWeight: FontWeight.bold, 
                fontSize: 14
              ),
            ),
            TextSpan(
              text: regularText, // Rest of the description
              style: TextStyle(
                color: secondaryColor, 
                fontSize: 14, 
                height: 1.4
              ),
            ),
          ],
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
  // For Image widgets
  Widget _buildImageContainer(String assetPath) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 200,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
          ),
        ),
      ),
    );
  }
}