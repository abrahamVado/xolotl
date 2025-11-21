import 'dart:io';

//1.- _iconPattern detecta referencias a drawables o mipmaps dentro de XML Android.
final RegExp _iconPattern = RegExp(r'@((?:drawable|mipmap))/([A-Za-z0-9_.-]+)');

//2.- MissingIcon describe un recurso faltante y las rutas que lo referencian.
class MissingIcon {
  final String resourceType;
  final String name;
  final Set<String> sources;

  const MissingIcon({
    required this.resourceType,
    required this.name,
    required this.sources,
  });
}

//3.- IconAuditResult resume la auditoría y permite inspeccionar faltantes y referencias.
class IconAuditResult {
  final List<MissingIcon> missingIcons;
  final Map<String, Set<String>> references;

  const IconAuditResult({
    required this.missingIcons,
    required this.references,
  });

  //4.- hasMissingIcons indica rápidamente si existen referencias rotas.
  bool get hasMissingIcons => missingIcons.isNotEmpty;
}

//5.- auditAndroidIcons recorre el árbol principal de Android y detecta íconos ausentes.
IconAuditResult auditAndroidIcons(Directory androidMainDir) {
  final Directory root = androidMainDir.absolute;
  final Directory resDir = Directory('${root.path}${Platform.pathSeparator}res');

  final Map<String, Set<String>> references =
      _collectIconReferences(root, resDir.existsSync() ? root : androidMainDir.absolute);
  final Map<String, Set<String>> available = _collectAvailableIcons(resDir);

  final List<MissingIcon> missing = <MissingIcon>[];

  for (final MapEntry<String, Set<String>> entry in references.entries) {
    final String key = entry.key;
    final int separatorIndex = key.indexOf(':');
    if (separatorIndex <= 0) {
      continue;
    }
    final String type = key.substring(0, separatorIndex);
    final String name = key.substring(separatorIndex + 1);
    final Set<String> namesForType = available[type] ?? <String>{};
    if (!namesForType.contains(name)) {
      missing.add(
        MissingIcon(
          resourceType: type,
          name: name,
          sources: Set<String>.from(entry.value),
        ),
      );
    }
  }

  missing.sort((MissingIcon a, MissingIcon b) {
    final int typeCompare = a.resourceType.compareTo(b.resourceType);
    if (typeCompare != 0) {
      return typeCompare;
    }
    return a.name.compareTo(b.name);
  });

  return IconAuditResult(missingIcons: missing, references: references);
}

//6.- _collectIconReferences inspecciona manifiestos y layouts buscando iconos usados.
Map<String, Set<String>> _collectIconReferences(Directory root, Directory base) {
  final Map<String, Set<String>> references = <String, Set<String>>{};

  if (!root.existsSync()) {
    return references;
  }

  final List<FileSystemEntity> entities = root.listSync(recursive: true);
  for (final FileSystemEntity entity in entities) {
    if (entity is! File) {
      continue;
    }
    if (!entity.path.toLowerCase().endsWith('.xml')) {
      continue;
    }
    final String content;
    try {
      content = entity.readAsStringSync();
    } on FileSystemException {
      continue;
    }

    for (final RegExpMatch match in _iconPattern.allMatches(content)) {
      final String type = match.group(1)!;
      final String name = match.group(2)!;
      final String key = '$type:$name';
      references.putIfAbsent(key, () => <String>{}).add(_relativePath(base.path, entity.path));
    }
  }

  return references;
}

//7.- _collectAvailableIcons enumera drawables y mipmaps disponibles en res/.
Map<String, Set<String>> _collectAvailableIcons(Directory resDir) {
  final Map<String, Set<String>> available = <String, Set<String>>{};
  if (!resDir.existsSync()) {
    return available;
  }

  final List<FileSystemEntity> entities = resDir.listSync(recursive: true);
  for (final FileSystemEntity entity in entities) {
    if (entity is! File) {
      continue;
    }
    final List<String> segments = entity.path.split(Platform.pathSeparator);
    if (segments.length < 2) {
      continue;
    }
    final String directoryName = segments[segments.length - 2];
    final String baseType = directoryName.split('-').first;
    if (baseType != 'drawable' && baseType != 'mipmap') {
      continue;
    }
    final String fileName = segments.last;
    final int dotIndex = fileName.lastIndexOf('.');
    final String name = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    available.putIfAbsent(baseType, () => <String>{}).add(name);
  }

  return available;
}

//8.- _relativePath normaliza la ruta de salida para hacerla legible en reportes.
String _relativePath(String basePath, String targetPath) {
  final String normalizedBase = Directory(basePath).absolute.path.replaceAll('\\', '/');
  final String normalizedTarget = File(targetPath).absolute.path.replaceAll('\\', '/');
  if (!normalizedTarget.startsWith(normalizedBase)) {
    return normalizedTarget;
  }
  String relative = normalizedTarget.substring(normalizedBase.length);
  if (relative.startsWith('/')) {
    relative = relative.substring(1);
  }
  return relative;
}
