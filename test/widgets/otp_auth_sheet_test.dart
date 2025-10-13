import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:mictlan_client/services/session_service.dart';
import 'package:mictlan_client/widgets/otp_auth_sheet.dart';

class _FakeHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw UnimplementedError();
  }
}

class _FakeSessionService extends SessionService {
  final String? initialPhone;
  bool requestSuccess;
  SessionToken? verificationResult;
  int requestCalls = 0;
  int verifyCalls = 0;
  String? lastRequestedPhone;
  String? lastVerifiedCode;

  _FakeSessionService({
    this.initialPhone,
    this.requestSuccess = true,
    this.verificationResult,
  }) : super(client: _FakeHttpClient(), storage: InMemoryTokenStorage());

  @override
  Future<String?> currentPhone() async => initialPhone;

  @override
  Future<bool> requestOtp(String phone) async {
    requestCalls++;
    lastRequestedPhone = phone;
    return requestSuccess;
  }

  @override
  Future<SessionToken?> verifyOtp(String phone, String code) async {
    verifyCalls++;
    lastRequestedPhone = phone;
    lastVerifiedCode = code;
    return verificationResult;
  }
}

void main() {
  testWidgets(
    'OtpAuthSheet completa el flujo en dos pasos y permite reintentar',
    (tester) async {
      //1.- Configuramos el servicio simulado con un teléfono previo almacenado.
      final fakeService = _FakeSessionService(initialPhone: '+5215555555555');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: OtpAuthSheet(sessionService: fakeService)),
        ),
      );

      await tester.pumpAndSettle();

      //2.- Capturamos un nuevo teléfono y solicitamos el envío del código OTP.
      await tester.enterText(find.byType(TextField).first, '+5215512345678');
      await tester.tap(find.text('Enviar código'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeService.requestCalls, 1);
      expect(fakeService.lastRequestedPhone, '+5215512345678');
      expect(find.text('Código de 6 dígitos'), findsOneWidget);
      expect(find.text('Reenviar código'), findsOneWidget);

      //3.- Probamos la acción de reenviar y la validación de código ingresado.
      await tester.tap(find.text('Reenviar código'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeService.requestCalls, 2);

      await tester.enterText(
        find.bySemanticsLabel('Código de 6 dígitos'),
        '123456',
      );
      await tester.tap(find.text('Validar código'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeService.verifyCalls, 1);
      expect(fakeService.lastVerifiedCode, '123456');
      expect(find.text('Código inválido, intenta nuevamente.'), findsOneWidget);
    },
  );
}
