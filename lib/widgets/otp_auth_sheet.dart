import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../services/services.dart' as services;
import '../services/session_service.dart';

//1.- OtpAuthSheet guía al ciudadano para obtener y validar el código SMS.
class OtpAuthSheet extends StatefulWidget {
  final SessionService sessionService;

  OtpAuthSheet({super.key, SessionService? sessionService})
    : sessionService = sessionService ?? services.sessionService;

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
    widget.sessionService.currentPhone().then((phone) {
      if (!mounted) return;
      if (phone != null) {
        _phoneController.text = phone;
      }
    });
  }

  //2.- _validatePhone revisa campo antes de solicitar OTP o mostrar errores inmediatos.
  bool _validatePhone() {
    final value = _phoneController.text.trim();
    if (value.isEmpty) {
      setState(() {
        _error = 'Ingresa un teléfono válido.';
      });
      return false;
    }
    return true;
  }

  //3.- _requestCode dispara el endpoint OTP y habilita el campo de código.
  Future<void> _requestCode() async {
    if (!_validatePhone()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await widget.sessionService.requestOtp(
      _phoneController.text.trim(),
    );
    setState(() {
      _loading = false;
      _codeRequested = ok;
      if (ok) {
        _codeController.clear();
      }
      _error = ok ? null : 'No pudimos enviar el código. Revisa el número.';
    });
  }

  //4.- _verifyCode valida el token y cierra la hoja en caso de éxito.
  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _error = 'Ingresa el código de 6 dígitos.';
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    final token = await widget.sessionService.verifyOtp(
      _phoneController.text.trim(),
      code,
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

  //5.- _backToPhone permite editar el número después de solicitar el OTP.
  void _backToPhone() {
    setState(() {
      _codeRequested = false;
      _codeController.clear();
      _error = null;
    });
  }

  //6.- _buildHeader renderiza el mango y título de la hoja inferior.
  Widget _buildHeader(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Verifica tu teléfono', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
      ],
    );
  }

  //7.- _buildPhoneStep muestra formulario inicial donde se captura el teléfono.
  Widget _buildPhoneStep(ThemeData theme) {
    return Column(
      key: const ValueKey('phone_step'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Text(
          'Te enviaremos un SMS con un código para confirmar tu identidad.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  //8.- _buildCodeStep presenta el campo de código y acciones adicionales.
  Widget _buildCodeStep(ThemeData theme) {
    return Column(
      key: const ValueKey('code_step'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            title: Text('Código enviado a:', style: theme.textTheme.labelSmall),
            subtitle: Text(
              _phoneController.text.trim(),
              style: theme.textTheme.titleMedium,
            ),
            trailing: TextButton(
              onPressed: _loading ? null : _backToPhone,
              child: const Text('Editar'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _codeController,
          maxLength: 6,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Código de 6 dígitos',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          enabled: !_loading,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _loading ? null : _requestCode,
            icon: const Icon(Icons.refresh),
            label: const Text('Reenviar código'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = math.max(24.0, viewInsets == 0 ? 32.0 : 16.0);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 24, 16, bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _codeRequested
                        ? _buildCodeStep(theme)
                        : _buildPhoneStep(theme),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_loading) const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () => Navigator.pop(context, false),
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
                          child: Text(
                            _codeRequested ? 'Validar código' : 'Enviar código',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
