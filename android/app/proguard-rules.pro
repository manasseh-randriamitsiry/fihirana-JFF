#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# GetX
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
-keep class com.google.inject.** { *; }
-keep class org.aopalliance.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class androidx.work.** { *; }

# Flutter
-keep class io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin { *; }
-keep class io.flutter.plugins.firebase.auth.FlutterFirebaseAuthPlugin { *; }
-keep class io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestorePlugin { *; }

# General
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-dontwarn javax.annotation.**
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**
-dontwarn com.google.errorprone.annotations.**
