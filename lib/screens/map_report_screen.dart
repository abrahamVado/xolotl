
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../services/api.dart';
import '../widgets/bento_menu.dart';

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

  Future<void> _load() async {
    final data = await Api.getIncidentTypes();
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
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Describe the problem'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Short description'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );
    if (ok != true) return;
    final res = await Api.submitReport(
      type: type,
      message: controller.text,
      lat: latLng.latitude,
      lng: latLng.longitude,
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
