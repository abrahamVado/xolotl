
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../providers/folio_providers.dart';
import 'map_report_screen.dart';
import '../services/folio_repository.dart';
import '../services/services.dart';

class ConsultScreen extends ConsumerStatefulWidget {
  final ValueChanged<FolioEntry>? onNavigateToFolio;

  const ConsultScreen({
    super.key,
    this.onNavigateToFolio,
  });

  @override
  ConsumerState<ConsultScreen> createState() => _ConsultScreenState();
}

class _ConsultScreenState extends ConsumerState<ConsultScreen> {
  final TextEditingController _lookupController = TextEditingController();
  final TextEditingController _filterController = TextEditingController();
  Map<String, dynamic>? _manualResult;
  bool _loadingLookup = false;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    //1.- _filterController actualiza el texto de filtro y refresca la grilla.
    _filterController.addListener(() {
      setState(() => _filter = _filterController.text.trim());
    });
  }

  @override
  void dispose() {
    //2.- dispose libera ambos controladores para prevenir fugas en pruebas y app.
    _lookupController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  //3.- _search consulta el backend para folios que aún no se guardan localmente.
  Future<void> _search() async {
    final query = _lookupController.text.trim();
    if (query.isEmpty) {
      setState(() => _manualResult = null);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loadingLookup = true;
      _manualResult = null;
    });
    final res = await apiService.getFolio(query);
    if (!mounted) return;
    setState(() {
      _manualResult = res;
      _loadingLookup = false;
    });
  }

  //4.- _showFolioDetails abre una hoja inferior con acciones para el folio.
  void _showFolioDetails(FolioEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _FolioDetailSheet(
        entry: entry,
        formattedTimestamp: _formatTimestamp(entry.timestamp),
        onNavigate: () {
          Navigator.of(context).pop();
          _openOnMap(entry);
        },
      ),
    );
  }

  //5.- _openOnMap redirige al mapa resaltando el folio seleccionado.
  void _openOnMap(FolioEntry entry) {
    final callback = widget.onNavigateToFolio;
    if (callback != null) {
      callback(entry);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapReportScreen(
          initialTarget: LatLng(entry.latitude, entry.longitude),
        ),
      ),
    );
  }

  //6.- _applyFilter reduce la lista con coincidencias en id, estado o tipo.
  List<FolioEntry> _applyFilter(List<FolioEntry> entries) {
    if (_filter.isEmpty) return entries;
    final query = _filter.toLowerCase();
    return entries
        .where((entry) =>
            entry.id.toLowerCase().contains(query) ||
            entry.type.toLowerCase().contains(query) ||
            entry.status.toLowerCase().contains(query))
        .toList();
  }

  //7.- _formatTimestamp genera una marca legible para tarjetas y hojas.
  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  //8.- _buildFolioList devuelve la lista desplazable con soporte para refresco.
  Widget _buildFolioList(List<FolioEntry> entries) {
    if (entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No folios saved yet.')), 
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 960
            ? 3
            : width >= 640
                ? 2
                : 1;
        final aspectRatio = crossAxisCount == 1 ? 3.4 : 1.8;
        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 32),
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _FolioCard(
              key: Key('folio-card-${entry.id}'),
              entry: entry,
              formattedTimestamp: _formatTimestamp(entry.timestamp),
              onTap: () => _showFolioDetails(entry),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final folioState = ref.watch(folioListProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          TextField(
            controller: _filterController,
            decoration: const InputDecoration(
              labelText: 'Filter stored folios',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _lookupController,
                  decoration: const InputDecoration(
                    labelText: 'Lookup folio by ID',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _loadingLookup ? null : _search,
                child: const Text('Consult'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingLookup) const LinearProgressIndicator(),
          if (_manualResult != null)
            _ManualLookupCard(
              result: _manualResult!,
              onClose: () => setState(() => _manualResult = null),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(folioListProvider.notifier).refresh(),
              child: folioState.when(
                data: (entries) => _buildFolioList(_applyFilter(entries)),
                loading: () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(child: CircularProgressIndicator()),
                  ],
                ),
                error: (error, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),
                    const Center(child: Text('Failed to load folios')), 
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(error.toString()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//9.- _ManualLookupCard resume el resultado de la consulta puntual del backend.
class _ManualLookupCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onClose;

  const _ManualLookupCard({
    required this.result,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = result['status'] ?? result['state'];
    final updated = result['updatedAt'] ?? result['timestamp'] ?? result['createdAt'];
    final folio = result['folio'] ?? result['id'] ?? 'Unknown';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lookup: $folio',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (status != null)
              Text('Status: $status', style: theme.textTheme.bodyMedium),
            if (result['type'] != null)
              Text('Incident: ${result['type']}', style: theme.textTheme.bodyMedium),
            if (updated != null)
              Text('Updated: $updated', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              result.toString(),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

//10.- _FolioCard despliega la información principal dentro de la grilla.
class _FolioCard extends StatelessWidget {
  final FolioEntry entry;
  final String formattedTimestamp;
  final VoidCallback onTap;

  const _FolioCard({
    super.key,
    required this.entry,
    required this.formattedTimestamp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.id,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Chip(
                    label: Text(entry.status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Incident: ${entry.type}', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text('Created: $formattedTimestamp', style: theme.textTheme.bodySmall),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(Icons.open_in_new),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//11.- _FolioDetailSheet ofrece acciones contextualizadas para el folio.
class _FolioDetailSheet extends StatelessWidget {
  final FolioEntry entry;
  final String formattedTimestamp;
  final VoidCallback onNavigate;

  const _FolioDetailSheet({
    required this.entry,
    required this.formattedTimestamp,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Folio ${entry.id}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Status: ${entry.status}', style: theme.textTheme.bodyMedium),
            Text('Incident: ${entry.type}', style: theme.textTheme.bodyMedium),
            Text('Created: $formattedTimestamp', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onNavigate,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open on map'),
            ),
            const SizedBox(height: 12),
            Text(
              'Latitude: ${entry.latitude.toStringAsFixed(5)}\nLongitude: ${entry.longitude.toStringAsFixed(5)}',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
