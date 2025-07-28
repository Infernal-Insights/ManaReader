diff --git a//dev/null b/mana_reader/android/app/build.gradle.kts
index 0000000000000000000000000000000000000000..b3dda403a4a46c3f6e35321f35c78d5fa70140ea 100644
--- a//dev/null
+++ b/mana_reader/android/app/build.gradle.kts
@@ -0,0 +1,44 @@
+plugins {
+    id("com.android.application")
+    id("kotlin-android")
+    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
+    id("dev.flutter.flutter-gradle-plugin")
+}
+
+android {
+    namespace = "com.example.mana_reader"
+    compileSdk = flutter.compileSdkVersion
+    ndkVersion = flutter.ndkVersion
+
+    compileOptions {
+        sourceCompatibility = JavaVersion.VERSION_11
+        targetCompatibility = JavaVersion.VERSION_11
+    }
+
+    kotlinOptions {
+        jvmTarget = JavaVersion.VERSION_11.toString()
+    }
+
+    defaultConfig {
+        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
+        applicationId = "com.example.mana_reader"
+        // You can update the following values to match your application needs.
+        // For more information, see: https://flutter.dev/to/review-gradle-config.
+        minSdk = flutter.minSdkVersion
+        targetSdk = flutter.targetSdkVersion
+        versionCode = flutter.versionCode
+        versionName = flutter.versionName
+    }
+
+    buildTypes {
+        release {
+            // TODO: Add your own signing config for the release build.
+            // Signing with the debug keys for now, so `flutter run --release` works.
+            signingConfig = signingConfigs.getByName("debug")
+        }
+    }
+}
+
+flutter {
+    source = "../.."
+}
