import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class PlacesService {
  final String apiKey;
  final http.Client _client; // Persistent HTTP client

  PlacesService({required this.apiKey}) : _client = http.Client();

  Future<List<Map<String, String>>> fetchSuggestions(String query) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey&language=en&components=country:CL';
      developer.log('Fetching suggestions for: $query', name: 'PlacesService');

      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          return List<Map<String, String>>.from(
            data['predictions'].map((p) => {
              'description': p['description'] as String,
              'place_id': p['place_id'] as String,
            }),
          );
        } else {
          developer.log('Google Places API error: ${data['status']}', name: 'PlacesService');
        }
      } else {
        developer.log('HTTP error: ${response.statusCode}', name: 'PlacesService');
      }
    } catch (e) {
      developer.log('Error fetching suggestions: $e', name: 'PlacesService');
    }
    return [];
  }

  void dispose() {
    _client.close(); // Close the HTTP client to cancel ongoing requests
  }
}