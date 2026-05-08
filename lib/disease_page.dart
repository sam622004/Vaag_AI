import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DiseasePage extends StatefulWidget {
  const DiseasePage({super.key});

  @override
  State<DiseasePage> createState() => _DiseasePageState();
}

class _DiseasePageState extends State<DiseasePage> {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;
  String? _prediction;
  double? _confidence;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
        _prediction = null;
        _confidence = null;
      });
      await _sendToBackend();
    }
  }

  Future<void> _sendToBackend() async {
    if (_image == null) return;

    setState(() {
      _loading = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("http://127.0.0.1:5000/predict"), // Flask backend
      );

      if (kIsWeb) {
        final bytes = await _image!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: _image!.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', _image!.path));
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);

      setState(() {
        _prediction = data['class'] ?? "Unknown";
        _confidence = (data['confidence'] != null)
            ? (data['confidence'] as num).toDouble()
            : null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _prediction = "Error: $e";
        _confidence = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (_image == null) {
      imageWidget = const Text(
        "No image selected.\nPick from gallery or capture with camera.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.grey),
      );
    } else {
      if (kIsWeb) {
        imageWidget = Image.network(_image!.path, height: 250);
      } else {
        imageWidget = Image.file(File(_image!.path), height: 250);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Disease Detection"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(child: Center(child: imageWidget)),
            if (_loading) const LinearProgressIndicator(),
            if (_prediction != null && !_loading)
              Card(
                color: Colors.green.shade50,
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "Prediction: ${_prediction!.replaceAll("_", " ")}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_confidence != null)
                        Text(
                          "Confidence: ${(_confidence! * 100).toStringAsFixed(2)}%",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Gallery"),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}