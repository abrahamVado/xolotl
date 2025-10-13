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

  //3.- _imageUrlKeys agrupa las variaciones más comunes entregadas por la API.
  static const List<String> _imageUrlKeys = [
    'image_url',
    'imageUrl',
    'image',
  ];

  //4.- _defaultAsset sirve cuando el id no está identificado o es vacío.
  static const String _defaultAsset = 'assets/icons/default.png';

  //5.- resolve genera el nombre de archivo final usando el id y un fallback seguro.
  static String resolve(Map<String, dynamic> type) {
    final imagePath = _resolveFromImageUrl(type);
    if (imagePath != null) {
      return imagePath;
    }
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

  //6.- _resolveFromImageUrl analiza la ruta proveniente del backend y la normaliza.
  static String? _resolveFromImageUrl(Map<String, dynamic> type) {
    for (final key in _imageUrlKeys) {
      final value = type[key];
      if (value == null) {
        continue;
      }
      final raw = value.toString().trim();
      if (raw.isEmpty) {
        continue;
      }
      final sanitized = raw
          .replaceAll('\\', '/')
          .replaceFirst(RegExp(r'^(\./)+'), '')
          .trim();
      if (sanitized.isEmpty) {
        continue;
      }
      if (_isNetworkSource(sanitized)) {
        return sanitized;
      }
      final normalized = sanitized.replaceFirst(RegExp(r'^/+'), '');
      if (normalized.isEmpty) {
        continue;
      }
      final candidates = <String>[];
      if (normalized.startsWith('internal/')) {
        candidates.add(normalized);
      } else if (normalized.startsWith('assets/')) {
        candidates
          ..add(normalized)
          ..add('internal/$normalized');
      } else {
        candidates
          ..add('assets/$normalized')
          ..add('internal/assets/$normalized');
      }
      for (final candidate in candidates) {
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }
    }
    return null;
  }

  //7.- defaultAsset expone el fallback primario reutilizado por la vista.
  static String get defaultAsset => _defaultAsset;

  //8.- _isNetworkSource detecta rutas absolutas que deben cargarse por HTTP.
  static bool _isNetworkSource(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://') || lower.startsWith('data:');
  }
}

//9.- resolveReportTypeAsset expone la transformación para validarla con pruebas unitarias.
@visibleForTesting
String resolveReportTypeAsset(Map<String, dynamic> type) =>
    _ReportTypeAssets.resolve(type);

//10.- resolveReportTypeCrossAxisCount permite verificar la distribución de columnas en pruebas.
@visibleForTesting
int resolveReportTypeCrossAxisCount(double maxWidth) =>
    _ReportTypeGridMetrics.resolveCrossAxisCount(maxWidth);

//11.- _ReportTypeGridMetrics concentra las reglas fijas del menú.
class _ReportTypeGridMetrics {
  //12.- fixedColumns asegura que la retícula siempre sea de 3x3 como lo solicitó el diseño.
  static const int fixedColumns = 3;

  //13.- resolveCrossAxisCount ignora el ancho y fuerza las tres columnas requeridas.
  static int resolveCrossAxisCount(double maxWidth) {
    if (maxWidth.isNaN || !maxWidth.isFinite) {
      return fixedColumns;
    }
    return fixedColumns;
  }
}

//15.- ReportTypeOverlay muestra un menú flotante con los tipos de reporte.
class ReportTypeOverlay extends StatelessWidget {
  //16.- types contiene la lista de configuraciones recibidas desde la API.
  final List<Map<String, dynamic>> types;
  //17.- onSelected se invoca cuando la persona elige un tipo y debe cerrar el menú.
  final ValueChanged<String> onSelected;
  //18.- onDismiss permite cerrar el menú tocando fuera o con el botón de cierre.
  final VoidCallback onDismiss;

