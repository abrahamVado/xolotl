import 'package:flutter/material.dart';

//1.- InitializationStatusView muestra el estado del arranque con mensajes y detalles opcionales.
class InitializationStatusView extends StatefulWidget {
  const InitializationStatusView({
    super.key,
    required this.title,
    required this.message,
    this.details,
    this.onRetry,
    this.showLoader = false,
  });

  final String title;
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final bool showLoader;

  @override
  State<InitializationStatusView> createState() => _InitializationStatusViewState();
}

class _InitializationStatusViewState extends State<InitializationStatusView> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    //1.- build levanta un Scaffold centrado con información de progreso y botones de acción.
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text(widget.message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                if (widget.showLoader) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                ],
                const SizedBox(height: 24),
                //2.- ElevatedButton alterna la visibilidad de los detalles reportados durante el arranque.
                ElevatedButton(
                  onPressed: () => setState(() => _showDetails = !_showDetails),
                  child: Text(_showDetails ? 'Ocultar detalles' : 'Revisar errores'),
                ),
                if (_showDetails) ...[
                  const SizedBox(height: 12),
                  Text(widget.details ?? 'No se han detectado errores.', textAlign: TextAlign.center),
                ],
                if (widget.onRetry != null) ...[
                  const SizedBox(height: 24),
                  //3.- Botón adicional permite relanzar la inicialización cuando está disponible.
                  OutlinedButton(onPressed: widget.onRetry, child: const Text('Reintentar')),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
