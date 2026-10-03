# ProGuard rules for Ghost-Link (LocalLoop) Mobile App
# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in flutter_root/packages/flutter_tools/gradle/flutter.gradle
# For more information, see https://developer.android.com/studio/build/shrink-code

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Riverpod
-keep class io.flutter.plugins.riverpod.** { *; }

# GoRouter
-keep class com.google.googlenav.** { *; }

# sqflite
-keep class com.tekartik.sqflite.** { *; }

# WebSocket
-keep class io.flutter.plugins.websocket.** { *; }

# Crypto
-keep class cryptography.** { *; }

# Mobile Scanner
-keep class com.google.mlkit.vision.barcode.** { *; }

# Keep serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName *;
}

# Prevent obfuscation of data classes
-keepclassmembers class * {
    @kotlin.metadata.KotlinMetadata *;
}

# Keep line numbers for crash reporting
-keepattributes SourceFile,LineNumberTable

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}