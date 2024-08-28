import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:photo/main.dart';
import 'package:photo/screens/image_page.dart';

class AlbumPage extends StatefulWidget {
  @override
  _AlbumPageState createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  Directory? appDocDir;
  Future<void> _signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeDirectory();
  }

  Future<void> _initializeDirectory() async {
    appDocDir = await getApplicationDocumentsDirectory();
    setState(() {});
  }

  Future<List<Directory>> _getAlbums() async {
    if (appDocDir == null) return [];
    return appDocDir!
        .listSync()
        .whereType<Directory>()
        .where((dir) => path.basename(dir.path) != 'flutter_assets')
        .toList();
  }

  Future<void> _createAlbum(String albumName) async {
    final albumDir = Directory(path.join(appDocDir!.path, albumName));
    if (!await albumDir.exists()) {
      await albumDir.create();
      setState(() {});
    }
  }

  Future<void> _deleteAlbum(Directory albumDir) async {
    if (await albumDir.exists()) {
      await albumDir.delete(recursive: true);
      setState(() {});
    }
  }

  Future<void> _renameAlbum(Directory albumDir, String newName) async {
    final newAlbumDir = Directory(path.join(albumDir.parent.path, newName));
    if (await albumDir.exists() && !await newAlbumDir.exists()) {
      await albumDir.rename(newAlbumDir.path);
      setState(() {});
    }
  }

  Future<void> _confirmDeleteAlbum(Directory albumDir) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa album'),
          content: const Text('Bạn có chắc là muốn xóa album này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Trở về'),
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
      await _deleteAlbum(albumDir);
    }
  }

  Color _getColorFromList(int index) {
    return Colors.grey;
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff99CCFF),
      appBar: AppBar(
        title: const Text('Photo Albums'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _signOut(),
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Directory>>(
            future: _getAlbums(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final albums = snapshot.data!;
              if (albums.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 100,
                      ),
                      Image.asset("assets/image-removebg-preview.png"),
                      const SizedBox(
                        height: 60,
                      ),
                      const Text('No Albums Found'),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 11.0,
                  mainAxisSpacing: 11.0,
                  childAspectRatio: 1.1,
                ),
                itemCount: albums.length,
                itemBuilder: (context, index) {
                  final album = albums[index];
                  final Color color = _getColorFromList(index);
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImagePage(albumDir: album),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: GridTile(
                        header: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            path.basename(album.path),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        footer: GridTileBar(
                          trailing: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.black),
                                onPressed: () async {
                                  String? newName = await _showAlbumNameDialog(
                                    context,
                                    initialName: path.basename(album.path),
                                  );
                                  if (newName != null && newName.isNotEmpty) {
                                    await _renameAlbum(album, newName);
                                  }
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDeleteAlbum(album),
                              ),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.folder,
                            size: 60,
                            color: Colors.blue[600],
                          ),
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
              onPressed: () async {
                String? albumName = await _showAlbumNameDialog(context);
                if (albumName != null && albumName.isNotEmpty) {
                  await _createAlbum(albumName);
                }
              },
              child: const Icon(Icons.add),
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showAlbumNameDialog(BuildContext context,
      {String initialName = ''}) async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        String albumName = initialName;
        return AlertDialog(
          title: const Text('Tên Album'),
          content: TextField(
            onChanged: (value) {
              albumName = value;
            },
            controller: TextEditingController(text: initialName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Trở về'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, albumName),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
