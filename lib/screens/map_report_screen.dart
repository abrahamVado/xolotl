
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import '../services/api.dart';
import '../services/services.dart';
import '../services/google_maps_availability.dart';
import '../services/session_service.dart';
import '../widgets/report_type_overlay.dart';
import '../widgets/otp_auth_sheet.dart';
import '../widgets/report_details_dialog.dart';

class MapReportScreen extends StatefulWidget {
  final ApiService? api;
  final SessionService? session;
  final ValueChanged<String>? onReportTypeSelected;

  const MapReportScreen({
    super.key,
    this.api,
    this.session,
    this.onReportTypeSelected,
  });

  @override
  State<MapReportScreen> createState() => _MapReportScreenState();
}

class _MapReportScreenState extends State<MapReportScreen> {
  //1.- _controller gestiona la instancia del mapa de Google.
  final Completer<GoogleMapController> _controller = Completer();
  //2.- _selected retiene la coordenada elegida por la persona usuaria.
  LatLng? _selected;
  //3.- _types alimenta el menú con los tipos de incidentes disponibles.
  List<Map<String, dynamic>> _types = [];
  //4.- _loading indica si los datos iniciales aún se están obteniendo.
  bool _loading = true;
  //5.- _introAcknowledged controla si la introducción ya fue aceptada.
  bool _introAcknowledged = false;
  //6.- _pendingLatLng preserva la coordenada mientras la persona elige el tipo.
  LatLng? _pendingLatLng;
  //7.- _showTypePicker activa la superposición flotante con los botones shadcn.
  bool _showTypePicker = false;
  //8.- _mapAvailable determina si Google Maps está listo para mostrarse.
  bool _mapAvailable = true;

  //9.- _api expone la dependencia inyectable o recurre al singleton global.
  ApiService get _api => widget.api ?? apiService;
  //10.- _session expone la sesión inyectada para pruebas o la global.
  SessionService get _session => widget.session ?? sessionService;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  //11.- _initialize sincroniza la disponibilidad del mapa y los tipos de reporte.
  Future<void> _initialize() async {
    final results = await Future.wait<dynamic>([
      GoogleMapsAvailability.instance.isConfigured(),
      _api.getIncidentTypes(),
    ]);
    if (!mounted) return;
    final available = results[0] as bool;
    final data = results[1] as List<Map<String, dynamic>>;
    setState(() {
      _mapAvailable = available;
      _types = data.isEmpty
          ? [
              {'id': 'pothole', 'name': 'Pothole', 'emoji': '🕳️'},
              {'id': 'light', 'name': 'Street Light', 'emoji': '💡'},
              {'id': 'trash', 'name': 'Trash', 'emoji': '🗑️'},
              {'id': 'water', 'name': 'Water Leak', 'emoji': '💧'},
            ]
          : data;
      _loading = false;
    });
  }

