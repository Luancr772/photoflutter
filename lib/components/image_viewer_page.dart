import 'dart:io';
import 'package:flutter/material.dart';

class ImageViewerPage extends StatelessWidget {
  final File imageFile;

  ImageViewerPage({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: Image.file(imageFile),
      ),
    );
  }
}
