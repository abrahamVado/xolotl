import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../providers/folio_providers.dart';
import 'folio_repository.dart';
import 'services.dart';

//1.- NotificationOrigin ayuda a identificar si el mensaje llegó en primer plano, abierto o en segundo plano.
enum NotificationOrigin { foreground, openedApp, background }

//2.- MessagingAdapter define el contrato mínimo que usamos de FirebaseMessaging para facilitar pruebas.
abstract class MessagingAdapter {
  Stream<RemoteMessage> get onForegroundMessage;
  Stream<RemoteMessage> get onMessageOpenedApp;
  Future<NotificationSettings> requestPermission({
    bool alert,
    bool announcement,
    bool badge,
    bool carPlay,
    bool criticalAlert,
    bool provisional,
    bool sound,
  });

  Future<String?> getToken();

  Future<void> setForegroundNotificationPresentationOptions({
    required bool alert,
    required bool badge,
    required bool sound,
  });
}

//3.- FirebaseMessagingAdapter conecta el platform interface oficial con nuestro contrato mínimo.
class FirebaseMessagingAdapter implements MessagingAdapter {
  FirebaseMessagingAdapter({FirebaseMessagingPlatform? platform})
      : _platform = platform ?? FirebaseMessagingPlatform.instance;

  final FirebaseMessagingPlatform _platform;

  @override
  Stream<RemoteMessage> get onForegroundMessage =>
      FirebaseMessagingPlatform.onMessage.stream;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessagingPlatform.onMessageOpenedApp.stream;

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
  }) {
    return _platform.requestPermission(
      alert: alert,
      announcement: announcement,
      badge: badge,
      carPlay: carPlay,
      criticalAlert: criticalAlert,
      provisional: provisional,
      sound: sound,
    );
  }

  @override
  Future<String?> getToken() => _platform.getToken();

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    required bool alert,
    required bool badge,
    required bool sound,
  }) {
    return _platform.setForegroundNotificationPresentationOptions(
      alert: alert,
      badge: badge,
      sound: sound,
    );
  }
}

//4.- NotificationPresenter abstrae el plugin local para poder simularlo en pruebas unitarias.
abstract class NotificationPresenter {
  Future<void> ensureInitialized(AndroidNotificationChannel channel);
  Future<void> show(NotificationPayload payload, AndroidNotificationChannel channel);
}

