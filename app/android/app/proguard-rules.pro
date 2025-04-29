# Google Play Core libraries
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Google API Client
-dontwarn com.google.api.client.http.**
-dontwarn com.google.api.client.http.javanet.**

# Error Prone annotations
-dontwarn com.google.errorprone.annotations.**

# JSR 305 annotations
-dontwarn javax.annotation.**
-dontwarn javax.annotation.concurrent.**

# Joda Time
-dontwarn org.joda.time.**

# Keep Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Tink Crypto Library
-keep class com.google.crypto.tink.** { *; }