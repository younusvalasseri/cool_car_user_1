plugins {
    id("com.android.application")
    kotlin("android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.cool_car_user_1"
    compileSdk = 35  
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11" 
    }

    defaultConfig {
        applicationId = "com.example.cool_car_user_1"
        minSdkVersion(23) 
        targetSdkVersion(35) 
        versionCode = 1 
        versionName = "1.0.0" 
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // Use debug signing
        }
    }
}

flutter {
    source = "../.."
}
