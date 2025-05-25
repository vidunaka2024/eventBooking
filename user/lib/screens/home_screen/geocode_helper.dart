import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;

/// Geocode [address] into [LatLng].
///
/// On Web, uses the Google Geocoding REST API with [googleApiKey].
/// On Android/iOS, uses the device-based [geocoding] plugin.
/// Returns `null` if geocoding fails or no results.
Future<LatLng?> geocodeAddress(String address, String googleApiKey) async {
  if (kIsWeb) {
    // 1) On the web, do an HTTP request to the Google Geocoding REST API.
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          double lat = location['lat'];
          double lng = location['lng'];
          return LatLng(lat, lng);
        } else {
          print("Web geocoding: got status=${data['status']}");
          return null;
        }
      } else {
        print("Web geocoding: HTTP error ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Web geocoding error: $e");
      return null;
    }
  } else {
    // 2) On Android/iOS, use the 'geocoding' plugin for device-based geocoding.
    try {
      final List<geo.Location> locations = await geo.locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        return LatLng(loc.latitude, loc.longitude);
      }
      return null;
    } catch (e) {
      print("Mobile geocoding error: $e");
      return null;
    }
  }
}
