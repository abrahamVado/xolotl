
import 'package:flutter/material.dart';
import '../services/services.dart';

class ConsultScreen extends StatefulWidget {
  const ConsultScreen({super.key});

  @override
  State<ConsultScreen> createState() => _ConsultScreenState();
}

class _ConsultScreenState extends State<ConsultScreen> {
  final _controller = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loading = false;

  //1.- _search consulta el folio ingresado y actualiza la interfaz con el resultado.
  Future<void> _search() async {
    setState(() {
      _loading = true;
      _result = null;
    });
    final res = await apiService.getFolio(_controller.text.trim());
    setState(() {
      _result = res;
      _loading = false;
    });
  }

  @override
  void dispose() {
    //2.- dispose libera el controlador de texto para evitar fugas de memoria.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Enter folio', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          FilledButton(
            //3.- FilledButton destaca la acción principal del formulario de consulta.
            onPressed: _loading ? null : _search,
            child: const Text('Consult'),
          ),
          const SizedBox(height: 24),
          if (_loading) const LinearProgressIndicator(),
          if (_result != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_result.toString()),
              ),
            ),
        ],
      ),
    );
  }
}
