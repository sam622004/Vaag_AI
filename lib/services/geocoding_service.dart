import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  final String apiKey = "79884015d134f27bf8210e0e9d5a4c1b"; // replace with your key

  Future<Map<String, dynamic>?> getCoordinates(String location) async {
    final url = Uri.parse(
      "http://api.openweathermap.org/geo/1.0/direct?q=$location&limit=1&appid=$apiKey",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        return {
          "lat": data[0]["lat"],
          "lon": data[0]["lon"],
          "name": data[0]["name"],
          "state": data[0]["state"],
          "country": data[0]["country"],
        };
      }
    }
    return null;
  }
}