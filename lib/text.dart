import 'package:flutter/material.dart';
import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Scanner')),
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
                  child: Center(child: Text('No Image Found')),
                ),
              )
              : Center(child: Image.file(File(pickedImage!.path), height: 400)),
          SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  getImage(ImageSource.gallery);
                },
                icon: Icon(Icons.photo),
                label: Text('Gallery'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  getImage(ImageSource.camera);
                },
                icon: Icon(Icons.camera_alt),
                label: Text('Camera'),
              ),
            ],
          ),
          SizedBox(height: 20),
          Center(child: Text('Recognized Text : ')),
          SizedBox(height: 30),

          scanning
              ? Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(
                  child: SpinKitThreeBounce(color: Colors.black, size: 30),
                ),
              )
              : Center(
                child: AnimatedTextKit(
                  isRepeatingAnimation: false,
                  animatedTexts: [
                    TypewriterAnimatedText(mytext, textAlign: TextAlign.center),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
