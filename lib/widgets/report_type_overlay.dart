import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

//1.- _ReportTypeAssets centraliza la lógica de nombres para los recursos gráficos.
class _ReportTypeAssets {
  //2.- _knownAssets mapea ids conocidos hacia archivos concretos preparados en assets/icons.
  static const Map<String, String> _knownAssets = {
    'pothole': 'assets/icons/pothole.png',
    'light': 'assets/icons/light.png',
    'trash': 'assets/icons/trash.png',
    'water': 'assets/icons/water.png',
  };

  //3.- _defaultAsset sirve cuando el id no está identificado o es vacío.
  static const String _defaultAsset = 'assets/icons/default.png';

  //4.- resolve genera el nombre de archivo final usando el id y un fallback seguro.
  static String resolve(Map<String, dynamic> type) {
    final idSource = type['id'];
    if (idSource == null) {
      return _defaultAsset;
    }
    final normalized = idSource.toString().trim().toLowerCase();
    if (normalized.isEmpty) {
      return _defaultAsset;
    }
    final directAsset = _knownAssets[normalized];
    if (directAsset != null) {
      return directAsset;
    }
    final sanitized = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_');
    final trimmed = sanitized
        .replaceFirst(RegExp(r'^_+'), '')
        .replaceFirst(RegExp(r'_+$'), '');
    if (trimmed.isEmpty) {
      return _defaultAsset;
    }
    return 'assets/icons/$trimmed.png';
  }
}

//12.- resolveReportTypeAsset expone la transformación para validarla con pruebas unitarias.
@visibleForTesting
String resolveReportTypeAsset(Map<String, dynamic> type) =>
    _ReportTypeAssets.resolve(type);

//5.- ReportTypeOverlay muestra un menú flotante con los tipos de reporte.
class ReportTypeOverlay extends StatelessWidget {
  //6.- types contiene la lista de configuraciones recibidas desde la API.
  final List<Map<String, dynamic>> types;
  //7.- onSelected se invoca cuando la persona elige un tipo y debe cerrar el menú.
  final ValueChanged<String> onSelected;
  //8.- onDismiss permite cerrar el menú tocando fuera o con el botón de cierre.
  final VoidCallback onDismiss;

  const ReportTypeOverlay({
    super.key,
    required this.types,
    required this.onSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    //9.- theme reutiliza la paleta actual para tonalidades de tarjeta y texto.
    final theme = Theme.of(context);
    //10.- grid construye la retícula 6x6 o un mensaje vacío si no hay catálogos.
    final Widget grid = types.isEmpty
        ? SizedBox(
            height: 120,
            child: Center(
              child: shad.Text(
                'Sin tipos disponibles',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        : ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: types.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final type = types[index];
                final labelSource = type['name'] ?? type['id'] ?? 'Tipo';
                final label = labelSource.toString();
                final idSource = type['id'] ?? type['name'] ?? label;
                final id = idSource.toString();
                final assetPath = _ReportTypeAssets.resolve(type);
                return shad.GhostButton(
                  key: Key('report-type-$id'),
                  onPressed: () => onSelected(id),
                  density: shad.ButtonDensity.comfortable,
                  shape: shad.ButtonShape.rectangle,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //11.- Image.asset representa el ícono cargado desde las carpetas preparadas.
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: Image.asset(
                          assetPath,
                          key: Key('report-type-image-$id'),
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      shad.Text(
                        label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          );

    return shad.SurfaceCard(
      key: const Key('report-type-overlay'),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      filled: true,
      fillColor: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      borderColor: theme.colorScheme.outlineVariant,
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withOpacity(0.12),
          blurRadius: 32,
          offset: const Offset(0, 24),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: shad.Text(
                  'Selecciona el tipo de reporte',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              shad.IconButton.ghost(
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          grid,
        ],
      ),
    );
  }
}
