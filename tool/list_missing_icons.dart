import 'dart:io';

import 'package:xolotl/tooling/icon_audit.dart';

Future<void> main(List<String> arguments) async {
  //1.- Determinamos la ruta base de Android usando el argumento o la ubicación por defecto.
  final String provided = arguments.isNotEmpty ? arguments.first : 'android/app/src/main';
  final Directory target = Directory(provided);

  //2.- Validamos que la carpeta exista antes de ejecutar la auditoría.
  if (!target.existsSync()) {
    stderr.writeln('Android directory not found: ${target.path}');
    exitCode = 2;
    return;
  }

  //3.- Ejecutamos la auditoría para obtener los íconos faltantes y sus referencias.
  final IconAuditResult result = auditAndroidIcons(target);

  //4.- Reportamos el estado al usuario final en formato legible.
  if (result.missingIcons.isEmpty) {
    stdout.writeln('No missing icons detected.');
    return;
  }

  stdout.writeln('Missing icons detected (${result.missingIcons.length}):');
  for (final MissingIcon icon in result.missingIcons) {
    stdout.writeln('- ${icon.resourceType}/${icon.name}');
    for (final String source in icon.sources) {
      stdout.writeln('  • referenced from $source');
    }
  }
}
