
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
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _selected;
  List<Map<String, dynamic>> _types = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  //1.- _load consulta tipos de incidente y actualiza el menú bento.
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

  //2.- _ensureSession verifica que exista token ciudadano antes de reportar.
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

  //3.- _onTap gestiona el flujo completo para crear el reporte ciudadano.
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

  @override
  Widget build(BuildContext context) {
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
