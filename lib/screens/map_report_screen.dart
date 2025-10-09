
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/services.dart';
import '../widgets/bento_menu.dart';
import '../widgets/otp_auth_sheet.dart';
import '../widgets/report_details_dialog.dart';

class MapReportScreen extends StatefulWidget {
  const MapReportScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  //6.- _load consulta tipos de incidente y actualiza el menú bento.
  Future<void> _load() async {
    final data = await apiService.getIncidentTypes();
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

  //7.- _ensureSession verifica que exista token ciudadano antes de reportar.
  Future<bool> _ensureSession() async {
    if (await sessionService.hasValidToken()) {
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

  //8.- _onTap gestiona el flujo completo para crear el reporte ciudadano.
  void _onTap(LatLng latLng) async {
    setState(() => _selected = latLng);
    final type = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BentoMenu(types: _types),
    );
    if (type == null) return;
    if (!mounted) return;
    if (!await _ensureSession()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Necesitas verificar tu teléfono.')));
      return;
    }
    final phone = await sessionService.currentPhone();
    if (phone == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No encontramos tu sesión activa.')));
      return;
    }
    final result = await showDialog<ReportDetailsResult>(
      context: context,
      builder: (_) => ReportDetailsDialog(phone: phone),
    );
    if (result == null) return;
    final res = await apiService.submitReport(
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send report')));
    }
  }

  //9.- _acknowledgeIntro registra la interacción con la pantalla inicial.
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
      ],
    );
  }
}
