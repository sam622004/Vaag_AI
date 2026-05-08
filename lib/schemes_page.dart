import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class SchemesPage extends StatefulWidget {
  const SchemesPage({super.key});

  @override
  State<SchemesPage> createState() => _SchemesPageState();
}

class _SchemesPageState extends State<SchemesPage> {
  String searchQuery = "";
  String selectedCategory = "All";

  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link')),
      );
    }
  }

  // 🌱 Category → Icon mapping
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'credit':
        return Icons.credit_card;
      case 'insurance':
        return Icons.security;
      case 'development':
        return Icons.agriculture;
      case 'market access':
        return Icons.store;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔍 Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search schemes...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        // 📂 Category filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: DropdownButtonFormField<String>(
            value: selectedCategory,
            decoration: const InputDecoration(
              labelText: "Filter by Category",
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: "All", child: Text("All")),
              DropdownMenuItem(value: "Credit", child: Text("Credit")),
              DropdownMenuItem(value: "Insurance", child: Text("Insurance")),
              DropdownMenuItem(value: "Development", child: Text("Development")),
              DropdownMenuItem(value: "Market Access", child: Text("Market Access")),
            ],
            onChanged: (value) {
              setState(() {
                selectedCategory = value ?? "All";
              });
            },
          ),
        ),

        const SizedBox(height: 10),

        // 🔄 Schemes list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('schemes').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final schemes = snapshot.data?.docs ?? [];

              // Apply search + category filters
              final filteredSchemes = schemes.where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final title = (data['title'] ?? '').toString().toLowerCase();
                final description = (data['description'] ?? '').toString().toLowerCase();
                final category = (data['category'] ?? '').toString();

                final matchesSearch = title.contains(searchQuery) || description.contains(searchQuery);
                final matchesCategory = selectedCategory == "All" || category == selectedCategory;

                return matchesSearch && matchesCategory;
              }).toList();

              if (filteredSchemes.isEmpty) {
                return const Center(
                  child: Text(
                    'No matching schemes found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredSchemes.length,
                itemBuilder: (context, index) {
                  final data = filteredSchemes[index].data() as Map<String, dynamic>? ?? {};
                  final category = (data['category'] ?? '').toString();

                  return Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🌱 Title with category icon
                          Row(
                            children: [
                              Icon(_getCategoryIcon(category), color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['title'] ?? 'No Title',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...data.entries
                              .where((entry) =>
                                  entry.key != 'title' && entry.key != 'apply_link')
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Text(
                                    '${entry.key}: ${entry.value}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                          if (data['apply_link'] != null &&
                              (data['apply_link'] as String).isNotEmpty)
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _launchURL(context, data['apply_link']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                icon: const Icon(Icons.open_in_new,
                                    size: 16, color: Colors.white),
                                label: const Text("Apply Now"),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}