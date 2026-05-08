import 'package:flutter/material.dart';
import 'services/agmarket_data.dart';

class AgMarketPage extends StatefulWidget {
  const AgMarketPage({super.key});

  @override
  State<AgMarketPage> createState() => _AgMarketPageState();
}

class _AgMarketPageState extends State<AgMarketPage> {
  final MarketService _service = MarketService();

  String? _category;
  String? _commodity;
  String? _market;

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _prices = [];
  List<String> _availableMarkets = [];

  Future<void> _loadPrices() async {
    if (_commodity == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _prices = [];
    });

    try {
      final results = await _service.fetchPrices(
        commodity: _commodity!,
        state: "Tamil Nadu",
        district: "Chennai", // optional, can be dynamic later
        market: _market,
      );
      setState(() {
        _prices = results;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load prices: $e";
        _loading = false;
      });
    }
  }

  Future<void> _loadMarkets(String commodity) async {
    try {
      final markets = await _service.fetchMarketsForCommodity(commodity);
      setState(() {
        _availableMarkets = markets;
        if (_market != null && !_availableMarkets.contains(_market)) {
          _market = null;
        }
      });
    } catch (_) {
      setState(() {
        _availableMarkets = kTamilNaduMarkets.toSet().toList()..sort();
        if (_market != null && !_availableMarkets.contains(_market)) {
          _market = null;
        }
      });
    }
  }

  List<String> _getCommodities() {
    if (_category == null) return [];
    return kAgCategories[_category] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final commodities = _getCommodities();
    final marketSource = _availableMarkets.isNotEmpty
        ? _availableMarkets
        : (kTamilNaduMarkets.toSet().toList()..sort());

    return Scaffold(
      appBar: AppBar(
        title: const Text("AgMarket Prices 🌾"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category dropdown
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
              items: kAgCategories.keys
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _category = val;
                  _commodity = null;
                  _market = null;
                  _availableMarkets = [];
                });
              },
            ),
            const SizedBox(height: 10),

            // Commodity dropdown
            DropdownButtonFormField<String>(
              value: _commodity,
              decoration: const InputDecoration(
                labelText: "Commodity",
                border: OutlineInputBorder(),
              ),
              items: commodities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _commodity = val;
                  _market = null;
                  _availableMarkets = [];
                });
                if (val != null && val.isNotEmpty) {
                  _loadMarkets(val);
                }
              },
            ),
            const SizedBox(height: 10),

            // Market dropdown
            DropdownButtonFormField<String>(
              value: marketSource.contains(_market) ? _market : null,
              decoration: const InputDecoration(
                labelText: "Market (optional)",
                border: OutlineInputBorder(),
              ),
              items: marketSource
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _market = val;
                });
              },
            ),
            const SizedBox(height: 12),

            // Fetch button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text("Show Live Prices"),
                onPressed: _loading ? null : _loadPrices,
              ),
            ),
            const SizedBox(height: 10),

            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),

            if (!_loading && _prices.isEmpty && _error == null)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "No price data found for this selection.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),

            if (_prices.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _prices.length,
                  itemBuilder: (context, i) {
                    final item = _prices[i];
                    return Card(
                      elevation: 3,
                      child: ListTile(
                        leading: const Icon(Icons.store, color: Colors.green),
                        title: Text(
                          "${item['market']} • ${item['commodity']} (${item['variety']})",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "🟢 Modal: ₹${item['modal_price']} / quintal\n"
                          "Min: ₹${item['min_price']} | Max: ₹${item['max_price']}\n"
                          "📅 Date: ${item['date']}",
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}