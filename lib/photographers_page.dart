import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photomate/booking.dart';
import 'package:photomate/portfolio.dart';

Future<User?> signInAdmin() async {
  try {
    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'hey@gmail.com',
      password: '123456',
    );
    return userCredential.user;
  } catch (e) {
    print("Error signing in: $e");
    return null;
  }
}

Future<void> addPhotographer(String name, String bio, String image) async {
  try {
    await FirebaseFirestore.instance.collection('photographers').add({
      'name': name,
      'bio': bio,
      'image': image,
      'rating': 0.0,
    });
  } catch (e) {
    print("Error adding photographer: $e");
  }
}

Future<void> deletePhotographer(String photographerId) async {
  try {
    await FirebaseFirestore.instance
        .collection('photographers')
        .doc(photographerId)
        .delete();
  } catch (e) {
    print("Error deleting photographer: $e");
  }
}

Future<void> updatePhotographer(
    String photographerId, String name, String bio, String image) async {
  try {
    await FirebaseFirestore.instance
        .collection('photographers')
        .doc(photographerId)
        .update({
      'name': name,
      'bio': bio,
      'image': image,
    });
  } catch (e) {
    print("Error updating photographer: $e");
  }
}

class PhotographersPage extends StatelessWidget {
  const PhotographersPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color myBlueGrey = Color(0xFF37474F);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Photographers'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () async {
              // Admin sign-in logic
              User? user = FirebaseAuth.instance.currentUser;
              if (user != null && user.email == 'hey@gmail.com') {
                // Show admin actions if the user is the admin
                showModalBottomSheet(
                  context: context,
                  builder: (context) => AdminActions(),
                );
              } else {
                // Optionally, you can show a Snackbar to notify the user
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin access denied')),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                "https://p4.wallpaperbetter.com/wallpaper/209/644/840/wood-textures-wood-texture-abstract-textures-hd-art-wallpaper-preview.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('photographers')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            var photographers = snapshot.data!.docs;
            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: photographers.length,
              itemBuilder: (context, index) {
                var photographer = photographers[index];

                return Card(
                  color: myBlueGrey.withOpacity(0.8),
                  margin: const EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotographerDetailsPage(
                            photographerName: photographer["name"]!,
                            photographerId: photographer.id,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              photographer["image"]!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            photographer["name"]!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            photographer["bio"]!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class PhotographerDetailsPage extends StatelessWidget {
  final String photographerName;
  final String photographerId;

  const PhotographerDetailsPage({
    super.key,
    required this.photographerName,
    required this.photographerId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(photographerName),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to $photographerName\'s Page',
              style: const TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PortfolioPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text('View Portfolio'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.grey.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  builder: (context) => BookingForm(
                    photographerName: photographerName,
                    onBookingSubmitted: (booking) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking Confirmed!')),
                      );
                    },
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text('Book Now'),
            ),
          ],
        ),
      ),
    );
  }
}

/*class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
      ),
      body: const Center(
        child: Text('Portfolio Content Here'),
      ),
    );
  }
}*/

class AdminActions extends StatelessWidget {
  const AdminActions({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('photographers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var photographers = snapshot.data!.docs;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Add Photographer Button
            ListTile(
              title: const Text('Add Photographer'),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddPhotographerForm(),
                  );
                },
              ),
            ),
            // List Photographers with Edit/Delete options
            ...photographers.map((photographer) {
              return ListTile(
                title: Text(photographer['name']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return EditPhotographerForm(
                                photographer: photographer);
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        deletePhotographer(photographer.id);
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class AddPhotographerForm extends StatelessWidget {
  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final imageController = TextEditingController();

  AddPhotographerForm({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Photographer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Photographer Name'),
          ),
          TextField(
            controller: bioController,
            decoration: const InputDecoration(labelText: 'Bio'),
          ),
          TextField(
            controller: imageController,
            decoration: const InputDecoration(labelText: 'Image URL'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            addPhotographer(
              nameController.text,
              bioController.text,
              imageController.text,
            );
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
}

class EditPhotographerForm extends StatelessWidget {
  final QueryDocumentSnapshot photographer;
  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final imageController = TextEditingController();

  EditPhotographerForm({super.key, required this.photographer});

  @override
  Widget build(BuildContext context) {
    nameController.text = photographer['name'];
    bioController.text = photographer['bio'];
    imageController.text = photographer['image'];

    return AlertDialog(
      title: const Text('Edit Photographer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Photographer Name'),
          ),
          TextField(
            controller: bioController,
            decoration: const InputDecoration(labelText: 'Bio'),
          ),
          TextField(
            controller: imageController,
            decoration: const InputDecoration(labelText: 'Image URL'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            updatePhotographer(
              photographer.id,
              nameController.text,
              bioController.text,
              imageController.text,
            );
            Navigator.pop(context);
          },
          child: const Text('Save Changes'),
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
}
