import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/vehicle_listing.dart';
import '../../providers/auth_providers.dart';
import '../../providers/vehicle_catalog_providers.dart';
import 'widgets/customs_terms_notice.dart';

/// Formulaire « Demander le prix » pour un vehicule (statut initial cote
/// serveur : en_attente_devis). Notifie l'admin via la fonction serveur.
class RequestPriceScreen extends ConsumerStatefulWidget {
  final VehicleListing vehicle;
  const RequestPriceScreen({super.key, required this.vehicle});

  @override
  ConsumerState<RequestPriceScreen> createState() => _RequestPriceScreenState();
}

class _RequestPriceScreenState extends ConsumerState<RequestPriceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _email = TextEditingController();
  final _country = TextEditingController(text: 'Senegal');
  final _city = TextEditingController();
  final _message = TextEditingController();
  bool _accepted = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-remplit avec le profil connecte.
    final p = ref.read(currentProfileProvider).valueOrNull;
    if (p != null) {
      _name.text = p.fullName;
      _whatsapp.text = p.whatsapp;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _whatsapp,
      _email,
      _country,
      _city,
      _message
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accepted) {
      setState(() => _error = 'Vous devez accepter les conditions d\'importation.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(vehicleRequestServiceProvider).submit(
            vehicleReference: widget.vehicle.reference,
            customerName: _name.text.trim(),
            phone: _phone.text.trim(),
            whatsapp: _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
            country: _country.text.trim().isEmpty ? null : _country.text.trim(),
            city: _city.text.trim().isEmpty ? null : _city.text.trim(),
            message: _message.text.trim().isEmpty ? null : _message.text.trim(),
          );
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            icon: const Icon(Icons.check_circle,
                color: AppColors.vert, size: 40),
            title: const Text('Demande envoyee'),
            content: const Text(
                'Votre demande de prix a bien ete transmise. Notre equipe '
                'vous prepare un devis et vous recontacte rapidement.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // dialog
                  Navigator.of(context).pop(); // ecran
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Envoi impossible : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    return Scaffold(
      appBar: AppBar(title: const Text('Demander le prix')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Rappel du vehicule
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grisClair,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.directions_car, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text('Ref ${v.reference}',
                            style: const TextStyle(
                                color: AppColors.gris, fontSize: 12)),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              _field(_name, 'Nom complet *', required: true),
              _field(_phone, 'Telephone *',
                  keyboard: TextInputType.phone, required: true),
              _field(_whatsapp, 'WhatsApp', keyboard: TextInputType.phone),
              _field(_email, 'Email (facultatif)',
                  keyboard: TextInputType.emailAddress),
              Row(children: [
                Expanded(child: _field(_country, 'Pays')),
                const SizedBox(width: 12),
                Expanded(child: _field(_city, 'Ville')),
              ]),
              _field(_message, 'Message', maxLines: 3),
              const SizedBox(height: 8),
              const CustomsTermsNotice(),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _accepted,
                activeColor: AppColors.vert,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setState(() => _accepted = v ?? false),
                title: const Text(
                    'J\'ai lu et j\'accepte les conditions d\'importation '
                    '(acompte 70% / solde 30%, dedouanement a ma charge).',
                    style: TextStyle(fontSize: 13)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(_error!, style: const TextStyle(color: AppColors.primary)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Envoyer la demande'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboard, int maxLines = 1, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null
            : null,
      ),
    );
  }
}
