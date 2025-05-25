import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:event_scheduler_app/screens/event_create_screen/event_create_widgets/location_picker_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  // --------------------------------------------------
  // Controllers for the Form
  // --------------------------------------------------
  final _eventNameController = TextEditingController();
  final _eventTypeController = TextEditingController();
  final _descriptionController = TextEditingController(); // Controller for Description
  final _dateController = TextEditingController(); // For date/time
  final _priceController = TextEditingController();
  final _availableCountController = TextEditingController();
  final _locationController = TextEditingController(); // To display lat/lng
  final _venueController = TextEditingController(); // Field for Venue

  LatLng? _selectedLocation; // Location from the map picker

  // Image selection variables (works for both mobile & web)
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes; // Holds image bytes for preview
  final ImagePicker _picker = ImagePicker();

  // --------------------------------------------------
  // Pick an image from the gallery
  // --------------------------------------------------
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = pickedFile;
        _selectedImageBytes = bytes;
      });
    }
  }

  // --------------------------------------------------
  // Upload image to GCP public bucket and return its URL
  // --------------------------------------------------
  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      // Generate a unique name for the image using the current timestamp.
      final objectName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      // Construct the URL for the image upload.
      final url = "https://storage.googleapis.com/eventchehan/photos/$objectName";
      final bytes = await imageFile.readAsBytes();

      // Perform the HTTP PUT request.
      final response = await http.put(
        Uri.parse(url),
        body: bytes,
        headers: {
          'Content-Type': 'application/octet-stream',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return url; // Return the public URL of the uploaded image.
      } else {
        print("Image upload failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Exception during image upload: $e");
      return null;
    }
  }

  // --------------------------------------------------
  // Create Event via the local backend API
  // --------------------------------------------------
  Future<void> _createEvent() async {
    try {
      final int price = int.tryParse(_priceController.text) ?? 0;
      final int availableCount = int.tryParse(_availableCountController.text) ?? 0;
      final String dateString = _dateController.text;
      final String locationString = _locationController.text;
      final String venueString = _venueController.text;
      final String descriptionString = _descriptionController.text;

      // Upload image (if one was selected) and retrieve its URL.
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Image upload failed")),
          );
          return;
        }
      }

      // Prepare the event data to send to your backend.
      Map<String, dynamic> eventData = {
        "eventName": _eventNameController.text,
        "eventType": _eventTypeController.text,
        "description": descriptionString,
        "date": dateString,
        "price": price,
        "availableCount": availableCount,
        "location": locationString,
        "imageUrl": imageUrl ?? "",
        "venue": venueString,
      };

      // Get the organizer's ID from Firebase Authentication.
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not authenticated")),
        );
        return;
      }
      final organizerId = currentUser.uid;

      // Define the API endpoint.
      final apiUrl = "http://localhost:8080/api/events/$organizerId";

      // Post the event data to the backend.
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(eventData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Event created successfully!")),
        );
        // Clear all fields and reset selections.
        _eventNameController.clear();
        _eventTypeController.clear();
        _descriptionController.clear();
        _dateController.clear();
        _priceController.clear();
        _availableCountController.clear();
        _locationController.clear();
        _venueController.clear();
        setState(() {
          _selectedLocation = null;
          _selectedImage = null;
          _selectedImageBytes = null;
        });
        // Navigate to the home screen and remove previous routes to refresh it.
        Navigator.pushNamedAndRemoveUntil(context, '/event', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating event: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating event: $e")),
      );
    }
  }

  // --------------------------------------------------
  // Launch the location picker screen
  // --------------------------------------------------
  Future<void> _selectLocation() async {
    final LatLng? pickedLocation = await Navigator.push<LatLng?>(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _selectedLocation = pickedLocation;
        _locationController.text =
            "[${pickedLocation.latitude.toStringAsFixed(4)}, ${pickedLocation.longitude.toStringAsFixed(4)}]";
      });
    }
  }

  // --------------------------------------------------
  // Pick Date & Time
  // --------------------------------------------------
  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    final combinedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final formatted =
        DateFormat("MMMM d, y 'at' h:mm a").format(combinedDateTime);
    setState(() {
      _dateController.text = formatted;
    });
  }

  // --------------------------------------------------
  // Sign Out
  // --------------------------------------------------
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error signing out: $e")),
      );
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventTypeController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _priceController.dispose();
    _availableCountController.dispose();
    _locationController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.orange,
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.white,
          surface: const Color(0xFF1F1B24),
          onSurface: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7A00E6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white12,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white54),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.grey,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushNamed(context, '/event');
            },
          ),
          title: const Text("Schedule an Event"),
          backgroundColor: const Color(0xFF1F1B24),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              onPressed: _signOut,
              tooltip: 'Sign Out',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Event Name
              TextField(
                controller: _eventNameController,
                decoration: const InputDecoration(
                  labelText: "Event Name",
                ),
              ),
              const SizedBox(height: 16),
              // Event Type
              TextField(
                controller: _eventTypeController,
                decoration: const InputDecoration(
                  labelText: "Event Type",
                ),
              ),
              const SizedBox(height: 16),
              // Description
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  hintText: "Enter a brief description of the event",
                ),
              ),
              const SizedBox(height: 16),
              // Date/Time Picker
              TextField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Date",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: _pickDateTime,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Price
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Price",
                ),
              ),
              const SizedBox(height: 16),
              // Available Count
              TextField(
                controller: _availableCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Available Count",
                ),
              ),
              const SizedBox(height: 16),
              // Venue
              TextField(
                controller: _venueController,
                decoration: const InputDecoration(
                  labelText: "Venue",
                ),
              ),
              const SizedBox(height: 16),
              // Selected Location with Icon Button
              TextField(
                controller: _locationController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Selected Location",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.location_on_outlined),
                    onPressed: _selectLocation,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Image Picker and Preview
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Select Image"),
                  ),
                  const SizedBox(width: 16),
                  _selectedImageBytes != null
                      ? Image.memory(
                          _selectedImageBytes!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : const Text("No image selected"),
                ],
              ),
              const SizedBox(height: 24),
              // Create Event Button
              ElevatedButton(
                onPressed: _createEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A00E6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  "Create Event",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
