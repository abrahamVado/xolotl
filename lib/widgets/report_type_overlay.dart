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

//5.- resolveReportTypeAsset expone la transformación para validarla con pruebas unitarias.
@visibleForTesting
String resolveReportTypeAsset(Map<String, dynamic> type) =>
    _ReportTypeAssets.resolve(type);

//6.- resolveReportTypeCrossAxisCount permite verificar la distribución de columnas en pruebas.
@visibleForTesting
int resolveReportTypeCrossAxisCount(double maxWidth) =>
    _ReportTypeGridMetrics.resolveCrossAxisCount(maxWidth);

//7.- _ReportTypeGridMetrics concentra las reglas responsivas del menú.
class _ReportTypeGridMetrics {
  //8.- minTileWidth define el ancho deseado de cada tarjeta para calcular columnas.
  static const double minTileWidth = 152;

  //9.- maxColumns limita el número de columnas simultáneas para evitar iconos diminutos.
  static const int maxColumns = 4;

  //10.- resolveCrossAxisCount calcula cuántas columnas caben según el ancho disponible.
  static int resolveCrossAxisCount(double maxWidth) {
    if (maxWidth.isNaN || !maxWidth.isFinite) {
      return 1;
    }
    final calculated = (maxWidth / minTileWidth).floor();
    return calculated.clamp(1, maxColumns);
  }
}

//11.- ReportTypeOverlay muestra un menú flotante con los tipos de reporte.
class ReportTypeOverlay extends StatelessWidget {
  //12.- types contiene la lista de configuraciones recibidas desde la API.
  final List<Map<String, dynamic>> types;
  //13.- onSelected se invoca cuando la persona elige un tipo y debe cerrar el menú.
  final ValueChanged<String> onSelected;
  //14.- onDismiss permite cerrar el menú tocando fuera o con el botón de cierre.
  final VoidCallback onDismiss;

  const ReportTypeOverlay({
    super.key,
    required this.types,
    required this.onSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    //15.- theme reutiliza la paleta actual para tonalidades de tarjeta y texto.
    final theme = Theme.of(context);
    //16.- grid construye la retícula responsiva o un mensaje vacío si no hay catálogos.
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
        : LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount =
                  _ReportTypeGridMetrics.resolveCrossAxisCount(constraints.maxWidth);
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 440),
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  itemCount: types.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 0.92,
                  ),
                  itemBuilder: (context, index) {
                    final type = types[index];
                    final labelSource = type['name'] ?? type['id'] ?? 'Tipo';
                    final label = labelSource.toString();
                    final idSource = type['id'] ?? type['name'] ?? label;
                    final id = idSource.toString();
                    final assetPath = _ReportTypeAssets.resolve(type);
                    return _ReportTypeTile(
                      id: id,
                      label: label,
                      assetPath: assetPath,
                      onTap: () => onSelected(id),
                    );
                  },
                ),
              );
            },
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

//17.- _ReportTypeTile define el botón visual cuadrado con imagen y etiqueta.
class _ReportTypeTile extends StatelessWidget {
  //18.- id se usa para llaves únicas y accesibilidad.
  final String id;
  //19.- label muestra el nombre legible del tipo de reporte.
  final String label;
  //20.- assetPath identifica el recurso gráfico mostrado dentro de la tarjeta.
  final String assetPath;
  //21.- onTap se ejecuta al pulsar la tarjeta.
  final VoidCallback onTap;

  const _ReportTypeTile({
    required this.id,
    required this.label,
    required this.assetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    //22.- theme permite alinear colores con el esquema actual.
    final theme = Theme.of(context);
    //23.- tileColor usa la superficie secundaria para dar contraste con el fondo principal.
    final tileColor = theme.colorScheme.surfaceVariant.withOpacity(0.9);
    //24.- textStyle emplea el estilo de etiquetas pequeñas reforzado para mejor legibilidad.
    final textStyle = theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('report-type-$id'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //25.- Expanded asegura que la imagen conserve proporciones sin desbordar.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Image.asset(
                    assetPath,
                    key: Key('report-type-image-$id'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                textAlign: TextAlign.center,
                style: textStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