//5.- FlutterLocalNotificationPresenter envuelve FlutterLocalNotificationsPlugin con la configuración usada.
class FlutterLocalNotificationPresenter implements NotificationPresenter {
  FlutterLocalNotificationPresenter({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> ensureInitialized(AndroidNotificationChannel channel) async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  @override
  Future<void> show(NotificationPayload payload, AndroidNotificationChannel channel) {
    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    return _plugin.show(
      payload.hashCode,
      payload.title ?? payload.fallbackTitle,
      payload.body ?? payload.fallbackBody,
      details,
      payload: payload.encoded,
    );
  }
}

//6.- NotificationPayload normaliza el formato enviado por el backend Go para usarlo en UI y notificaciones.
class NotificationPayload {
  final String? title;
  final String? body;
  final String? folioId;
  final String? status;
  final String? type;
  final double? latitude;
  final double? longitude;
  final DateTime? timestamp;
  final Map<String, dynamic> rawData;

  NotificationPayload._({
    required this.title,
    required this.body,
    required this.folioId,
    required this.status,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.rawData,
  });

  factory NotificationPayload.fromMessage(
    RemoteMessage message,
    DateTime Function() clock,
  ) {
    final data = Map<String, dynamic>.from(message.data);
    final folioCandidate = data['folio'] ?? data['folioId'] ?? data['id'];
    final latCandidate = _parseDouble(data['latitude'] ?? data['lat']);
    final lonCandidate = _parseDouble(data['longitude'] ?? data['lng'] ?? data['lon']);
    final statusCandidate = data['status']?.toString();
    final typeCandidate = data['type']?.toString();
    final timestampSource = data['timestamp'] ?? data['updatedAt'] ?? data['createdAt'];
    final parsedTimestamp = timestampSource is String
        ? DateTime.tryParse(timestampSource)
        : null;

    return NotificationPayload._(
      title: message.notification?.title ?? data['title']?.toString(),
      body: message.notification?.body ?? data['body']?.toString(),
      folioId: folioCandidate?.toString(),
      status: statusCandidate,
      type: typeCandidate,
      latitude: latCandidate,
      longitude: lonCandidate,
      timestamp: parsedTimestamp ?? message.sentTime ?? clock(),
      rawData: data,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String get fallbackTitle => folioId != null ? 'Folio $folioId' : 'Reporte actualizado';

  String get fallbackBody =>
      status != null ? 'Estado actualizado: $status' : 'Se recibió una nueva actualización.';

  bool get hasFolio => folioId != null && folioId!.isNotEmpty;

  bool get shouldNotify => (title != null && title!.isNotEmpty) ||
      (body != null && body!.isNotEmpty) ||
      hasFolio;

  String get encoded => jsonEncode(rawData);

  FolioEntry mergeWith(FolioEntry? existing, DateTime Function() clock) {
    final reference = existing ??
        FolioEntry(
          id: folioId ?? 'unknown',
          timestamp: clock(),
          latitude: latitude ?? 0,
          longitude: longitude ?? 0,
          status: status ?? 'unknown',
          type: type ?? 'unknown',
        );

    return FolioEntry(
      id: folioId ?? reference.id,
      timestamp: timestamp ?? reference.timestamp,
      latitude: latitude ?? reference.latitude,
      longitude: longitude ?? reference.longitude,
      status: status ?? reference.status,
      type: type ?? reference.type,
    );
  }
}

//7.- NotificationService coordina permisos, listeners y actualizaciones locales cuando llega un mensaje FCM.
class NotificationService {
  NotificationService._({
    required MessagingAdapter messaging,
    required NotificationPresenter presenter,
    required FolioRepository folios,
    ProviderContainer? container,
    required DateTime Function() clock,
  })  : _messaging = messaging,
        _presenter = presenter,
        _folios = folios,
        _container = container,
        _clock = clock;

  final MessagingAdapter _messaging;
  final NotificationPresenter _presenter;
  final FolioRepository _folios;
  final ProviderContainer? _container;
  final DateTime Function() _clock;
  final List<StreamSubscription<RemoteMessage>> _subscriptions = [];

  static NotificationService? _instance;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'folio_alerts',
    'Folio updates',
    description: 'Actualizaciones de estado emitidas por el backend ciudadano.',
    importance: Importance.high,
  );

  static Future<NotificationService> initialize({
    required ProviderContainer container,
    MessagingAdapter? messaging,
    NotificationPresenter? presenter,
    FolioRepository? folios,
    DateTime Function()? clock,
  }) async {
    final service = NotificationService._(
      messaging: messaging ?? FirebaseMessagingAdapter(),
      presenter: presenter ?? FlutterLocalNotificationPresenter(),
      folios: folios ?? folioRepository,
      container: container,
      clock: clock ?? DateTime.now,
    );
    await service._configure(requestPermission: true, registerListeners: true);
    _instance?._dispose();
    _instance = service;
    return service;
  }

  static Future<NotificationService> background({
    MessagingAdapter? messaging,
    NotificationPresenter? presenter,
    FolioRepository? folios,
    DateTime Function()? clock,
  }) async {
    final service = NotificationService._(
      messaging: messaging ?? FirebaseMessagingAdapter(),
      presenter: presenter ?? FlutterLocalNotificationPresenter(),
      folios: folios ?? folioRepository,
      container: null,
      clock: clock ?? DateTime.now,
    );
    await service._configure(requestPermission: false, registerListeners: false);
    return service;
  }

  static NotificationService get instance {
    final service = _instance;
    if (service == null) {
      throw StateError('NotificationService has not been initialized');
    }
    return service;
  }

  @visibleForTesting
  static void resetForTests() {
    _instance?._dispose();
    _instance = null;
  }

  Future<void> _configure({
    required bool requestPermission,
    required bool registerListeners,
  }) async {
    await _presenter.ensureInitialized(_channel);
    if (requestPermission) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      await _messaging.getToken();
    }
    if (registerListeners) {
      _subscriptions.add(_messaging.onForegroundMessage.listen(handleForegroundMessage));
      _subscriptions.add(_messaging.onMessageOpenedApp.listen(handleOpenedMessage));
    }
  }

  Future<void> handleForegroundMessage(RemoteMessage message) async {
    await _process(message, NotificationOrigin.foreground);
  }

  Future<void> handleOpenedMessage(RemoteMessage message) async {
    await _process(message, NotificationOrigin.openedApp);
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await _process(message, NotificationOrigin.background);
  }

  Future<void> _process(RemoteMessage message, NotificationOrigin origin) async {
    final payload = NotificationPayload.fromMessage(message, _clock);
    if (origin != NotificationOrigin.background && payload.shouldNotify) {
      await _presenter.show(payload, _channel);
    }
    if (!payload.hasFolio) {
      return;
    }
    final entry = await _buildEntry(payload);
    if (entry == null) {
      return;
    }
    await _folios.saveForCurrentSession(entry);
    if (_container != null) {
      await _container!.read(folioListProvider.notifier).upsert(entry);
    }
  }

  Future<FolioEntry?> _buildEntry(NotificationPayload payload) async {
    final entries = await _folios.loadForCurrentSession();
    FolioEntry? existing;
    for (final entry in entries) {
      if (entry.id == payload.folioId) {
        existing = entry;
        break;
      }
    }
    return payload.mergeWith(existing, _clock);
  }

  void _dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}
