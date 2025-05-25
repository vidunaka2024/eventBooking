import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:event_scheduler_app/screens/event_create_screen/event_create_widgets/location_picker_screen.dart';
import '../../model/event_model.dart';

class EditEventScreen extends StatefulWidget {
  final Event event;
  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  late TextEditingController _eventNameController;
  late TextEditingController _eventTypeController;
  late TextEditingController _descriptionController; // New controller for Description
  late TextEditingController _dateController;
  late TextEditingController _priceController;
  late TextEditingController _availableCountController;
  late TextEditingController _locationController;

  LatLng? _selectedLocation;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Prepopulate the fields with existing event data.
    _eventNameController = TextEditingController(text: widget.event.eventName);
    _eventTypeController = TextEditingController(text: widget.event.eventType);
    _descriptionController = TextEditingController(text: widget.event.description); // Prepopulate description
    _dateController = TextEditingController(text: widget.event.date);
    _priceController = TextEditingController(text: widget.event.price.toString());
    _availableCountController = TextEditingController(text: widget.event.availableCount.toString());
    _locationController = TextEditingController(text: widget.event.location);
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventTypeController.dispose();
    _descriptionController.dispose(); // Dispose description controller
    _dateController.dispose();
    _priceController.dispose();
    _availableCountController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Pick a new image (if desired).
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

  // Upload image to GCP public bucket and return its URL.
  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final objectName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final url = "https://storage.googleapis.com/eventchehan/photos/$objectName";
      final bytes = await imageFile.readAsBytes();

      final response = await http.put(
        Uri.parse(url),
        body: bytes,
        headers: {'Content-Type': 'application/octet-stream'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return url;
      } else {
        print("Image upload failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Exception during image upload: $e");
      return null;
    }
  }

  // Select a location via the LocationPickerScreen.
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

  // Pick date and time.
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

  // Update event by sending a PUT request.
  Future<void> _updateEvent() async {
    try {
      final int price = int.tryParse(_priceController.text) ?? 0;
      final int availableCount = int.tryParse(_availableCountController.text) ?? 0;
      final String dateString = _dateController.text;
      final String locationString = _locationController.text;

      // If a new image is selected, upload it; otherwise, use the existing URL.
      String? imageUrl = widget.event.imageUrl;
      if (_selectedImage != null) {
        final uploadedUrl = await _uploadImage(_selectedImage!);
        if (uploadedUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Image upload failed")),
          );
          return;
        }
        imageUrl = uploadedUrl;
      }

      // Build updated event data.
      Map<String, dynamic> eventData = {
        "eventName": _eventNameController.text,
        "eventType": _eventTypeController.text,
        "description": _descriptionController.text, // Add description field.
        "date": dateString,
        "price": price,
        "availableCount": availableCount,
        "location": locationString,
        "imageUrl": imageUrl ?? "",
      };

      // Get the organizer ID (if needed for verification).
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not authenticated")),
        );
        return;
      }
      final organizerId = currentUser.uid;
      // (Organizer ID can be sent with the event data if your backend expects it.)

      // Send the PUT request to update the event.
      final apiUrl = "http://localhost:8080/api/events/${widget.event.id}";
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(eventData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Event updated successfully!")),
        );
        Navigator.pop(context, true); // Optionally return to detail view.
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating event: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating event: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1B24),
        title: const Text("Edit Event", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Name
            TextField(
              controller: _eventNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Event Name",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Event Type
            TextField(
              controller: _eventTypeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Event Type",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Description
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Description",
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: "Enter a brief description of the event",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Date/Time Picker
            TextField(
              controller: _dateController,
              readOnly: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Date",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  onPressed: _pickDateTime,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Price
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Price",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Available Count
            TextField(
              controller: _availableCountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Available Count",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Location with Icon Button
            TextField(
              controller: _locationController,
              readOnly: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Location",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.location_on, color: Colors.white),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                _selectedImageBytes != null
                    ? Image.memory(
                        _selectedImageBytes!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    : widget.event.imageUrl.isNotEmpty
                        ? Image.network(
                            widget.event.imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : const Text(
                            "No image selected",
                            style: TextStyle(color: Colors.white),
                          ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _updateEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