  const ReportTypeOverlay({
    super.key,
    required this.types,
    required this.onSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    //19.- theme reutiliza la paleta actual para tonalidades de tarjeta y texto.
    final theme = Theme.of(context);
    //20.- grid construye la retícula responsiva o un mensaje vacío si no hay catálogos.
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
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final type = types[index];
                    final labelSource = type['name'] ?? type['id'] ?? 'Tipo';
                    final label = labelSource.toString();
                    final idSource = type['id'] ?? type['name'] ?? label;
                    final id = idSource.toString();
                    //21.- rawValue prioriza el reportType entregado por la API para envíos.
                    final rawValue = type['reportType'] ?? idSource ?? label;
                    //22.- value normaliza el identificador final a String para callbacks.
                    final value = rawValue.toString();
                    final assetPath = _ReportTypeAssets.resolve(type);
                    return _ReportTypeTile(
                      id: id,
                      assetPath: assetPath,
                      fallbackAsset: _ReportTypeAssets.defaultAsset,
                      semanticLabel: label,
                      onTap: () => onSelected(value),
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

//23.- _ReportTypeTile define el botón visual cuadrado centrado únicamente con el icono.
class _ReportTypeTile extends StatelessWidget {
  //24.- id se usa para llaves únicas y accesibilidad.
  final String id;
  //25.- semanticLabel conserva el nombre para lectores de pantalla aunque no se renderice.
  final String semanticLabel;
  //26.- assetPath identifica el recurso gráfico mostrado dentro de la tarjeta.
  final String assetPath;
  //27.- fallbackAsset ofrece una ruta secundaria si falla la primaria.
  final String fallbackAsset;
  //28.- onTap se ejecuta al pulsar la tarjeta.
  final VoidCallback onTap;

  const _ReportTypeTile({
    required this.id,
    required this.semanticLabel,
    required this.assetPath,
    required this.fallbackAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    //29.- theme permite alinear colores con el esquema actual.
    final theme = Theme.of(context);
    //30.- tileColor ahora es blanco puro para respetar la especificación de botones claros.
    final tileColor = Colors.white;

    //31.- _ReportTypeTileImage evalúa si la ruta es remota y responde a errores.
    //32.- imageWidget delega la representación a un widget dedicado que maneja errores.
    final Widget imageWidget = _ReportTypeTileImage(
      id: id,
      assetPath: assetPath,
      fallbackAsset: fallbackAsset,
    );

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('report-type-$id'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Semantics(
          //33.- Semantics preserva el nombre del tipo para accesibilidad aunque no sea visible.
          button: true,
          label: semanticLabel,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: imageWidget,
            ),
          ),
        ),
      ),
    );
  }
}

//34.- _ReportTypeTileImage encapsula la lógica para mostrar imágenes y errores.
class _ReportTypeTileImage extends StatelessWidget {
  final String id;
  final String assetPath;
  final String fallbackAsset;

  const _ReportTypeTileImage({
    required this.id,
    required this.assetPath,
    required this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedPath = assetPath.trim();
    final bool hasPath = trimmedPath.isNotEmpty;
    final Widget errorWidget = _ReportTypeImageError(
      id: id,
      fallbackAsset: fallbackAsset,
    );

    if (!hasPath) {
      return FittedBox(fit: BoxFit.contain, child: errorWidget);
    }

    final bool isNetworkAsset = _ReportTypeAssets._isNetworkSource(trimmedPath);

    final Widget image = isNetworkAsset
        ? Image.network(
            trimmedPath,
            key: Key('report-type-image-$id'),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => errorWidget,
          )
        : Image.asset(
            trimmedPath,
            key: Key('report-type-image-$id'),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => errorWidget,
          );

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 96,
        height: 96,
        child: image,
      ),
    );
  }
}

//35.- _ReportTypeImageError comunica visualmente que la carga falló.
class _ReportTypeImageError extends StatelessWidget {
  final String id;
  final String fallbackAsset;

  const _ReportTypeImageError({
    required this.id,
    required this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFallback = fallbackAsset.trim().isNotEmpty;
    final Widget fallbackWidget = hasFallback
        ? Image.asset(
            fallbackAsset,
            key: Key('report-type-image-fallback-$id'),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.broken_image_outlined,
                key: Key('report-type-image-fallback-error-$id'),
                color: theme.colorScheme.error,
                size: 48,
              );
            },
          )
        : Icon(
            Icons.broken_image_outlined,
            key: Key('report-type-image-fallback-error-$id'),
            color: theme.colorScheme.error,
            size: 48,
          );

    final textStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onErrorContainer,
    );

    return SizedBox(
      key: Key('report-type-image-error-$id'),
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FittedBox(
                fit: BoxFit.contain,
                child: fallbackWidget,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              key: Key('report-type-image-error-label-$id'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Imagen no disponible',
                style: textStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
