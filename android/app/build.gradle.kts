plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val flutterEnvNative = project(":flutter_env_native")
apply(from = "${flutterEnvNative.projectDir}/envConfig.gradle")

android {
    namespace = "com.onodnawij.siga"
    compileSdk = flutter.compileSdkVersion
    //ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.onodnawij.siga"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        buildConfigField("String", "TELEGRAM_BOT_TOKEN", "\"${project.findProperty("TELEGRAM_BOT_TOKEN") ?: "default_value"}\"")
        buildConfigField("String", "TELEGRAM_CHAT_ID", "\"${project.findProperty("TELEGRAM_CHAT_ID") ?: "default_value"}\"")
    }

    signingConfigs {
        create("release") {
            storeFile = file(project.findProperty("KEYSTORE_FILE"))
            storePassword = project.findProperty("STORE_PASSWORD") as String
            keyAlias = project.findProperty("KEY_ALIAS") as String
            keyPassword = project.findProperty("KEY_PASSWORD") as String
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // WorkManager dependency for background tasks
    implementation("androidx.work:work-runtime-ktx:2.8.1")

    // OkHttp dependency for network requests
    implementation("com.squareup.okhttp3:okhttp:4.9.3")

    // Add this if you need to handle permissions for older Android versions
    implementation("androidx.core:core-ktx:1.9.0")

    // Logging support (optional, but good for debugging)
    implementation("com.squareup.okhttp3:logging-interceptor:4.9.3")
}