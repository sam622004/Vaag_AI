import 'dart:convert';
import 'package:http/http.dart' as http;

// Categories for dropdowns
const Map<String, List<String>> kAgCategories = {
  "Crops": ["Paddy", "Rice", "Maize", "Sugarcane", "Cotton", "Groundnut", "Millet"],
  "Vegetables": ["Tomato", "Onion", "Brinjal", "Chili", "Potato"],
  "Fruits": ["Banana", "Mango", "Coconut"],
  "Dairy & Livestock": ["Milk", "Egg", "Poultry"],
};

// Static fallback markets
const List<String> kTamilNaduMarkets = [
  "Koyambedu",
  "Madurai",
  "Trichy",
  "Salem",
  "Tirunelveli",
  "Erode",
  "Thanjavur",
  "Vellore",
  "Dindigul",
];

class MarketService {
  // ✅ Permanent API key
  final String apiKey = "579b464db66ec23bdd000001b5857e83e3244e1f705e5883a1512422";

  // ✅ Resource ID for "Variety-wise Daily Market Prices Data of Commodity"
  final String resourceId = "35985678-0d79-46b4-9ed6-6f13308a1d24";

  /// Normalize filters (capitalization + spacing)
  String _normalize(String input) {
    if (input.isEmpty) return input;
    return input.trim().split(" ").map((w) =>
      w[0].toUpperCase() + w.substring(1).toLowerCase()
    ).join(" ");
  }

  /// Fetch live prices
  Future<List<Map<String, dynamic>>> fetchPrices({
    required String commodity,
    required String state,
    String? district,
    String? market,
  }) async {
    final query = {
      "api-key": apiKey,
      "format": "json",
      "filters[State]": _normalize(state),
      "filters[Commodity]": _normalize(commodity),
      if (district != null && district.isNotEmpty)
        "filters[District]": _normalize(district),
      if (market != null && market.isNotEmpty)
        "filters[Market]": _normalize(market),
      "limit": "50",
    };

    final uri = Uri.https("api.data.gov.in", "/resource/$resourceId", query);
    print("🔎 API URL: $uri");

    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      final List records = body["records"] ?? [];
      return records.map<Map<String, dynamic>>((e) => {
            "state": e["State"] ?? state,
            "district": e["District"] ?? district ?? "N/A",
            "market": e["Market"] ?? (market ?? "N/A"),
            "commodity": e["Commodity"] ?? commodity,
            "variety": e["Variety"] ?? "N/A",
            "grade": e["Grade"] ?? "N/A",
            "modal_price": e["Modal_Price"] ?? "N/A",
            "min_price": e["Min_Price"] ?? "N/A",
            "max_price": e["Max_Price"] ?? "N/A",
            "date": e["Arrival_Date"] ?? "N/A",
          }).toList();
    } else {
      throw Exception("Agmarknet error ${resp.statusCode}: ${resp.body}");
    }
  }

  /// Fetch distinct markets for a commodity
  Future<List<String>> fetchMarketsForCommodity(String commodity) async {
    final query = {
      "api-key": apiKey,
      "format": "json",
      "filters[State]": "Tamil Nadu",
      "filters[Commodity]": _normalize(commodity),
      "limit": "200",
    };

    final uri = Uri.https("api.data.gov.in", "/resource/$resourceId", query);
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      final List records = body["records"] ?? [];
      final markets = records
          .map((e) => (e["Market"] ?? "").toString().trim())
          .where((m) => m.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      return markets;
    } else {
      throw Exception("Failed to fetch market list: ${resp.statusCode}");
    }
  }
}