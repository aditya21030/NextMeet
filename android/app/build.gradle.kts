import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.yousful.nextmeet"
    compileSdk = 36
    buildToolsVersion = "35.0.0"
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        create("release") {
            val properties = keystoreProperties
            val alias = properties.getProperty("keyAlias")
            val keyPass = properties.getProperty("keyPassword")
            val store = properties.getProperty("storeFile")
            val storePass = properties.getProperty("storePassword")

            if (alias != null && keyPass != null && store != null && storePass != null) {
                keyAlias = alias
                keyPassword = keyPass
                storeFile = rootProject.file("app/$store")
                storePassword = storePass
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.yousful.nextmeet"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.3")
    implementation(platform("com.google.firebase:firebase-bom:33.16.0"))
}

configurations.all {
    resolutionStrategy {
        force("androidx.activity:activity-ktx:1.9.3")
        force("androidx.activity:activity:1.9.3")
        force("androidx.core:core-ktx:1.13.1")
        force("androidx.core:core:1.13.1")
        force("androidx.lifecycle:lifecycle-viewmodel-ktx:2.8.7")
        force("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
        force("androidx.lifecycle:lifecycle-livedata-ktx:2.8.7")
        force("androidx.browser:browser:1.8.0")
        
        // Prevent mismatch between versions from different plugins
        force("com.google.android.gms:play-services-ads-identifier:18.1.0")
    }
}

