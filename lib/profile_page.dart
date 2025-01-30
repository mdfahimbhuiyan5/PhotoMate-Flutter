import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photomate/screens/login_screen.dart'; // Import LoginScreen

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _profilePicUrl;
  String? _name;
  String? _email;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Load the user's profile data
  Future<void> _loadProfileData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _name = userDoc['name'] ?? '';
          _email = userDoc['email'] ?? '';
          _phone = userDoc['phone'] ?? '';
          _profilePicUrl =
              userDoc['profilePicUrl'] ?? ''; // Load profile picture URL
        });
      }
    }
  }

  // Handle profile picture change
  Future<void> _changeProfilePicture() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      // Optionally upload the image to Firebase Storage and save the URL in Firestore
      final user = _auth.currentUser;
      if (user != null) {
        // Here, you would upload the image to Firebase Storage and get the URL
        // After uploading, save the URL to Firestore
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profilePicUrl': _imageFile?.path, // Store path or URL after upload
        });
      }
    }
  }

  // Log Out function
  Future<void> _logOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepOrangeAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logOut, // Log Out on press
          ),
        ],
      ),
      body: Container(
        color: Colors.black87, // Dark background
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Profile picture section
                  GestureDetector(
                    onTap: _changeProfilePicture,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_profilePicUrl != null &&
                                        _profilePicUrl!.isNotEmpty
                                    ? NetworkImage(_profilePicUrl!)
                                    : AssetImage('assets/placeholder.png'))
                                as ImageProvider,
                        child: _imageFile == null
                            ? const Icon(
                                Icons.camera_alt,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Name display and update inside a box with border
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _name ?? 'Name not available',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrangeAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      // Show dialog to update name
                      showDialog(
                        context: context,
                        builder: (context) {
                          final nameController =
                              TextEditingController(text: _name);
                          return AlertDialog(
                            title: const Text('Update Name'),
                            content: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                hintText: 'Enter new name',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  if (nameController.text.isNotEmpty) {
                                    setState(() {
                                      _name = nameController.text;
                                    });
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(_auth.currentUser!.uid)
                                        .update({
                                      'name': nameController.text,
                                    });
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text('Save'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text(
                      'Edit Name',
                      style: TextStyle(
                        color: Colors.deepOrangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Phone number inside a bordered box
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Phone: ${_phone ?? 'Phone not available'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Email inside a bordered box
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Email: ${_email ?? 'Email not available'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Log Out Button with border
                  ElevatedButton(
                    onPressed: _logOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 50.0),
                    ),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
