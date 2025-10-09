import 'dart:io';
import 'dart:typed_data';

Future<void> main(List<String> args) async {
  //1.- Definimos la ruta destino del wrapper y salimos temprano si ya existe.
  final jarFile = File('android/gradle/wrapper/gradle-wrapper.jar');
  if (jarFile.existsSync()) {
    //2.- Informamos que no es necesario descargar de nuevo el wrapper.
    stdout.writeln('Gradle wrapper jar already present.');
    return;
  }

  //3.- Leemos la versión configurada en gradle-wrapper.properties.
  final propertiesFile =
      File('android/gradle/wrapper/gradle-wrapper.properties');
  if (!propertiesFile.existsSync()) {
    //4.- Abortamos con un mensaje claro cuando falta la configuración.
    stderr.writeln('gradle-wrapper.properties is missing.');
    exitCode = 1;
    return;
  }
  final distributionLine = propertiesFile
      .readAsLinesSync()
      .firstWhere(
        (line) => line.startsWith('distributionUrl='),
        orElse: () => '',
      )
      .replaceFirst('distributionUrl=', '');
  if (distributionLine.isEmpty) {
    //5.- Rechazamos continuar si no encontramos la URL de distribución.
    stderr.writeln('distributionUrl not found in gradle-wrapper.properties');
    exitCode = 1;
    return;
  }

  //6.- Calculamos la versión que usaremos para armar las URLs candidatas.
  final versionMatch = RegExp(r'gradle-([\d.]+)-').firstMatch(distributionLine);
  if (versionMatch == null) {
    //7.- Explicamos el fallo cuando la expresión regular no coincide.
    stderr.writeln('Unable to determine Gradle version from $distributionLine');
    exitCode = 1;
    return;
  }
  final version = versionMatch.group(1)!;

  //8.- Definimos las URLs candidatas para obtener el jar.
  final candidateUrls = <Uri>[
    Uri.parse(
        'https://raw.githubusercontent.com/gradle/gradle/v$version/gradle/wrapper/gradle-wrapper.jar'),
  ];
  if (version.split('.').length == 2) {
    candidateUrls.add(Uri.parse(
        'https://raw.githubusercontent.com/gradle/gradle/v${version}.0/gradle/wrapper/gradle-wrapper.jar'));
  }

  //9.- Descargamos el jar probando cada URL hasta encontrar una respuesta válida.
  final client = HttpClient();
  client.userAgent = 'xolotl-gradle-wrapper-fetcher';
  try {
    bool downloaded = false;
    for (final url in candidateUrls) {
      final request = await client.getUrl(url);
      final response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        await jarFile.parent.create(recursive: true);
        await jarFile.writeAsBytes(bytes);
        stdout.writeln('Downloaded Gradle wrapper from ${url.toString()}');
        downloaded = true;
        break;
      }
    }
    if (!downloaded) {
      //10.- Avisamos que ninguna URL funcionó para que el desarrollador investigue.
      stderr.writeln(
          'Unable to download gradle-wrapper.jar. Update the script with a valid source.');
      exitCode = 1;
    }
  } on SocketException catch (error) {
    //11.- Documentamos los errores de red y sugerimos revisar la conexión.
    stderr.writeln('Network error while downloading gradle-wrapper.jar: $error');
    exitCode = 1;
  } finally {
    client.close();
  }
}

//12.- Utilidad tomada de flutter foundation para leer toda la respuesta HTTP.
Future<List<int>> consolidateHttpClientResponseBytes(
  HttpClientResponse response, {
  int expectedContentLength = 0,
}) async {
  //1.- Reutilizamos un buffer que crece según llegan los chunks.
  final chunks = <List<int>>[];
  //2.- Seguimos la longitud esperada únicamente para reservar memoria.
  var contentLength = expectedContentLength;
  if (contentLength < 0) {
    contentLength = 0;
  }
  //3.- Vamos acumulando los bytes de la respuesta.
  await for (final chunk in response) {
    chunks.add(chunk);
    contentLength += chunk.length;
  }
  //4.- Combinamos todos los chunks en un solo arreglo final.
  return Uint8List(contentLength)
    ..setAll(0, chunks.expand((chunk) => chunk));
}
