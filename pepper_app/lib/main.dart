import 'package:flutter/material.dart';
import 'package:pepper_app/pages/home_page.dart';
import 'package:pepper_app/theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'PepSee',
      theme: appTheme,
      home: const HomePage(title: 'PepSee'),
    );
  }
}