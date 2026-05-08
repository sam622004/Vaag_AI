import 'package:flutter/material.dart';
import 'services/weather_service.dart';
import 'services/geocoding_service.dart';
import 'package:intl/intl.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? weatherData;
  bool isLoading = false;

  Future<void> _getWeather(String location) async {
    setState(() => isLoading = true);

    final geoService = GeocodingService();
    var coords = await geoService.getCoordinates(location.trim());

    // fallback if location not found
    coords ??= {"lat": 13.0827, "lon": 80.2707, "name": "Chennai"};

    try {
      final service = WeatherService();
      final data = await service.fetchWeather(coords["lat"], coords["lon"]);

      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Weather service error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Weather Module")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Enter location (e.g., Chennai)",
                border: OutlineInputBorder(),
              ),
              onSubmitted: _getWeather,
            ),
            const SizedBox(height: 10),
            if (isLoading) const CircularProgressIndicator(),
            if (weatherData != null)
              Expanded(
                child: ListView(
                  children: [
                    Text("🌡️ Current Temp: ${weatherData!['current']['temperature_2m']} °C"),
                    Text("💨 Wind: ${weatherData!['current']['wind_speed_10m']} km/h"),
                    const SizedBox(height: 10),
                    const Text("📅 Forecast:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ...List.generate(
                      (weatherData!['daily']['time'] as List).length,
                      (i) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today, color: Colors.green),
                          title: Text(
                            DateFormat('EEE, dd MMM').format(
                              DateTime.parse(weatherData!['daily']['time'][i]),
                            ),
                          ),
                          subtitle: Text(
                            "Max: ${weatherData!['daily']['temperature_2m_max'][i]}°C, "
                            "Min: ${weatherData!['daily']['temperature_2m_min'][i]}°C, "
                            "Rain: ${weatherData!['daily']['precipitation_sum'][i]} mm",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}