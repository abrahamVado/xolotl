import 'package:flutter/material.dart';
import '../services/services.dart';

//1.- OtpAuthSheet guía al ciudadano para obtener y validar el código SMS.
class OtpAuthSheet extends StatefulWidget {
  const OtpAuthSheet({super.key});

  @override
  State<OtpAuthSheet> createState() => _OtpAuthSheetState();
}

class _OtpAuthSheetState extends State<OtpAuthSheet> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeRequested = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    sessionService.currentPhone().then((phone) {
      if (!mounted) return;
      if (phone != null) {
        _phoneController.text = phone;
      }
    });
  }

  //2.- _requestCode dispara el endpoint OTP y habilita el campo de código.
  Future<void> _requestCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await sessionService.requestOtp(_phoneController.text.trim());
    setState(() {
      _loading = false;
      _codeRequested = ok;
      _error = ok ? null : 'No pudimos enviar el código. Revisa el número.';
    });
  }

  //3.- _verifyCode valida el token y cierra la hoja en caso de éxito.
  Future<void> _verifyCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final token = await sessionService.verifyOtp(
      _phoneController.text.trim(),
      _codeController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = token == null ? 'Código inválido, intenta nuevamente.' : null;
    });
    if (token != null) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Verifica tu teléfono', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono (+521...)',
                border: OutlineInputBorder(),
              ),
              enabled: !_loading,
            ),
            const SizedBox(height: 12),
            if (_codeRequested)
              TextField(
                controller: _codeController,
                maxLength: 6,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Código de 6 dígitos',
                  border: OutlineInputBorder(),
                ),
                enabled: !_loading,
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _loading
                        ? null
                        : _codeRequested
                            ? _verifyCode
                            : _requestCode,
                    child: Text(_codeRequested ? 'Validar código' : 'Enviar código'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }
}
