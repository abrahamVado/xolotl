import 'dart:io';

import 'package:args/args.dart';

//1.- LockCleanOutcome enum describe los posibles resultados al revisar un candado.
enum LockCleanOutcome { deleted, skippedFresh, skippedMissing }

//2.- LockCleaner encapsula la lógica para decidir si se elimina el candado.
class LockCleaner {
  final DateTime Function() _clock;
  final Future<void> Function(File file) _delete;

  LockCleaner({DateTime Function()? clock, Future<void> Function(File file)? delete})
      : _clock = clock ?? DateTime.now,
        _delete = delete ?? ((file) => file.delete());

  //3.- clean revisa la edad del archivo y ejecuta la eliminación cuando aplica.
  Future<LockCleanOutcome> clean(File lockFile, Duration maxAge) async {
    if (!lockFile.existsSync()) {
      return LockCleanOutcome.skippedMissing;
    }

    final lastModified = lockFile.lastModifiedSync();
    final age = _clock().difference(lastModified);
    if (age < maxAge) {
      return LockCleanOutcome.skippedFresh;
    }

    await _delete(lockFile);
    return LockCleanOutcome.deleted;
  }
}

//4.- _trimTrailingSeparator elimina separadores repetidos al final de la ruta base.
String _trimTrailingSeparator(String base, String separator) {
  var sanitized = base;
  while (sanitized.endsWith(separator)) {
    sanitized = sanitized.substring(0, sanitized.length - separator.length);
  }
  return sanitized;
}

//5.- _joinPath agrega segmentos cuidando el separador según el sistema operativo.
String _joinPath(String base, List<String> segments, bool isWindows) {
  final separator = isWindows ? '\\' : '/';
  final buffer = StringBuffer(_trimTrailingSeparator(base, separator));
  for (final segment in segments) {
    buffer
      ..write(separator)
      ..write(segment);
  }
  return buffer.toString();
}

//6.- resolveDefaultLockPath calcula la ruta al candado usando variables de entorno comunes.
String? resolveDefaultLockPath(Map<String, String> environment, {bool? treatAsWindows}) {
  final isWindows = treatAsWindows ?? Platform.isWindows;
  String? _chooseBase(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  final gradleHome = _chooseBase(environment['GRADLE_USER_HOME']);
  if (gradleHome != null) {
    return _joinPath(gradleHome, const ['caches', 'journal-1', 'journal-1.lock'], isWindows);
  }

  final userProfile = _chooseBase(environment['USERPROFILE']);
  if (userProfile != null) {
    final gradleDir = _joinPath(userProfile, const ['.gradle'], isWindows);
    return _joinPath(gradleDir, const ['caches', 'journal-1', 'journal-1.lock'], isWindows);
  }

  final home = _chooseBase(environment['HOME']);
  if (home != null) {
    final gradleDir = _joinPath(home, const ['.gradle'], isWindows);
    return _joinPath(gradleDir, const ['caches', 'journal-1', 'journal-1.lock'], isWindows);
  }

  return null;
}

//7.- _buildParser configura los argumentos necesarios para el comando.
ArgParser _buildParser() {
  return ArgParser()
    ..addOption(
      'lock',
      abbr: 'l',
      help:
          'Path to the Gradle journal lock file (journal-1.lock). Defaults to the user Gradle directory when omitted.',
      valueHelp: 'path',
    )
    ..addOption(
      'max-age-minutes',
      abbr: 'm',
      help: 'Minutes before a lock is considered stale.',
      valueHelp: 'minutes',
      defaultsTo: '10',
    );
}

//8.- _parseDuration valida la duración ingresada por la persona usuaria.
Duration? _parseDuration(String rawMinutes) {
  final minutes = int.tryParse(rawMinutes);
  if (minutes == null || minutes <= 0) {
    return null;
  }
  return Duration(minutes: minutes);
}

//9.- main procesa argumentos, ejecuta la limpieza y muestra mensajes guía.
Future<void> main(List<String> arguments) async {
  final parser = _buildParser();
  final result = parser.parse(arguments);

  final providedLock = result['lock'] as String?;
  final lockPath =
      (providedLock != null && providedLock.isNotEmpty) ? providedLock : resolveDefaultLockPath(Platform.environment);
  if (lockPath == null || lockPath.isEmpty) {
    stderr.writeln('Unable to determine the Gradle lock path. Provide it with --lock.');
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final duration = _parseDuration(result['max-age-minutes'] as String);
  if (duration == null) {
    stderr.writeln('The --max-age-minutes option must be a positive integer.');
    exitCode = 64;
    return;
  }

  final cleaner = LockCleaner();
  final outcome = await cleaner.clean(File(lockPath), duration);

  switch (outcome) {
    case LockCleanOutcome.deleted:
      stdout.writeln('Removed stale Gradle lock at $lockPath.');
      exitCode = 0;
      break;
    case LockCleanOutcome.skippedFresh:
      stdout.writeln('Gradle lock at $lockPath is still recent; no action taken.');
      exitCode = 0;
      break;
    case LockCleanOutcome.skippedMissing:
      stdout.writeln('Gradle lock at $lockPath was not found.');
      exitCode = 0;
      break;
  }
}
