
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api.dart';
import '../services/services.dart';
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

  //8.- _api expone la dependencia inyectable o recurre al singleton global.
  ApiService get _api => widget.api ?? apiService;
  //9.- _session expone la sesión inyectada para pruebas o la global.
  SessionService get _session => widget.session ?? sessionService;

  @override
  void initState() {
    super.initState();
    _load();
  }

  //10.- _load consulta tipos de incidente y actualiza el menú bento.
  Future<void> _load() async {
    final data = await _api.getIncidentTypes();
    setState(() {
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

  //11.- _ensureSession verifica que exista token ciudadano antes de reportar.
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

  //12.- _onTap guarda la coordenada seleccionada y despliega la superposición.
  void _onTap(LatLng latLng) async {
    setState(() {
      _selected = latLng;
      _pendingLatLng = latLng;
      _showTypePicker = true;
    });
  }

  //13.- _cancelTypeSelection cierra el menú flotante sin continuar el flujo.
  void _cancelTypeSelection() {
    setState(() {
      _showTypePicker = false;
      _pendingLatLng = null;
    });
  }

  //14.- _handleTypeSelected continúa el flujo de reporte tras elegir la categoría.
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

  //15.- _acknowledgeIntro registra la interacción con la pantalla inicial.
  void _acknowledgeIntro() {
    setState(() => _introAcknowledged = true);
  }

  @override
  Widget build(BuildContext context) {
    //10.- build muestra la intro estilo shadcn_flutter antes del mapa.
    if (!_introAcknowledged) {
      final colorScheme = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: colorScheme.surfaceContainerHighest,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Icon(
                            Icons.assistant_navigation,
                            size: 72,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Reporta incidencias en tu ciudad',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Selecciona un punto en el mapa para comenzar tu reporte ciudadano.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _acknowledgeIntro,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Click to continue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
