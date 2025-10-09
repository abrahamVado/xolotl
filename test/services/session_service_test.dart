import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xolotl/services/session_service.dart';

void main() {
  group('SessionService', () {
    test('verifyOtp stores token and exposes it until expiration', () async {
      final now = DateTime.parse('2024-01-01T00:00:00Z');
      final responses = <String, http.Response>{
        '/api/v1/auth/otp/request': http.Response('', 202),
        '/api/v1/auth/otp/verify': http.Response(
          jsonEncode({
            'token': 'abc123',
            'expiresAt': now.add(const Duration(minutes: 5)).toIso8601String(),
            'role': 'citizen',
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      };
      final client = MockClient((request) async =>
          responses[request.url.path] ?? http.Response('not found', 404));
      final storage = InMemoryTokenStorage();
      final service = SessionService(
        client: client,
        storage: storage,
        clock: () => now,
      );

      final requestOk = await service.requestOtp('+521234567890');
      expect(requestOk, isTrue);

      final token = await service.verifyOtp('+521234567890', '000000');
      expect(token, isNotNull);
      expect(token!.token, 'abc123');
      expect(await service.hasValidToken(), isTrue);
      expect(await service.currentPhone(), '+521234567890');

      final futureService = SessionService(
        client: client,
        storage: storage,
        clock: () => now.add(const Duration(minutes: 10)),
      );
      expect(await futureService.hasValidToken(), isFalse);
    });
  });
}