  //12.- _ensureSession verifica que exista token ciudadano antes de reportar.
  Future<bool> _ensureSession() async {
    if (await _session.hasValidToken()) {
      return true;
    }
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OtpAuthSheet(),
    );
    return ok == true;
  }

  //13.- _onTap guarda la coordenada seleccionada y despliega la superposición.
  void _onTap(LatLng latLng) async {
    setState(() {
      _selected = latLng;
      _pendingLatLng = latLng;
      _showTypePicker = true;
    });
  }

  //14.- _cancelTypeSelection cierra el menú flotante sin continuar el flujo.
  void _cancelTypeSelection() {
    setState(() {
      _showTypePicker = false;
      _pendingLatLng = null;
    });
  }

  //15.- _handleTypeSelected continúa el flujo de reporte tras elegir la categoría.
  Future<void> _handleTypeSelected(String type) async {
    final latLng = _pendingLatLng;
    setState(() {
      _showTypePicker = false;
      _pendingLatLng = null;
    });
    if (latLng == null || !mounted) {
      return;
    }
    widget.onReportTypeSelected?.call(type);
    if (!await _ensureSession()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Necesitas verificar tu teléfono.')));
      return;
    }
    final phone = await _session.currentPhone();
    if (phone == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No encontramos tu sesión activa.')));
      return;
    }
    final result = await showDialog<ReportDetailsResult>(
      context: context,
      builder: (_) => ReportDetailsDialog(phone: phone),
    );
    if (result == null) return;
    final res = await _api.submitReport(
      incidentTypeId: type,
      description: result.description,
      contactEmail: result.email,
      lat: latLng.latitude,
      lng: latLng.longitude,
      address: result.address,
    );
    if (!mounted) return;
    if (res != null) {
      final folio = res['folio'] ?? 'unknown';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report sent. Folio: $folio')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to send report')));
    }
  }

  //16.- _acknowledgeIntro registra la interacción con la pantalla inicial.
  void _acknowledgeIntro() {
    setState(() => _introAcknowledged = true);
  }

  //17.- _retryMapAvailability solicita nuevamente la verificación del API key.
  Future<void> _retryMapAvailability() async {
    final available = await GoogleMapsAvailability.instance.isConfigured();
    if (!mounted) return;
    setState(() {
      _mapAvailable = available;
    });
  }

  @override
  Widget build(BuildContext context) {
    //18.- build muestra la intro estilo shadcn_flutter antes del mapa.
    if (!_introAcknowledged) {
      final colorScheme = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: colorScheme.surfaceContainerHighest,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _IntroView(onContinue: _acknowledgeIntro),
            ),
          ),
        ),
      );
    }
    if (!_mapAvailable) {
      final colorScheme = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: colorScheme.surfaceContainerHighest,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _MapUnavailableView(onRetry: _retryMapAvailability),
            ),
          ),
        ),
      );
    }
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(target: LatLng(19.4326, -99.1332), zoom: 12),
          onMapCreated: (c) => _controller.complete(c),
          onTap: _onTap,
          markers: _selected == null
              ? {}
              : {
                  Marker(markerId: const MarkerId('selected'), position: _selected!),
                },
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
        ),
        if (_loading)
          const Positioned(
            top: 50,
            right: 20,
            child: CircularProgressIndicator(),
          ),
        if (_showTypePicker)
          Positioned.fill(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _cancelTypeSelection,
                  behavior: HitTestBehavior.opaque,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: ReportTypeOverlay(
                      types: _types,
                      onSelected: _handleTypeSelected,
                      onDismiss: _cancelTypeSelection,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

//19.- _IntroView encapsula la tarjeta de bienvenida con componentes shadcn.
class _IntroView extends StatelessWidget {
  //20.- onContinue propaga el cierre de la introducción hacia la pantalla padre.
  final VoidCallback onContinue;

  const _IntroView({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    //21.- theme centraliza tipografías y colores calculados por Flutter.
    final theme = Theme.of(context);
    //22.- colorScheme reduce accesos repetidos al esquema cromático.
    final colorScheme = theme.colorScheme;
    return shad.SurfaceCard(
      key: const Key('map-intro-card'),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      filled: true,
      fillColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      borderColor: colorScheme.outlineVariant,
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withOpacity(0.08),
          blurRadius: 28,
          offset: const Offset(0, 18),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          shad.SurfaceCard(
            padding: const EdgeInsets.all(20),
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            borderColor: colorScheme.outlineVariant.withOpacity(0.4),
            child: const Icon(
              Icons.assistant_navigation,
              size: 72,
            ),
          ),
          const SizedBox(height: 32),
          shad.Text(
            'Reporta incidencias en tu ciudad',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          shad.Text(
            'Selecciona un punto en el mapa para comenzar tu reporte ciudadano.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: shad.PrimaryButton(
              onPressed: onContinue,
              density: shad.ButtonDensity.comfortable,
              shape: shad.ButtonShape.rectangle,
              child: const shad.Text('Click to continue'),
            ),
          ),
        ],
      ),
    );
  }
}

//23.- _MapUnavailableView muestra instrucciones cuando falta el API key de Google Maps.
class _MapUnavailableView extends StatelessWidget {
  //24.- onRetry vuelve a solicitar la verificación del API key configurado.
  final VoidCallback onRetry;

  const _MapUnavailableView({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    //25.- theme reutiliza las tipografías configuradas por Material 3.
    final theme = Theme.of(context);
    //26.- colorScheme unifica los colores dentro del contenedor de información.
    final colorScheme = theme.colorScheme;
    return shad.SurfaceCard(
      key: const Key('map-unavailable-card'),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      filled: true,
      fillColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      borderColor: colorScheme.outlineVariant,
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withOpacity(0.08),
          blurRadius: 28,
          offset: const Offset(0, 20),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.map_outlined, size: 60),
          const SizedBox(height: 24),
          shad.Text(
            'Configura Google Maps',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          shad.Text(
            'Agrega tu API key de Android en local.properties como MAPS_API_KEY '
            'o exporta la variable de entorno MAPS_API_KEY antes de compilar.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          shad.Text(
            'Después vuelve a intentar para cargar el mapa ciudadano.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          shad.PrimaryButton(
            onPressed: onRetry,
            density: shad.ButtonDensity.comfortable,
            shape: shad.ButtonShape.rectangle,
            child: const shad.Text('Reintentar detección'),
          ),
        ],
      ),
    );
  }
}
