/* -------------------------------------------------------------
 *  build.gradle.kts  —  tflite_flutter plugin (Kotlin DSL)
 * -------------------------------------------------------------
 *  • Adds required namespace to satisfy AGP 8.x+
 *  • Uses Android Gradle Plugin 8 syntax
 *  • Targets Java 11 (compatible with Flutter 3.16+)
 * -------------------------------------------------------------
 */

plugins {
    id("com.android.library")
    kotlin("android")
}

android {
    // ✅ mandatory for AGP 8+
    namespace = "com.tensorflow.lite_flutter"

    // ☑️  choose your target SDK
    compileSdk = 33

    defaultConfig {
        minSdk = 21
        // targetSdk is optional for libraries; compileSdk is enough.
    }

    // Java 11 (matches latest Flutter template)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }
}

dependencies {
    // Kotlin stdlib (provided automatically by Kotlin plugin in newer AGP versions,
    // but you can keep it explicit for clarity)
    implementation(kotlin("stdlib"))

    // TensorFlow Lite runtime supplied by Flutter’s prebuilt binaries;
    // no extra Maven dependency required.
}
