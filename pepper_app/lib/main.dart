import 'package:flutter/material.dart';
import 'package:pepper_app/pages/home_page.dart';
import 'package:pepper_app/theme/theme.dart';
import 'package:camera/camera.dart';

late CameraDescription firstCamera;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

   // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pepper App',
      theme: appTheme,
      home: HomePage(title: 'Peppe App', camera: firstCamera),
    );
  }
}
