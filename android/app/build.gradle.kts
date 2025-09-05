plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

fun localPropertiesFile(fileName: String = "local.properties"): java.io.File =
    File(rootProject.projectDir, fileName)

val localProperties = Properties()
try {
    localPropertiesFile().inputStream().use {
        localProperties.load(it)
    }
} catch (e: java.io.FileNotFoundException) {
    println("Warning: ${localPropertiesFile().name} not found. Skipping.")
}

// ✅ Valeurs avec fallback si absentes
val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0.0"
val flutterMinSdkVersion = localProperties.getProperty("flutter.minSdkVersion") ?: "21"

android {
    namespace = "com.example.savoir_plus"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        applicationId = "com.example.savoir_plus"
        minSdk = flutterMinSdkVersion.toInt()
        targetSdk = flutter.compileSdkVersion
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies { }
