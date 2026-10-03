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
    // For debug builds, the default debug signing config is used automatically
    signingConfigs {
        create("release") {
            // Keystore configuration - set these in gradle.properties or local.properties:
            // storeFile=../keystore/release.keystore
            // storePassword=RELEASE_STORE_PASSWORD
            // keyAlias=release
            // keyPassword=RELEASE_KEY_PASSWORD
            val storeFileProp = project.findProperty("storeFile") as String?
            val storePasswordProp = project.findProperty("storePassword") as String?
            val keyAliasProp = project.findProperty("keyAlias") as String?
            val keyPasswordProp = project.findProperty("keyPassword") as String?

            // Only validate keystore config for release builds
            // This allows debug builds to work without keystore configuration
            val isReleaseBuild = project.gradle.startParameter.taskNames.any { it.contains("Release") || it.contains("release") }
            
            if (storeFileProp != null && storePasswordProp != null && keyAliasProp != null && keyPasswordProp != null) {
                storeFile = file(storeFileProp)
                storePassword = storePasswordProp.toString()
                keyAlias = keyAliasProp.toString()
                keyPassword = keyPasswordProp.toString()
            } else if (isReleaseBuild) {
                // Only throw error for release builds
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
