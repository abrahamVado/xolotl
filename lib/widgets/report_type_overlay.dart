import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

//1.- ReportTypeOverlay muestra un menú flotante con los tipos de reporte.
class ReportTypeOverlay extends StatelessWidget {
  //2.- types contiene la lista de configuraciones recibidas desde la API.
  final List<Map<String, dynamic>> types;
  //3.- onSelected se invoca cuando la persona elige un tipo y debe cerrar el menú.
  final ValueChanged<String> onSelected;
  //4.- onDismiss permite cerrar el menú tocando fuera o con el botón de cierre.
  final VoidCallback onDismiss;

  const ReportTypeOverlay({
    super.key,
    required this.types,
    required this.onSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    //5.- theme reutiliza la paleta actual para tonalidades de tarjeta y texto.
    final theme = Theme.of(context);
    //6.- grid construye la retícula 6x6 o un mensaje vacío si no hay catálogos.
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
                final emojiSource = type['emoji'] ?? '📍';
                final emoji = emojiSource.toString();
                final idSource = type['id'] ?? type['name'] ?? label;
                final id = idSource.toString();
                return shad.GhostButton(
                  key: Key('report-type-$id'),
                  onPressed: () => onSelected(id),
                  density: shad.ButtonDensity.comfortable,
                  shape: shad.ButtonShape.rectangle,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
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

    return Material(
      color: Colors.transparent,
      child: shad.Card(
        key: const Key('report-type-overlay'),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        filled: true,
        fillColor: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
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
                shad.GhostButton(
                  onPressed: onDismiss,
                  density: shad.ButtonDensity.icon,
                  child: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            grid,
          ],
        ),
      ),
    );
  }
}
