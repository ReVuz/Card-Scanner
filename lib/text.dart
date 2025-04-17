import 'package:flutter/material.dart';
import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'business_card_parser.dart';
import 'business_card_result.dart';
import 'saved_contacts_page.dart'; // Add this import

class text extends StatefulWidget {
  const text({super.key});

  @override
  State<text> createState() => _textState();
}

class _textState extends State<text> {
  XFile? pickedImage;
  String mytext = '';
  bool scanning = false;

  final ImagePicker _imagePicker = ImagePicker();
  getImage(ImageSource ourSource) async {
    XFile? result = await _imagePicker.pickImage(source: ourSource);
    if (result != null) {
      setState(() {
        pickedImage = result;
      });
      performTextRecognition();
    }
  }

  performTextRecognition() async {
    setState(() {
      scanning = true;
    });
    try {
      final inputImage = InputImage.fromFilePath(pickedImage!.path);
      final textRecognizer = GoogleMlKit.vision.textRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      setState(() {
        mytext = recognizedText.text;
        scanning = false;
      });
      textRecognizer.close();
    } catch (e) {
      print("Error during scanning : $e");
      setState(() {
        scanning = false;
      });
    }
  }

  void _showExtractedData() {
    if (mytext.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No text to analyze')));
      return;
    }

    final parsedData = BusinessCardParser.parse(mytext);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BusinessCardResultPage(
              parsedData: parsedData,
              originalText: mytext, // Pass the original text
            ),
      ),
    );
  }

  void _openSavedContacts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SavedContactsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts),
            onPressed: _openSavedContacts,
            tooltip: 'Saved Contacts',
          ),
        ],
      ),
      body: ListView(
        shrinkWrap: true,
        children: [
          pickedImage == null
              ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 30,
                ),
                child: ClayContainer(
                  height: 400,
                  child: const Center(child: Text('No Image Found')),
                ),
              )
              : Center(child: Image.file(File(pickedImage!.path), height: 400)),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  getImage(ImageSource.gallery);
                },
                icon: const Icon(Icons.photo),
                label: const Text('Gallery'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  getImage(ImageSource.camera);
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Center(child: Text('Recognized Text : ')),
          const SizedBox(height: 30),

          scanning
              ? const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(
                  child: SpinKitThreeBounce(color: Colors.black, size: 30),
                ),
              )
              : Column(
                children: [
                  Center(
                    child: AnimatedTextKit(
                      isRepeatingAnimation: false,
                      animatedTexts: [
                        TypewriterAnimatedText(
                          mytext,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (mytext.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _showExtractedData,
                      icon: const Icon(Icons.badge),
                      label: const Text('Extract Card Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
        ],
      ),
    );
  }
}
