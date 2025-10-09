plugins {
    //1.- Activa el plugin de aplicación Android siguiendo la configuración del proyecto de referencia.
    id("com.android.application")
    //2.- Habilita compatibilidad con Kotlin para compartir la misma pila que la app ciudadana.
    id("kotlin-android")
    //3.- Aplica el plugin de Flutter después de los plugins de Android y Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    //1.- Mantiene el namespace original de la aplicación alineado con el AndroidManifest.
    namespace = "com.example.mictlan_client"
    //2.- Sincroniza compileSdk y ndk con los valores resueltos por Flutter.
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    //3.- Ajusta la compatibilidad de Java igual que en el proyecto de referencia.
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    //4.- Configura Kotlin para emitir bytecode objetivo Java 11.
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        //5.- Conserva el applicationId del proyecto xolotl mientras reutiliza la estructura de referencia.
        applicationId = "com.example.mictlan_client"
        //6.- Replica la obtención dinámica de versionado administrado por Flutter.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    //7.- Porta la misma configuración de sabores citizen/admin proveniente de la app de referencia.
    flavorDimensions.add("app")
    productFlavors {
        create("citizen") {
            dimension = "app"
            applicationIdSuffix = ".citizen"
            versionNameSuffix = "-citizen"
        }
        create("admin") {
            dimension = "app"
            applicationIdSuffix = ".admin"
            versionNameSuffix = "-admin"
        }
    }

    //8.- Mantiene la firma de release utilizando las claves de depuración como en la referencia.
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

//9.- Señala al plugin de Flutter el directorio raíz del código fuente Dart.
flutter {
    source = "../.."
}

dependencies {
    //10.- Agrega Material Components para proporcionar el tema usado por los estilos Android.
    implementation("com.google.android.material:material:1.12.0")
}
