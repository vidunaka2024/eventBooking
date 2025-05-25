import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({Key? key}) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _userLocation; // user’s current location
  LatLng? _selectedLocation; // user-tapped location

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Get user’s current location
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (!(permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always)) return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
      _markers.clear();

      // Add a green marker for the user location
      _markers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: "Your Location"),
        ),
      );
    });

    // Move camera to user's location
    if (_mapController != null && _userLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_userLocation!),
      );
    }
  }

  // Called when user taps on map
  void _onMapTapped(LatLng tappedPoint) {
    setState(() {
      _selectedLocation = tappedPoint;
      // Remove any old "selectedLocation" marker
      _markers.removeWhere(
        (marker) => marker.markerId.value == "selectedLocation",
      );

      // Add a red marker for the tapped location
      _markers.add(
        Marker(
          markerId: const MarkerId("selectedLocation"),
          position: tappedPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: "Selected Location"),
        ),
      );
    });
  }

  // Confirm and pop back to HomeScreen
  void _confirmLocation() {
    if (_selectedLocation == null) {
      // No location chosen, show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please tap on the map to pick a location."),
        ),
      );
      return;
    }
    // Return the selected LatLng
    Navigator.pop(context, _selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    // Default to some location (e.g., Colombo) if user location not determined
    final LatLng defaultPosition = const LatLng(6.9271, 79.8612);

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.orange,
        colorScheme: const ColorScheme.dark(
          primary: Colors.orange,
          onPrimary: Colors.white,
          surface: Color(0xFF1F1B24),
          onSurface: Colors.white,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.grey,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1B24),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Pick a Location"),
        ),
        body: Stack(
          children: [
            // Google Map
            GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _userLocation ?? defaultPosition,
                zoom: 14,
              ),
              markers: _markers,
              onTap: _onMapTapped,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
            // "Confirm Location" button at the bottom
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: _confirmLocation,
                icon: const Icon(Icons.check),
                label: const Text("Confirm Location"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF6c5ce7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
