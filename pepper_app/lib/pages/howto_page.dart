import 'package:flutter/material.dart';

class HowToPage extends StatelessWidget {
   const HowToPage({super.key});

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text('How To Use Pepper'),
       ),
       body: const Center(
         child: Text('Instructions on how to use Pepper will go here.'),
       ),
     );
   }
 }