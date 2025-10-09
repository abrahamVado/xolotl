//1.- Gestiona la obtención del SDK de Flutter y declara repositorios para los plugins.
pluginManagement {
    //2.- Carga el archivo local.properties para ubicar el SDK de Flutter en el sistema.
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        properties.getProperty("flutter.sdk")
            ?: error("flutter.sdk not set in local.properties")
    }

    //3.- Incluye el build generado por Flutter para exponer sus tareas y plugins.
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    //4.- Declara los repositorios oficiales necesarios para resolver dependencias de plugins.
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

//5.- Define los plugins que se cargarán en el proyecto con versiones alineadas al repositorio de referencia.
plugins {
    //1.- Habilita el cargador de plugins de Flutter para registrar tareas adicionales.
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    //2.- Expone el plugin de aplicación Android con la versión 8.9.1 sin aplicarlo de inmediato.
    id("com.android.application") version "8.9.1" apply false
    //3.- Expone el plugin de Kotlin Android con la versión 2.1.0, también sin aplicarlo.
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

//6.- Registra el módulo principal de la app dentro del árbol de Gradle.
include(":app")
