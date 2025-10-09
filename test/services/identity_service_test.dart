import 'dart:collection';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:xolotl/services/identity.dart';

class FakeIdentityStorage implements IdentityStorage {
  FakeIdentityStorage({this.stored});

  String? stored;
  bool writeCalled = false;

  @override
  Future<String?> read() async {
    //1.- Devuelve el contenido simulado previamente persistido.
    return stored;
  }

  @override
  Future<void> write(String value) async {
    //2.- Registra la escritura y conserva el valor para validaciones posteriores.
    writeCalled = true;
    stored = value;
  }
}

class FakeDeviceSummaryProvider implements DeviceSummaryProvider {
  const FakeDeviceSummaryProvider(this.value);

  final String value;

  @override
  Future<String> summary() async {
    //1.- Regresa el resumen de dispositivo predefinido para la prueba.
    return value;
  }
}

class SequenceUuid extends Uuid {
  SequenceUuid(List<String> values) : _values = ListQueue.of(values);

  final ListQueue<String> _values;

  @override
  String v4({Map<String, dynamic>? config}) {
    //1.- Entrega los valores secuenciales configurados en la prueba.
    return _values.removeFirst();
  }
}

class FakeDeviceInfoPlugin extends DeviceInfoPlugin {
  FakeDeviceInfoPlugin(this.info);

  final AndroidDeviceInfo info;

  @override
  Future<AndroidDeviceInfo> get androidInfo async {
    //1.- Devuelve la información simulada para validar el resumen generado.
    return info;
  }
}

void main() {
  group('Identity.ensureIdentity', () {
    test('returns stored identity when available', () async {
      //1.- Configura un almacenamiento con identidad previa serializada.
      final storedData = jsonEncode({
        'clientId': 'client-1',
        'deviceSummary': 'Acme One (abc)',
        'username': 'user1',
        'password': 'pass1',
      });
      final storage = FakeIdentityStorage(stored: storedData);

      //2.- Ejecuta ensureIdentity y valida que respete la información guardada.
      final identity = await Identity.ensureIdentity(
        storage: storage,
        deviceSummaryProvider: const FakeDeviceSummaryProvider('Should not be used'),
        uuid: SequenceUuid(['unused-a', 'unused-b']),
      );

      //3.- Comprueba que no se haya intentado sobrescribir la identidad existente.
      expect(identity.clientId, 'client-1');
      expect(identity.deviceSummary, 'Acme One (abc)');
      expect(identity.username, 'user1');
      expect(identity.password, 'pass1');
      expect(storage.writeCalled, isFalse);
    });

    test('creates and persists identity when missing', () async {
      //1.- Declara dobles de prueba para generar valores deterministas.
      final storage = FakeIdentityStorage();
      final uuid = SequenceUuid(['uuid-a', 'uuid-b']);
      const summaryProvider = FakeDeviceSummaryProvider('Acme Pro (xyz)');

      //2.- Solicita la identidad y valida que se construya a partir de los colaboradores.
      final identity = await Identity.ensureIdentity(
        storage: storage,
        deviceSummaryProvider: summaryProvider,
        uuid: uuid,
      );

      //3.- Verifica que la información se haya persistido y que los campos sigan el formato esperado.
      expect(identity.clientId, 'uuid-a');
      expect(identity.deviceSummary, 'Acme Pro (xyz)');
      expect(identity.username, 'u_uuid-a');
      expect(identity.password, 'uuid-b');
      expect(storage.writeCalled, isTrue);

      final persisted = jsonDecode(storage.stored!) as Map<String, dynamic>;
      expect(persisted['clientId'], 'uuid-a');
      expect(persisted['deviceSummary'], 'Acme Pro (xyz)');
      expect(persisted['username'], 'u_uuid-a');
      expect(persisted['password'], 'uuid-b');
    });
  });

  group('AndroidDeviceSummaryProvider', () {
    test('uses injected plugin to build summary', () async {
      //1.- Construye un AndroidDeviceInfo controlado para verificar la salida.
      final info = AndroidDeviceInfo.fromMap({
        'version': {
          'baseOS': null,
          'codename': 'REL',
          'incremental': '1',
          'previewSdkInt': 0,
          'release': '14',
          'sdkInt': 34,
          'securityPatch': '2024-01-01',
        },
        'board': 'acme',
        'bootloader': 'boot-1',
        'brand': 'Acme',
        'device': 'omega',
        'display': 'display',
        'fingerprint': 'fingerprint',
        'hardware': 'hardware',
        'host': 'host',
        'id': 'XYZ123',
        'manufacturer': 'Acme Corp',
        'model': 'Omega',
        'product': 'omega',
        'supported32BitAbis': <String>[],
        'supported64BitAbis': <String>[],
        'supportedAbis': <String>[],
        'tags': 'tags',
        'type': 'user',
        'isPhysicalDevice': true,
        'systemFeatures': <String>[],
        'serialNumber': 'serial',
        'isLowRamDevice': false,
      });

      //2.- Inyecta el plugin falso para asegurar que el proveedor lo use directamente.
      final provider = AndroidDeviceSummaryProvider(plugin: FakeDeviceInfoPlugin(info));

      //3.- Ejecuta summary y valida que utilice los campos relevantes del dispositivo.
      final summary = await provider.summary();
      expect(summary, 'Acme Omega (XYZ123)');
    });
  });
}
