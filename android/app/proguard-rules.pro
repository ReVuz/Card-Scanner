# Keep default TextRecognizer (English)
-keep class com.google.mlkit.vision.text.TextRecognizer { *; }

# Don't keep other language-specific recognizers
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**