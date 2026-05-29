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
    ndkVersion = "28.1.13356709"

    defaultConfig {
        applicationId = "com.manasseh.fihirana_jff"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 12
        versionName = "1.0.46"
        multiDexEnabled = true
    }

    signingConfigs {
        register("release") {
            // Use environment variables for security
            keyAlias = System.getenv("KEY_ALIAS") ?: project.findProperty("KEY_ALIAS") as String? ?: "fihirana"
            keyPassword = System.getenv("KEY_PASSWORD") ?: project.findProperty("KEY_PASSWORD") as String? ?: "fihirana2024"
            storeFile = file(System.getenv("KEYSTORE_FILE") ?: project.findProperty("KEYSTORE_FILE") as String? ?: "fihirana.jks")
            storePassword = System.getenv("STORE_PASSWORD") ?: project.findProperty("STORE_PASSWORD") as String? ?: "fihirana2024"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Ensure assets are properly included in release builds
            packaging {
                resources {
                    excludes += "/META-INF/{AL2.0,LGPL2.1}"
                    // Include all assets
                    pickFirsts += "**/*.json"
                    pickFirsts += "**/*.ttf"
                    pickFirsts += "**/*.png"
                    pickFirsts += "**/*.svg"
                }
            }
        }
        
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
            isDebuggable = true
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
