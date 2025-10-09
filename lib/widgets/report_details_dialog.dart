import 'package:flutter/material.dart';

//1.- ReportDetailsResult encapsula los datos necesarios para enviar reporte.
class ReportDetailsResult {
  final String description;
  final String email;
  final String address;

  const ReportDetailsResult({required this.description, required this.email, required this.address});
}

//2.- ReportDetailsDialog muestra un formulario validado previo al envío.
class ReportDetailsDialog extends StatefulWidget {
  final String phone;
  const ReportDetailsDialog({super.key, required this.phone});

  @override
  State<ReportDetailsDialog> createState() => _ReportDetailsDialogState();
}

class _ReportDetailsDialogState extends State<ReportDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  //3.- _submit valida campos y devuelve el resultado al caller.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ReportDetailsResult(
        description: _descriptionController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Describe el incidente'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Describe brevemente el problema' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo de contacto'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un correo de contacto';
                  }
                  final email = value.trim();
                  final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
                  return isValid ? null : 'Correo inválido';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Referencia de dirección'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Añade una referencia' : null,
              ),
              const SizedBox(height: 16),
              Text('Teléfono registrado: ${widget.phone}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Enviar reporte')),
      ],
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
