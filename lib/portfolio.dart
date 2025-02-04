import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({Key? key}) : super(key: key);

  @override
  _PortfolioPageState createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  /// Adds a new portfolio image to Firestore.
  Future<void> addPortfolioImage(String imageUrl, String description) async {
    try {
      await FirebaseFirestore.instance.collection('portfolio').add({
        'imageUrl': imageUrl,
        'description': description,
        'uploadedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint("Error adding portfolio image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload image.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the current user is admin.
    final currentUser = FirebaseAuth.instance.currentUser;
    bool isAdmin = currentUser != null && currentUser.email == 'hey@gmail.com';

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Portfolio'),
        centerTitle: true,
        backgroundColor: Colors.black87,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('portfolio')
            .orderBy('uploadedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var images = snapshot.data!.docs;
          if (images.isEmpty) {
            return const Center(
              child: Text(
                'No images uploaded yet.',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              itemCount: images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                var imageDoc = images[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  elevation: 6,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: imageDoc['imageUrl'],
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, error, stackTrace) {
                          return const Center(
                              child: Icon(Icons.broken_image,
                                  size: 40, color: Colors.white54));
                        },
                      ),
                      if (imageDoc['description'] != null &&
                          imageDoc['description'].toString().isNotEmpty)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            child: Text(
                              imageDoc['description'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      // Only show the FAB if the current user is the admin.
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: Colors.blueAccent,
              elevation: 6,
              child: const Icon(Icons.add, size: 30),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.grey[850],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: const Text(
                      "Add Portfolio Image",
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: imageUrlController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Image URL",
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Colors.white38),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Colors.blueAccent),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descriptionController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Description (optional)",
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Colors.white38),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Colors.blueAccent),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          // Ensure the image URL is not empty.
                          if (imageUrlController.text.trim().isNotEmpty) {
                            addPortfolioImage(
                              imageUrlController.text.trim(),
                              descriptionController.text.trim(),
                            );
                            imageUrlController.clear();
                            descriptionController.clear();
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Please enter an image URL.")),
                            );
                          }
                        },
                        child: const Text(
                          "Upload",
                          style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          : null,
    );
  }
}
