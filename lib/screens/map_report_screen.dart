
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import '../services/api.dart';
import '../services/folio_repository.dart';
import '../services/location_service.dart';
import '../services/services.dart';
import '../services/google_maps_availability.dart';
import '../services/session_service.dart';
import '../widgets/report_type_overlay.dart';
import '../widgets/otp_auth_sheet.dart';
import '../widgets/report_details_dialog.dart';
import '../widgets/map_report_components.dart';
import '../providers/folio_providers.dart';

class MapReportScreen extends ConsumerStatefulWidget {
  final ApiService? api;
  final SessionService? session;
  final FolioRepository? folios;
  final ValueChanged<String>? onReportTypeSelected;
  final LocationService? location;
  final LatLng? initialTarget;

  const MapReportScreen({
    super.key,
    this.api,
    this.session,
    this.folios,
    this.onReportTypeSelected,
    this.location,
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
  //12.- _locatingUser indica si se está centrando el mapa en la ubicación actual.
  bool _locatingUser = false;
  //12.1.- _autoCenteredOnIntro evita repetir el centrado automático inicial.
  bool _autoCenteredOnIntro = false;

  //13.- _api expone la dependencia inyectable o recurre al singleton global.
  ApiService get _api => widget.api ?? apiService;
  //14.- _session expone la sesión inyectada para pruebas o la global.
  SessionService get _session => widget.session ?? sessionService;
  //15.- _folioRepo centraliza el repositorio encargado de persistir folios.
  FolioRepository get _folioRepo => widget.folios ?? folioRepository;
  //16.- _locationService abstrae el origen de datos de geoubicación.
  LocationService get _locationService => widget.location ?? locationService;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  //17.- _initialize sincroniza la disponibilidad del mapa y los tipos de reporte.
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

  //18.- _loadStoredFolios restaura los marcadores persistidos en la sesión.
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

  //19.- _buildMarkers compone el conjunto de marcadores a mostrar en el mapa.
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
    //19.1.- Al existir selección agregamos un marcador con instrucciones visibles.
    if (selection != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: selection,
          infoWindow: InfoWindow(
            title: 'Punto seleccionado',
            snippet: 'Usa el botón “Comenzar reporte” para continuar.',
            onTap: _openTypePickerFromMarker,
          ),
          onTap: _openTypePickerFromMarker,
          consumeTapEvents: true,
        ),
      );
    }
    return markers;
  }

  //19.1.- _openTypePickerFromMarker reactiva el selector tras tocar el marcador.
  void _openTypePickerFromMarker() {
    setState(() {
      _pendingLatLng ??= _selected;
      _showTypePicker = true;
    });
  }

  //20.- _focusInitialTarget centra la cámara cuando proviene desde la consulta.
  Future<void> _focusInitialTarget() async {
    if (_focusedInitialTarget) return;
    final target = widget.initialTarget;
    if (target == null) return;
    final controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
    _focusedInitialTarget = true;
  }

  //20.1.- _onMapCreated registra el controlador y dispara el centrado inicial.
  void _onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }
    _attemptInitialAutoCenter();
  }

  //20.2.- _attemptInitialAutoCenter lanza el flujo para ubicar a la persona usuaria.
  void _attemptInitialAutoCenter() {
    if (!_introAcknowledged) return;
    if (_autoCenteredOnIntro) return;
    if (!_controller.isCompleted) return;
    _autoCenteredOnIntro = true;
    unawaited(_goToCurrentLocation());
  }

  //21.- _goToCurrentLocation anima la cámara hacia la posición ciudadana.
  Future<void> _goToCurrentLocation() async {
    setState(() => _locatingUser = true);
    LatLng? current;
    try {
      current = await _locationService.currentLocation();
    } catch (_) {
      current = null;
    }
    if (!mounted) {
      return;
    }
    if (current == null) {
      setState(() => _locatingUser = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible obtener tu ubicación actual.')),
      );
      return;
    }
    if (!_controller.isCompleted) {
      setState(() => _locatingUser = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El mapa se está inicializando. Intenta nuevamente.')),
      );
      return;
    }
    final controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newLatLngZoom(current, 17));
    if (!mounted) {
      return;
    }
    setState(() {
      _locatingUser = false;
      _selected = current;
      _markers = _buildMarkers(selectionOverride: current);
    });
  }

  //22.- _ensureSession verifica que exista token ciudadano antes de reportar.
  Future<bool> _ensureSession() async {
    if (await _session.hasValidToken()) {
      return true;
    }
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OtpAuthSheet(),
    );
    return ok == true;
  }

  //23.- _onTap guarda la coordenada seleccionada y despliega la superposición.
  void _onTap(LatLng latLng) async {
    setState(() {
      _selected = latLng;
      _pendingLatLng = latLng;
      _showTypePicker = false;
      _markers = _buildMarkers(selectionOverride: latLng);
    });
  }

  //24.- _cancelTypeSelection cierra el menú flotante sin continuar el flujo.
  void _cancelTypeSelection() {
    setState(() {
      _showTypePicker = false;
      _pendingLatLng = null;
    });
  }

  //25.- _handleTypeSelected continúa el flujo de reporte tras elegir la categoría.
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

  //26.- _acknowledgeIntro registra la interacción con la pantalla inicial.
  void _acknowledgeIntro() {
    setState(() => _introAcknowledged = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _attemptInitialAutoCenter();
    });
  }

  //27.- _retryMapAvailability solicita nuevamente la verificación del API key.
  Future<void> _retryMapAvailability() async {
    final available = await GoogleMapsAvailability.instance.isConfigured();
    if (!mounted) return;
    setState(() {
      _mapAvailable = available;
    });
  }

  @override
  Widget build(BuildContext context) {
    //28.- build muestra la intro estilo shadcn_flutter antes del mapa.
    if (!_introAcknowledged) {
      final colorScheme = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: colorScheme.surfaceContainerHighest,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: MapReportIntroView(onContinue: _acknowledgeIntro),
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
              child: MapUnavailableView(onRetry: _retryMapAvailability),
            ),
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    _attemptInitialAutoCenter();
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition:
              const CameraPosition(target: LatLng(18.0010, -94.5597), zoom: 12.5),
          onMapCreated: _onMapCreated,
          onTap: _onTap,
          markers: _markers,
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                //40.- Column agrupa la instrucción ciudadana y la tarjeta de ubicación.
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    //41.- Container destaca el mensaje para iniciar un reporte sin cubrir el mapa.
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: shad.Text(
                        'Haz clic en el mapa para iniciar un reporte',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    MapLocationPrompt(
                      locating: _locatingUser,
                      onLocate: _goToCurrentLocation,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_selected != null && !_showTypePicker)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  //41.1.- shad.SurfaceCard despliega la ventana flotante con el CTA.
                  child: SelectedMarkerPopup(onStartReport: _openTypePickerFromMarker),
                ),
              ),
            ),
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

