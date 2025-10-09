import java.io.File

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
            //7.1.- Define este sabor como predeterminado para que Flutter pueda compilar sin especificar uno.
            isDefault = true
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

//11.- Define el sabor predeterminado que Flutter debe usar para generar los artefactos esperados.
val defaultFlutterFlavor = "citizen"

//12.- Función auxiliar que copia el APK generado al directorio monitoreado por Flutter.
fun registerFlutterApkCopyTask(buildType: String) {
    //12.1.- Localiza la tarea assemble correspondiente al tipo de compilación indicado.
    tasks.matching { it.name == "assemble${buildType.replaceFirstChar { ch -> ch.uppercase() }}" }
        .configureEach {
            //12.2.- Agrega un paso final que copia y renombra el APK del sabor predeterminado.
            doLast {
                //12.2.1.- Ruta del APK generado por Gradle para el sabor predeterminado.
                val variantApk = File(
                    buildDir,
                    "outputs/apk/$defaultFlutterFlavor/${buildType.lowercase()}/app-$defaultFlutterFlavor-${buildType.lowercase()}.apk",
                )

                //12.2.2.- Directorio esperado por la herramienta de Flutter para instalar el APK.
                val flutterOutputDir = File(buildDir, "outputs/flutter-apk")

                //12.2.3.- Copia el archivo cuando está disponible y avisa si falta para facilitar el diagnóstico.
                if (variantApk.exists()) {
                    flutterOutputDir.mkdirs()
                    variantApk.copyTo(File(flutterOutputDir, "app-${buildType.lowercase()}.apk"), overwrite = true)
                } else {
                    logger.warn("No se encontró el APK ${variantApk.path} tras ejecutar ${name}.")
                }
            }
        }
}

//13.- Registra la sincronización para los tipos de compilación soportados por Flutter.
listOf("debug", "profile", "release").forEach(::registerFlutterApkCopyTask)
