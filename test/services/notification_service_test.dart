import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/test.dart';

import 'package:mictlan_client/providers/folio_providers.dart';
import 'package:mictlan_client/services/folio_repository.dart';
import 'package:mictlan_client/services/notification_service.dart';
import 'package:mictlan_client/services/session_service.dart';

//1.- FakeFirebaseMessagingPlatform registra invocaciones y replica streams del plugin oficial.
class FakeFirebaseMessagingPlatform extends FirebaseMessagingPlatform {
  FakeFirebaseMessagingPlatform() : super();

  int requestPermissionCalls = 0;
  int getTokenCalls = 0;
  bool presentationOptionsSet = false;
  BackgroundMessageHandler? lastBackgroundHandler;

  @override
  FirebaseMessagingPlatform delegateFor({required FirebaseApp app}) {
    return this;
  }

  @override
  FirebaseMessagingPlatform setInitialValues({bool? isAutoInitEnabled}) {
    return this;
  }

  @override
  Future<void> registerBackgroundMessageHandler(BackgroundMessageHandler handler) async {
    lastBackgroundHandler = handler;
  }

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
  }) async {
    requestPermissionCalls++;
    return const NotificationSettings(
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.disabled,
      authorizationStatus: AuthorizationStatus.authorized,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.disabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.enabled,
      criticalAlert: AppleNotificationSetting.disabled,
      sound: AppleNotificationSetting.enabled,
    );
  }

  @override
  Future<String?> getToken({String? vapidKey, String? senderId, String? applicationVerifier}) async {
    getTokenCalls++;
    return 'fake-token';
  }

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    required bool alert,
    required bool badge,
    required bool sound,
  }) async {
    presentationOptionsSet = true;
  }
}

//2.- FakeNotificationPresenter guarda el último payload mostrado para validaciones precisas.
class FakeNotificationPresenter implements NotificationPresenter {
  bool initialized = false;
  NotificationPayload? lastPayload;
  AndroidNotificationChannel? lastChannel;

  @override
  Future<void> ensureInitialized(AndroidNotificationChannel channel) async {
    initialized = true;
    lastChannel = channel;
  }

  @override
  Future<void> show(NotificationPayload payload, AndroidNotificationChannel channel) async {
    lastPayload = payload;
    lastChannel = channel;
  }
}

void main() {
  late FakeFirebaseMessagingPlatform platform;
  late FakeNotificationPresenter presenter;
  late ProviderContainer container;
  late SessionService session;
  late FolioRepository folios;

  setUp(() {
    platform = FakeFirebaseMessagingPlatform();
    FirebaseMessagingPlatform.instance = platform;
    presenter = FakeNotificationPresenter();
    session = SessionService(storage: InMemoryTokenStorage());
    folios = FolioRepository(storage: InMemoryFolioStorage(), session: session);
    container = ProviderContainer(overrides: [
      folioRepositoryProvider.overrideWithValue(folios),
    ]);
  });

  tearDown(() {
    container.dispose();
    NotificationService.resetForTests();
  });

  test('initialize solicita permisos y obtiene el token FCM', () async {
    await NotificationService.initialize(
      container: container,
      messaging: FirebaseMessagingAdapter(platform: platform),
      presenter: presenter,
      folios: folios,
    );

    expect(platform.presentationOptionsSet, isTrue);
    expect(platform.requestPermissionCalls, 1);
    expect(platform.getTokenCalls, 1);
    expect(presenter.initialized, isTrue);
  });

  test('handleForegroundMessage muestra notificación y actualiza folios', () async {
    await session.debugSetTokenOnlyForTests(SessionToken(
      token: 'jwt',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      phone: '5551234567',
    ));

    final fixedNow = DateTime.parse('2024-05-11T12:00:00Z');
    final service = await NotificationService.initialize(
      container: container,
      messaging: FirebaseMessagingAdapter(platform: platform),
      presenter: presenter,
      folios: folios,
      clock: () => fixedNow,
    );

    final message = RemoteMessage(
      data: const <String, dynamic>{
        'folio': 'F-101',
        'status': 'investigating',
        'type': 'fire',
        'latitude': '19.4326',
        'longitude': '-99.1332',
      },
      notification: const RemoteNotification(
        title: 'Actualización de folio',
        body: 'Tu reporte cambió de estado',
      ),
      sentTime: fixedNow,
    );

    await service.handleForegroundMessage(message);

    expect(presenter.lastPayload?.folioId, 'F-101');
    expect(presenter.lastChannel?.id, 'folio_alerts');

    final stored = await folios.loadForCurrentSession();
    expect(stored, hasLength(1));
    final entry = stored.first;
    expect(entry.status, 'investigating');
    expect(entry.type, 'fire');
    expect(entry.latitude, closeTo(19.4326, 0.0001));
    expect(entry.longitude, closeTo(-99.1332, 0.0001));

    final refreshed = await container.read(folioListProvider.future);
    expect(refreshed, isNotEmpty);
    expect(refreshed.first.id, 'F-101');
  });
}
