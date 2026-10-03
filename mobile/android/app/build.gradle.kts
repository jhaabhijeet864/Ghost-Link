plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ghostlink.localloop"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Application ID for Ghost-Link (LocalLoop) mobile app
        applicationId = "com.ghostlink.localloop"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Signing configurations - release keystore should be configured via gradle.properties or local.properties
    signingConfigs {
        create("release") {
            // Keystore configuration - set these in gradle.properties or local.properties:
            // storeFile=../keystore/release.keystore
            // storePassword=RELEASE_STORE_PASSWORD
            // keyAlias=release
            // keyPassword=RELEASE_KEY_PASSWORD
            val storeFile = project.findProperty("storeFile") as String?
            val storePassword = project.findProperty("storePassword") as String?
            val keyAlias = project.findProperty("keyAlias") as String?
            val keyPassword = project.findProperty("keyPassword") as String?

            if (storeFile != null && storePassword != null && keyAlias != null && keyPassword != null) {
                storeFile = file(storeFile)
                storePassword = storePassword.toString()
                keyAlias = keyAlias.toString()
                keyPassword = keyPassword.toString()
            } else {
                // Fallback to debug config for development builds only
                throw GradleException("Release keystore not configured. Set storeFile, storePassword, keyAlias, keyPassword in gradle.properties or local.properties")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
