
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import '../services/api.dart';
import '../services/folio_repository.dart';
import '../services/services.dart';
import '../services/google_maps_availability.dart';
import '../services/session_service.dart';
import '../widgets/report_type_overlay.dart';
import '../widgets/otp_auth_sheet.dart';
import '../widgets/report_details_dialog.dart';
import '../providers/folio_providers.dart';

class MapReportScreen extends ConsumerStatefulWidget {
  final ApiService? api;
  final SessionService? session;
  final FolioRepository? folios;
  final ValueChanged<String>? onReportTypeSelected;
  final LatLng? initialTarget;

  const MapReportScreen({
    super.key,
    this.api,
    this.session,
    this.folios,
    this.onReportTypeSelected,
    this.initialTarget,
  });

  @override
  ConsumerState<MapReportScreen> createState() => _MapReportScreenState();
}

class _MapReportScreenState extends ConsumerState<MapReportScreen> {
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
  //9.- _folioEntries contiene los folios cargados desde el repositorio.
  List<FolioEntry> _folioEntries = const [];
  //10.- _markers mantiene todos los marcadores renderizados en el mapa.
  Set<Marker> _markers = <Marker>{};
  //11.- _focusedInitialTarget evita re-centrar el mapa múltiples veces.
  bool _focusedInitialTarget = false;

  //12.- _api expone la dependencia inyectable o recurre al singleton global.
  ApiService get _api => widget.api ?? apiService;
  //13.- _session expone la sesión inyectada para pruebas o la global.
  SessionService get _session => widget.session ?? sessionService;
  //14.- _folioRepo centraliza el repositorio encargado de persistir folios.
  FolioRepository get _folioRepo => widget.folios ?? folioRepository;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  //15.- _initialize sincroniza la disponibilidad del mapa y los tipos de reporte.
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
              {
                'id': 'pothole',
                'name': 'Pothole',
                'emoji': '🕳️',
                'reportType': 'pothole',
              },
              {
                'id': 'light',
                'name': 'Street Light',
                'emoji': '💡',
                'reportType': 'light',
              },
              {
                'id': 'trash',
                'name': 'Trash',
                'emoji': '🗑️',
                'reportType': 'trash',
              },
              {
                'id': 'water',
                'name': 'Water Leak',
                'emoji': '💧',
                'reportType': 'water',
              },
            ]
          : data;
      _loading = false;
    });
    await _loadStoredFolios();
  }

  //16.- _loadStoredFolios restaura los marcadores persistidos en la sesión.
  Future<void> _loadStoredFolios() async {
    final entries = await _folioRepo.loadForCurrentSession();
    if (!mounted) return;
    setState(() {
      final selection = widget.initialTarget ?? _selected;
      _selected = selection;
      _folioEntries = entries;
      _markers = _buildMarkers(selectionOverride: selection);
    });
    await _focusInitialTarget();
  }

  //17.- _buildMarkers compone el conjunto de marcadores a mostrar en el mapa.
  Set<Marker> _buildMarkers({LatLng? selectionOverride}) {
    final markers = <Marker>{};
    for (final entry in _folioEntries) {
      markers.add(
        Marker(
          markerId: MarkerId('folio-${entry.id}'),
          position: LatLng(entry.latitude, entry.longitude),
          infoWindow: InfoWindow(title: entry.id, snippet: entry.type),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
    final selection = selectionOverride ?? _selected;
    if (selection != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: selection,
        ),
      );
    }
    return markers;
  }

  //18.- _focusInitialTarget centra la cámara cuando proviene desde la consulta.
  Future<void> _focusInitialTarget() async {
    if (_focusedInitialTarget) return;
    final target = widget.initialTarget;
    if (target == null) return;
    final controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
    _focusedInitialTarget = true;
  }

  //19.- _ensureSession verifica que exista token ciudadano antes de reportar.
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

  //20.- _onTap guarda la coordenada seleccionada y despliega la superposición.
  void _onTap(LatLng latLng) async {
    setState(() {
      _selected = latLng;
      _pendingLatLng = latLng;
      _showTypePicker = true;
      _markers = _buildMarkers(selectionOverride: latLng);
    });
  }

  //21.- _cancelTypeSelection cierra el menú flotante sin continuar el flujo.
  void _cancelTypeSelection() {
    setState(() {
      _showTypePicker = false;
      _pendingLatLng = null;
    });
  }

  //22.- _handleTypeSelected continúa el flujo de reporte tras elegir la categoría.
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
    final entry = await _api.submitReport(
      incidentTypeId: type,
      description: result.description,
      contactEmail: result.email,
      lat: latLng.latitude,
      lng: latLng.longitude,
      address: result.address,
    );
    if (!mounted) return;
    if (entry != null) {
      setState(() {
        final updated = List<FolioEntry>.from(_folioEntries);
        final index = updated.indexWhere((e) => e.id == entry.id);
        if (index >= 0) {
          updated[index] = entry;
        } else {
          updated.add(entry);
          updated.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
        _folioEntries = updated;
        _selected = null;
        _markers = _buildMarkers();
      });
      await ref.read(folioListProvider.notifier).refresh();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Report sent. Folio: ${entry.id}')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to send report')));
    }
  }

  //23.- _acknowledgeIntro registra la interacción con la pantalla inicial.
  void _acknowledgeIntro() {
    setState(() => _introAcknowledged = true);
  }

  //24.- _retryMapAvailability solicita nuevamente la verificación del API key.
  Future<void> _retryMapAvailability() async {
    final available = await GoogleMapsAvailability.instance.isConfigured();
    if (!mounted) return;
    setState(() {
      _mapAvailable = available;
    });
  }

  @override
  Widget build(BuildContext context) {
    //25.- build muestra la intro estilo shadcn_flutter antes del mapa.
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
          initialCameraPosition:
              const CameraPosition(target: LatLng(18.0010, -94.5597), zoom: 12.5),
          onMapCreated: (c) => _controller.complete(c),
          onTap: _onTap,
          markers: _markers,
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

//26.- _IntroView encapsula la tarjeta de bienvenida con componentes shadcn.
class _IntroView extends StatelessWidget {
  //27.- onContinue propaga el cierre de la introducción hacia la pantalla padre.
  final VoidCallback onContinue;

  const _IntroView({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    //28.- theme centraliza tipografías y colores calculados por Flutter.
    final theme = Theme.of(context);
    //29.- colorScheme reduce accesos repetidos al esquema cromático.
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

//30.- _MapUnavailableView muestra instrucciones cuando falta el API key de Google Maps.
class _MapUnavailableView extends StatelessWidget {
  //31.- onRetry vuelve a solicitar la verificación del API key configurado.
  final VoidCallback onRetry;

  const _MapUnavailableView({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    //32.- theme reutiliza las tipografías configuradas por Material 3.
    final theme = Theme.of(context);
    //33.- colorScheme unifica los colores dentro del contenedor de información.
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
