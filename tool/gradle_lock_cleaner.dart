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

//4.- _buildParser configura los argumentos necesarios para el comando.
ArgParser _buildParser() {
  return ArgParser()
    ..addOption(
      'lock',
      abbr: 'l',
      help: 'Path to the Gradle journal lock file (journal-1.lock).',
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

//5.- _parseDuration valida la duración ingresada por la persona usuaria.
Duration? _parseDuration(String rawMinutes) {
  final minutes = int.tryParse(rawMinutes);
  if (minutes == null || minutes <= 0) {
    return null;
  }
  return Duration(minutes: minutes);
}

//6.- main procesa argumentos, ejecuta la limpieza y muestra mensajes guía.
Future<void> main(List<String> arguments) async {
  final parser = _buildParser();
  final result = parser.parse(arguments);

  final lockPath = result['lock'] as String?;
  if (lockPath == null || lockPath.isEmpty) {
    stderr.writeln('Missing required --lock option.');
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
