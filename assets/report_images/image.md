# Guía de imágenes JPEG

Este directorio `assets/report_images/` está destinado a almacenar los íconos o fotografías en formato **JPEG** que serán consumidos por la aplicación.

## Pasos para agregar imágenes

1. Coloca los archivos `.jpg` o `.jpeg` dentro de esta carpeta manteniendo nombres descriptivos y en minúsculas.
2. Actualiza la API o configuración correspondiente para que la propiedad `image_url` de cada tipo de reporte apunte al nombre del archivo, por ejemplo `report_images/iluminacion_nocturna.jpg`.
3. Asegúrate de ejecutar `flutter pub get` después de agregar nuevas imágenes para que el `AssetManifest` se regenere antes de compilar la aplicación.

## Recomendaciones

- Evita espacios en los nombres de archivo; utiliza guiones bajos (`_`) para separar palabras.
- Optimiza cada imagen para que pese menos de 200 KB con el fin de mejorar los tiempos de carga.
- Conserva una copia original en un repositorio seguro por si necesitas regenerar los recursos.
