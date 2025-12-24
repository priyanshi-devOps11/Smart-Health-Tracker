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
    
    implementation(kotlin("stdlib"))
}
