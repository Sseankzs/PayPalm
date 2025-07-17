plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

android {
    namespace = "com.paypalm_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" //

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.paypalm_mobile"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val props = Properties()
            project.rootProject.file("local.properties").inputStream().use { props.load(it) }

            val keystorePathValue = props["KEYSTORE_PATH"] ?: throw GradleException("KEYSTORE_PATH is missing in local.properties")
            val keystorePasswordValue = props["KEYSTORE_PASSWORD"] ?: throw GradleException("KEYSTORE_PASSWORD is missing in local.properties")
            val keyAliasValue = props["KEY_ALIAS"] ?: throw GradleException("KEY_ALIAS is missing in local.properties")
            val keyPasswordValue = props["KEY_PASSWORD"] ?: throw GradleException("KEY_PASSWORD is missing in local.properties")

            storeFile = file(keystorePathValue as String)
            storePassword = keystorePasswordValue as String
            keyAlias = keyAliasValue as String
            keyPassword = keyPasswordValue as String
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.2"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
}
