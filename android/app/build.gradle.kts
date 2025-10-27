plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.2"))
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.20")
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("androidx.biometric:biometric:1.1.0")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.android.gms:play-services-auth:20.7.0")
    implementation("com.google.android.gms:play-services-measurement:21.2.0")
    implementation("com.google.android.gms:play-services-measurement-api:21.2.0")
}

android {
    namespace = "com.manasseh.fihirana_jff"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.manasseh.fihirana_jff"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 2
        versionName = "1.0.1"
        multiDexEnabled = true
    }

    signingConfigs {
        register("release") {
            keyAlias = "fihirana"
            keyPassword = "fihirana2024"
            storeFile = file("fihirana.jks")
            storePassword = "fihirana2024"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
}

flutter {
    source = "../.."
}
