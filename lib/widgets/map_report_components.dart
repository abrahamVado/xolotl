import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

//1.- MapLocationPrompt guía a la persona usuaria para centrar la cámara en su posición.
class MapLocationPrompt extends StatelessWidget {
  //2.- onLocate dispara la solicitud de coordenadas actuales.
  final VoidCallback onLocate;
  //3.- locating deshabilita el botón mientras se consulta la ubicación.
  final bool locating;

  const MapLocationPrompt({
    super.key,
    required this.onLocate,
    required this.locating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return shad.SurfaceCard(
      key: const Key('map-location-card'),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      filled: true,
      fillColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      borderColor: colorScheme.outlineVariant,
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withOpacity(0.07),
          blurRadius: 18,
          offset: const Offset(0, 12),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                shad.Text(
                  'Usar mi ubicación',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                shad.Text(
                  'Centra el mapa y aplica zoom sobre tu ubicación actual.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          shad.PrimaryButton(
            key: const Key('map-current-location-button'),
            onPressed: locating ? null : onLocate,
            density: shad.ButtonDensity.compact,
            shape: shad.ButtonShape.rectangle,
            child: locating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const shad.Text('Centrar'),
          ),
        ],
      ),
    );
  }
}

//4.- MapReportIntroView encapsula la tarjeta de bienvenida con componentes shadcn.
class MapReportIntroView extends StatelessWidget {
  //5.- onContinue propaga el cierre de la introducción hacia la pantalla padre.
  final VoidCallback onContinue;

  const MapReportIntroView({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return shad.SurfaceCard(
      key: const Key('map-intro-card'),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      filled: true,
      fillColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      borderColor: colorScheme.outlineVariant,
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withOpacity(0.08),
          blurRadius: 28,
          offset: const Offset(0, 18),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          shad.SurfaceCard(
            padding: const EdgeInsets.all(20),
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            borderColor: colorScheme.outlineVariant.withOpacity(0.4),
            child: const Icon(
              Icons.assistant_navigation,
              size: 72,
            ),
          ),
          const SizedBox(height: 32),
          shad.Text(
            'Reporta incidencias en tu ciudad',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          shad.Text(
            'Selecciona un punto en el mapa para comenzar tu reporte ciudadano.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: shad.PrimaryButton(
              onPressed: onContinue,
              density: shad.ButtonDensity.comfortable,
              shape: shad.ButtonShape.rectangle,
              child: const shad.Text('Click to continue'),
            ),
          ),
        ],
      ),
    );
  }
}

//6.- MapUnavailableView muestra instrucciones cuando falta el API key de Google Maps.
class MapUnavailableView extends StatelessWidget {
  //7.- onRetry vuelve a solicitar la verificación del API key configurado.
  final VoidCallback onRetry;

  const MapUnavailableView({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return shad.SurfaceCard(
      key: const Key('map-unavailable-card'),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      filled: true,
      fillColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      borderColor: colorScheme.outlineVariant,
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withOpacity(0.08),
          blurRadius: 28,
          offset: const Offset(0, 20),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.map_outlined, size: 60),
          const SizedBox(height: 24),
          shad.Text(
            'Configura Google Maps',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          shad.Text(
            'Agrega tu API key de Android en local.properties como MAPS_API_KEY '
            'o exporta la variable de entorno MAPS_API_KEY antes de compilar.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          shad.Text(
            'Después vuelve a intentar para cargar el mapa ciudadano.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          shad.PrimaryButton(
            onPressed: onRetry,
            density: shad.ButtonDensity.comfortable,
            shape: shad.ButtonShape.rectangle,
            child: const shad.Text('Reintentar detección'),
          ),
        ],
      ),
    );
  }
}

//8.- SelectedMarkerPopup despliega la ventana flotante con el botón principal.
class SelectedMarkerPopup extends StatelessWidget {
  //9.- onStartReport reactiva el selector tras tocar el marcador.
  final VoidCallback onStartReport;

  const SelectedMarkerPopup({
    super.key,
    required this.onStartReport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return shad.SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      filled: true,
      fillColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      borderColor: colorScheme.outlineVariant,
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 16),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          shad.Text(
            'Listo para reportar',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          shad.Text(
            'Presiona el botón para elegir el tipo de incidencia.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: shad.PrimaryButton(
              key: const Key('selected-marker-report-button'),
              onPressed: onStartReport,
              density: shad.ButtonDensity.comfortable,
              shape: shad.ButtonShape.rectangle,
              child: const shad.Text('Comenzar reporte'),
            ),
          ),
        ],
      ),
    );
  }
}
