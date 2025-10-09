import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

//1.- Configura repositorios y rutas de build replicando la estructura del proyecto de referencia.
allprojects {
    //2.- Expone los repositorios principales para todas las dependencias de los subproyectos.
    repositories {
        google()
        mavenCentral()
    }
}

//3.- Reubica las carpetas de compilación para mantener el árbol de artefactos fuera del módulo Android.
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

//4.- Ajusta la carpeta de compilación de cada subproyecto para que cuelgue del nuevo directorio.
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

//5.- Asegura que el módulo app se evalúe antes que los demás, tal como en la app ciudadana.
subprojects {
    project.evaluationDependsOn(":app")
}

//6.- Define la tarea clean que elimina por completo los artefactos generados.
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
