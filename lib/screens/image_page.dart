import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:photo/components/image_viewer_page.dart';

class ImagePage extends StatefulWidget {
  final Directory albumDir;

  ImagePage({required this.albumDir});

  @override
  _ImagePageState createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];

  Future<List<File>> _getImages() async {
    return widget.albumDir.listSync().whereType<File>().toList();
  }

  Future<void> _pickAndSaveImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final String newPath =
          path.join(widget.albumDir.path, path.basename(image.path));
      await File(image.path).copy(newPath);
      setState(() {});
    }
  }

  Future<void> _deleteImage(File imageFile) async {
    if (await imageFile.exists()) {
      await imageFile.delete();
      setState(() {});
    }
  }

  Future<void> _deleteSelectedImages() async {
    for (var image in _selectedImages) {
      await _deleteImage(image);
    }
    setState(() {
      _selectedImages.clear();
    });
  }

  void _toggleSelection(File image) {
    setState(() {
      if (_selectedImages.contains(image)) {
        _selectedImages.remove(image);
      } else {
        _selectedImages.add(image);
      }
    });
  }

  Future<void> _confirmDeleteSelectedImages() async {
    if (_selectedImages.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa các ảnh đã chọn'),
          content: Text('Bạn muốn xóa ${_selectedImages.length} ảnh?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteSelectedImages();
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff99CCFF),
      appBar: AppBar(
        title: Text(path.basename(widget.albumDir.path)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_selectedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDeleteSelectedImages,
            ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<List<File>>(
            future: _getImages(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final images = snapshot.data!;
              if (images.isEmpty)
                return const Center(child: Text('No Images Found'));
              return GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final image = images[index];
                  final isSelected = _selectedImages.contains(image);
                  return GestureDetector(
                    onLongPress: () => _toggleSelection(image),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ImageViewerPage(imageFile: image),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                        border: isSelected
                            ? Border.all(color: Colors.blue, width: 2.0)
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Stack(
                          children: [
                            Image.file(
                              image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            if (isSelected)
                              const Positioned(
                                top: 0,
                                right: 0,
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                              ),
                            Positioned(
                              bottom: 8.0,
                              right: 8.0,
                              child: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDeleteImage(image),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: _pickAndSaveImage,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add_a_photo),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteImage(File imageFile) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa ảnh này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteImage(imageFile);
    }
  }
}
