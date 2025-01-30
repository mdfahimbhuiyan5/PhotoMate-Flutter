import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String name;
  final String phoneNumber;
  final DateTime dateTime;
  final String location;
  final String photographerName; // Add photographer's name to the booking

  const Booking({
    required this.name,
    required this.phoneNumber,
    required this.dateTime,
    required this.location,
    required this.photographerName, // Add photographer's name
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'photographerName': photographerName, // Add photographer's name to map
    };
  }

  static Future<bool> isConflict(DateTime dateTime) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('dateTime', isEqualTo: dateTime.toIso8601String())
        .get();
    return snapshot.docs.isNotEmpty;
  }
}

class BookingForm extends StatefulWidget {
  final Function(Booking) onBookingSubmitted;
  final String photographerName; // Add photographer's name here

  const BookingForm({
    super.key,
    required this.onBookingSubmitted,
    required this.photographerName, // Pass photographer's name
  });

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  DateTime _dateTime = DateTime.now();
  String _location = "";
  String? _errorMessage;

  Future<void> saveBookingToFirebase(Booking booking) async {
    final conflict = await Booking.isConflict(booking.dateTime);
    if (conflict) {
      setState(() {
        _errorMessage =
            "This time slot is already booked. Please choose another one.";
      });
      return;
    }

    try {
      final bookingRef = FirebaseFirestore.instance.collection('bookings');

      // Debug log to confirm data being sent
      print("Saving booking: ${booking.toMap()}");

      // Save booking to Firestore
      await bookingRef.add(booking.toMap());

      setState(() {
        _errorMessage = null;
      });

      // Call the function to notify the parent widget about the booking
      widget.onBookingSubmitted(booking);
    } catch (e) {
      print("Error saving booking: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://i0.wp.com/harshvardhanart.com/wp-content/uploads/2020/04/classic-painting-bg.jpg?w=1084&ssl=1',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Confirm Your Booking",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "Phone Number"),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Date & Time: "),
                    TextButton(
                      onPressed: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _dateTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          final TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_dateTime),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              _dateTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Text(
                        "${_dateTime.toLocal().toIso8601String().split('T')[0]} ${_dateTime.toLocal().toIso8601String().split('T')[1].split('.')[0]}",
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _location = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: "Location"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty &&
                        _phoneNumberController.text.isNotEmpty &&
                        _location.isNotEmpty) {
                      final booking = Booking(
                        name: _nameController.text,
                        phoneNumber: _phoneNumberController.text,
                        dateTime: _dateTime,
                        location: _location,
                        photographerName:
                            widget.photographerName, // Pass photographer's name
                      );

                      saveBookingToFirebase(booking);
                      _nameController.clear();
                      _phoneNumberController.clear();
                      _location = "";
                    }
                  },
                  child: const Text("Book Now"),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
