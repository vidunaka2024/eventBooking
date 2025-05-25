import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:googlemaps_flutter_webservices/geocoding.dart';

import 'modern_drawer.dart';
import 'event_buy_screen.dart';
import 'event_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Event categories (now includes "Recommended").
  final List<String> _categories = [
    "All",
    "Recommended",
    "Music",
    "Sports",
    "Movies",
    "Theatre"
  ];
  String _selectedCategory = "All";

  // Controllers for the search fields (city and event name).
  final TextEditingController _citySearchController = TextEditingController();
  final TextEditingController _eventSearchController = TextEditingController();

  // Variables for the map and markers.
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _filterLocation; // Location used for distance filtering and map display.

  // Lists to store events fetched from the backend.
  List<Event> _allEvents = [];
  List<Event> _recommendedEvents = [];

  // Current query typed for searching by event name.
  String _eventSearchQuery = "";

  // Whether to apply the 10 km distance filter; controlled via ModernDrawer.
  bool _searchWithinRadius = true;

  // Replace with your actual Google Maps Geocoding API key.
  final GoogleMapsGeocoding _geocoding =
      GoogleMapsGeocoding(apiKey: "AIzaSyDQttE3cSnfZPt_K2UB9HYg1UWhdncQuPs");

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _fetchRecommendedEvents();
    _determinePosition();
  }

  /// Fetches all events from the backend API.
  Future<void> _fetchEvents() async {
    const apiUrl = "http://10.0.2.2:8080/api/events";
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      List<dynamic> data;
      if (jsonResponse is List) {
        data = jsonResponse;
      } else if (jsonResponse is Map) {
        // If the response is a map with an 'events' field, use that list.
        if (jsonResponse.containsKey('events')) {
          data = jsonResponse['events'];
        } else {
          // Otherwise, treat the entire map as a single event object.
          data = [jsonResponse];
        }
      } else {
        throw Exception("Unexpected JSON format");
      }
      setState(() {
        _allEvents = data.map((e) => Event.fromJson(e)).toList();
      });
      _updateEventMarkers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load events")),
      );
    }
  }

  /// Fetches recommended events for the current user from the backend API.
  Future<void> _fetchRecommendedEvents() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "YourUserId";
    final apiUrl = "http://10.0.2.2:8080/api/events/recommendation/$userId";
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      List<dynamic> data;
      if (jsonResponse is List) {
        data = jsonResponse;
      } else if (jsonResponse is Map) {
        // If the response is a map with an 'events' field, use that list.
        if (jsonResponse.containsKey('events')) {
          data = jsonResponse['events'];
        } else {
          // Otherwise, treat the entire map as a single event object.
          data = [jsonResponse];
        }
      } else {
        throw Exception("Unexpected JSON format");
      }
      setState(() {
        _recommendedEvents = data.map((e) => Event.fromJson(e)).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load recommended events")),
      );
    }
  }

  /// Retrieves the device's current location.
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (!(permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always)) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _filterLocation = LatLng(position.latitude, position.longitude);
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: _filterLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: "Your Location"),
        ),
      );
      _updateEventMarkers();
    });

    if (_mapController != null && _filterLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_filterLocation!),
      );
    }
  }

  /// Uses Google Maps Geocoding API to search for a city, re-center the map, and optionally filter by distance.
  Future<void> _searchCity(String cityName) async {
    try {
      final response = await _geocoding.searchByAddress(cityName);
      if (response.results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("City not found: $cityName")),
        );
        return;
      }
      final result = response.results.first;
      LatLng newLocation = LatLng(
        result.geometry.location.lat,
        result.geometry.location.lng,
      );
      setState(() {
        // This is the new filter location from city search.
        _filterLocation = newLocation;
        _markers.clear();
        // Mark the searched city right away.
        _markers.add(
          Marker(
            markerId: const MarkerId("searchedLocation"),
            position: newLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: cityName,
              snippet: "Tap for city details",
            ),
          ),
        );
        _updateEventMarkers();
      });
      // Re-center the camera on the searched location.
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(newLocation),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// Updates markers for events that match:
  /// - If "Recommended" is selected, use _recommendedEvents
  /// - Otherwise, filter _allEvents by category
  /// - Also filters by the search query (event name)
  /// - If _searchWithinRadius is true, only show events within 10 km
  void _updateEventMarkers() {
    if (_filterLocation == null) return;

    // Remove existing event markers (IDs starting with "event_").
    _markers.removeWhere((marker) => marker.markerId.value.startsWith("event_"));

    // Decide which base list of events to consider.
    List<Event> baseList;
    if (_selectedCategory == "Recommended") {
      baseList = _recommendedEvents;
    } else if (_selectedCategory == "All") {
      baseList = _allEvents;
    } else {
      baseList = _allEvents.where((event) =>
          event.eventType.toLowerCase() ==
          _selectedCategory.toLowerCase()).toList();
    }

    // Filter further by event name.
    final List<Event> events = baseList.where((event) {
      final bool nameMatch = _eventSearchQuery.isEmpty ||
          event.eventName.toLowerCase().contains(_eventSearchQuery);
      return nameMatch;
    }).toList();

    // Now add markers, applying the distance filter only if _searchWithinRadius is true.
    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      // Assume event.location is stored as "[lat, lng]".
      List<String> parts = event.location
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',');
      double eventLat = double.tryParse(parts[0].trim()) ?? 0;
      double eventLng = double.tryParse(parts[1].trim()) ?? 0;

      if (_searchWithinRadius) {
        // Only show markers within 10 km
        double distance = Geolocator.distanceBetween(
          _filterLocation!.latitude,
          _filterLocation!.longitude,
          eventLat,
          eventLng,
        );
        if (distance <= 10000) {
          _markers.add(
            Marker(
              markerId: MarkerId("event_$i"),
              position: LatLng(eventLat, eventLng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              infoWindow: InfoWindow(
                title: event.eventName,
                snippet: event.date,
              ),
            ),
          );
        }
      } else {
        // No distance filter; show all events that match name/category
        _markers.add(
          Marker(
            markerId: MarkerId("event_$i"),
            position: LatLng(eventLat, eventLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(
              title: event.eventName,
              snippet: event.date,
            ),
          ),
        );
      }
    }
    setState(() {});
  }

  /// Refreshes all events from the backend (pull-to-refresh).
  Future<void> _refreshEvents() async {
    await _fetchEvents();
    // Also refresh recommended events if you'd like to keep them updated:
    await _fetchRecommendedEvents();
  }

  /// Callback for when the user toggles the 10 km filter in ModernDrawer.
  void _onRadiusFilterChanged(bool isActive) {
    setState(() {
      _searchWithinRadius = isActive;
    });
    // Rebuild markers based on the new distance-filter setting.
    _updateEventMarkers();
  }

  @override
  Widget build(BuildContext context) {
    // Default fallback position if _filterLocation is null.
    LatLng defaultPosition = const LatLng(6.9271, 79.8612);

    // Decide which list to start with, based on the selected category.
    List<Event> baseList;
    if (_selectedCategory == "Recommended") {
      baseList = _recommendedEvents;
    } else if (_selectedCategory == "All") {
      baseList = _allEvents;
    } else {
      baseList = _allEvents.where((event) =>
          event.eventType.toLowerCase() ==
          _selectedCategory.toLowerCase()).toList();
    }

    // Then filter by event name and by distance (if enabled).
    List<Event> filteredEvents = baseList.where((event) {
      // Event name match
      final bool nameMatch = _eventSearchQuery.isEmpty ||
          event.eventName.toLowerCase().contains(_eventSearchQuery);
      if (!nameMatch) return false;

      // If there's no device/filter location or the radius filter is off, skip distance check
      if (_filterLocation == null || !_searchWithinRadius) {
        return true;
      }

      // Distance check (within 10 km)
      List<String> parts = event.location
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',');
      double eventLat = double.tryParse(parts[0].trim()) ?? 0;
      double eventLng = double.tryParse(parts[1].trim()) ?? 0;
      double distance = Geolocator.distanceBetween(
        _filterLocation!.latitude,
        _filterLocation!.longitude,
        eventLat,
        eventLng,
      );
      return distance <= 10000;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF161616),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Discover events near you,",
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
            Text(
              "Welcome to Event Organizer",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: const [
          // Example profile picture
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/images/image.png'),
              radius: 20,
            ),
          ),
        ],
      ),
      // Provide data to ModernDrawer, including the radius setting and callback.
      drawer: ModernDrawer(
        userName: FirebaseAuth.instance.currentUser?.displayName ?? "John Doe",
        userEmail: FirebaseAuth.instance.currentUser?.email ?? "john.doe@test.com",
        profileImageUrl: FirebaseAuth.instance.currentUser?.photoURL,
        onLogout: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        },
        userId: FirebaseAuth.instance.currentUser?.uid ?? "YourUserId",
        isRadiusFilterActive: _searchWithinRadius,
        onRadiusFilterChanged: _onRadiusFilterChanged,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Map container
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _filterLocation ?? defaultPosition,
                        zoom: 14,
                      ),
                      markers: _markers,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      onTap: (LatLng tappedPoint) {
                        // Let the user pick a custom location on the map.
                        setState(() {
                          _filterLocation = tappedPoint;
                          _markers.clear();
                          _markers.add(
                            Marker(
                              markerId: const MarkerId("tappedLocation"),
                              position: tappedPoint,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed,
                              ),
                              infoWindow:
                                  const InfoWindow(title: "Selected Location"),
                            ),
                          );
                          _updateEventMarkers();
                        });
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // City Search Field
                TextField(
                  controller: _citySearchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search by city (e.g., Colombo)...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (value) {
                    // If user typed a city, search & center on it.
                    // If empty, revert to device location.
                    if (value.isNotEmpty) {
                      _searchCity(value.trim());
                    } else {
                      _determinePosition();
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Event Name Search Field
                TextField(
                  controller: _eventSearchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search by event name...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.event, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    // Filter as the user types.
                    setState(() {
                      _eventSearchQuery = value.trim().toLowerCase();
                      _updateEventMarkers();
                    });
                  },
                ),
                const SizedBox(height: 20),
                // Categories header
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Event categories",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Categories row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 15.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                              _markers.clear();
                              // Re-add the current (or tapped) location marker if available
                              if (_filterLocation != null) {
                                _markers.add(
                                  Marker(
                                    markerId: const MarkerId("currentLocation"),
                                    position: _filterLocation!,
                                    icon: BitmapDescriptor
                                        .defaultMarkerWithHue(
                                            BitmapDescriptor.hueGreen),
                                    infoWindow: const InfoWindow(
                                      title: "Your Location",
                                    ),
                                  ),
                                );
                              }
                              _updateEventMarkers();
                            });
                          },
                          child: _buildCategoryIcon(
                            _getCategoryIcon(category),
                            category,
                            isSelected: _selectedCategory == category,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                // Trending events header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    // When "Recommended" is chosen, show "Recommended events" label
                    _selectedCategory == "Recommended"
                        ? "Recommended events"
                        : "Trending events near you in $_selectedCategory",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // List of filtered events
                filteredEvents.isNotEmpty
                    ? Column(
                        children: filteredEvents.map((event) {
                          return _buildEventCard(event);
                        }).toList(),
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            "No events found.",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper to select an icon for each category.
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "Recommended":
        return Icons.star_rate;
      case "Music":
        return Icons.music_note;
      case "Sports":
        return Icons.sports_soccer;
      case "Movies":
        return Icons.local_movies;
      case "Theatre":
        return Icons.local_activity;
      default:
        return Icons.category; // For "All" or unknown.
    }
  }

  // Widget for displaying a category icon + label.
  Widget _buildCategoryIcon(IconData icon, String label,
      {bool isSelected = false}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: isSelected ? Colors.orange : const Color(0xFF2A2A2A),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.orange : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // Widget for displaying an event card.
  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: event.imageUrl.isNotEmpty
                ? Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 150,
                  )
                : Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.event, size: 100),
                  ),
          ),
          // Event details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title, date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.eventName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Date: ${event.date}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    // Navigate to EventBuyScreen with the selected event.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventBuyScreen(event: event),
                      ),
                    );
                  },
                  child: const Text(
                    "View",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}