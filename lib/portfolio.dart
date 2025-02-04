import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PortfolioPage extends StatelessWidget {
  final String photographerName;

  const PortfolioPage({super.key, required this.photographerName});

  @override
  Widget build(BuildContext context) {
    const Color myBlueGrey = Color(0xFF37474F);

    return Scaffold(
      appBar: AppBar(
        title: Text('$photographerName\'s Portfolio'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('photographers')
            .doc(photographerName)
            .collection('portfolio')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var images = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: images.length,
            itemBuilder: (context, index) {
              var image = images[index];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full image display with a thin border
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: () {
                        // Open the image in a new full-screen view
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullImageView(imageUrl: image['url']),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.network(
                          image['url'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 300, // Fixed height for large, full-width images
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description below the image
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      image['description'] ?? 'No description available',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 24), // Space between images
                ],
              );
            },
          );
        },
      ),
      // Admin Add Image Button
      floatingActionButton: FirebaseAuth.instance.currentUser?.email == 'hey@gmail.com'
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddImageForm(photographerName: photographerName),
                );
              },
              backgroundColor: Colors.blueGrey,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class FullImageView extends StatelessWidget {
  final String imageUrl;

  const FullImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Image View'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}

class AddImageForm extends StatelessWidget {
  final String photographerName;
  final imageController = TextEditingController();
  final descriptionController = TextEditingController();

  AddImageForm({super.key, required this.photographerName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Image'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: imageController,
            decoration: const InputDecoration(labelText: 'Image URL'),
          ),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            addImage(imageController.text, descriptionController.text);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> addImage(String imageUrl, String description) async {
    try {
      await FirebaseFirestore.instance
          .collection('photographers')
          .doc(photographerName)
          .collection('portfolio')
          .add({
        'url': imageUrl,
        'description': description,
      });
    } catch (e) {
      print("Error adding image: $e");
    }
  }
}
