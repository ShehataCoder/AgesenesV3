# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google ML Kit & TensorFlow Lite
-dontwarn com.google.mlkit.**
-keep class com.google.mlkit.** { *; }
-dontwarn org.tensorflow.lite.**
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# ----------------------------------------------------------
# Google Play Core & Deferred Components (Fix for R8 Missing Class)
# ----------------------------------------------------------
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
