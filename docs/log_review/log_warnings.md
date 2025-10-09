# Android log warnings overview

//1.- Este documento resume los mensajes observados en el registro proporcionado y su impacto.

//2.- `Too many Flogger logs received before configuration` aparece cuando la biblioteca Cronet emite
//   registros antes de inicializar su backend en dispositivos con muchas solicitudes. Es informativo y
//   se mitiga inicializando Cronet temprano o ignorando la advertencia.

//3.- `Unable to acquire a buffer item` proviene de `ImageReader_JNI` al intentar tomar más imágenes
//   simultáneas que el búfer permitido. Normalmente ocurre con múltiples capturas rápidas y se resuelve
//   liberando fotogramas previos o reduciendo la frecuencia de captura.

//4.- `Unable to open libdolphin.so` indica que una librería opcional no está presente. En nuestra app
//   no se utiliza Dolphin, por lo que puede ignorarse mientras no requiramos esa característica.

//5.- La advertencia `OnBackInvokedCallback is not enabled` sí se corrige activando
//   `android:enableOnBackInvokedCallback="true"` en el `AndroidManifest.xml`, cambio aplicado en este PR.
