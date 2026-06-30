import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/models/interpellation_state.dart';
import '../../../../data/repositories.dart';
import '../../../../theme/stitch_colors.dart';

class OcrPreviewScreen extends ConsumerStatefulWidget {
  const OcrPreviewScreen({super.key});

  @override
  ConsumerState<OcrPreviewScreen> createState() => _OcrPreviewScreenState();
}

class _OcrPreviewScreenState extends ConsumerState<OcrPreviewScreen> {
  final _formKey = GlobalKey<FormState>();

  // Conducteur
  final _nameCtrl    = TextEditingController();
  final _licCtrl     = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _dobCtrl     = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Véhicule
  final _plateCtrl  = TextEditingController();
  final _brandCtrl  = TextEditingController();
  final _modelCtrl  = TextEditingController();
  final _colorCtrl  = TextEditingController();

  // Documents
  bool _hasPermis    = true;
  bool _hasCarteGrise = true;
  bool _hasAssurance  = true;
  bool _hasControle   = true;
  
  bool _isConfirming = false;


  @override
  void initState() {
    super.initState();
    final s = ref.read(interpellationProvider);
    _nameCtrl.text  = s.driverName;
    _licCtrl.text   = s.driverLicense;
    _phoneCtrl.text = s.driverPhone;
    _plateCtrl.text = s.vehiclePlate;
    _brandCtrl.text = s.vehicleBrand;
    _modelCtrl.text = s.vehicleModel;
    _colorCtrl.text = s.vehicleColor;
    _hasPermis      = s.hasLicense;
    _hasCarteGrise  = s.hasCarteGrise;
    _hasAssurance   = s.hasAssurance;
    _hasControle    = s.hasControleTechnique;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _licCtrl.dispose(); _phoneCtrl.dispose(); _dobCtrl.dispose();
    _addressCtrl.dispose();
    _plateCtrl.dispose(); _brandCtrl.dispose();
    _modelCtrl.dispose(); _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchByPlate() async {
    final plate = _plateCtrl.text.trim().toUpperCase();
    if (plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saisissez d\'abord le numéro de plaque')));
      return;
    }
    try {
      final result = await DriverRepository().search(plate: plate);
      if (!mounted) return;

      final driver = result['driver'] as Map<String, dynamic>?;
      final vehicle = result['vehicle'] as Map<String, dynamic>?;

      if (driver == null && vehicle == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun conducteur trouvé')));
        return;
      }

      setState(() {
        if (driver != null) {
          final prenom = driver['prenom'] as String? ?? '';
          final nom = driver['nom'] as String? ?? '';
          _nameCtrl.text = '$prenom $nom'.trim();
          _licCtrl.text = driver['numeroPermis'] as String? ?? _licCtrl.text;
          _phoneCtrl.text = driver['telephone'] as String? ?? _phoneCtrl.text;
        }
        if (vehicle != null) {
          _brandCtrl.text = vehicle['marque'] as String? ?? _brandCtrl.text;
          _modelCtrl.text = vehicle['modele'] as String? ?? _modelCtrl.text;
          _colorCtrl.text = vehicle['couleur'] as String? ?? _colorCtrl.text;
        }
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> _confirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isConfirming = true);

    final notifier = ref.read(interpellationProvider.notifier);
    notifier.updateDriver(
      name:       _nameCtrl.text.trim(),
      license:    _licCtrl.text.trim(),
      hasLicense: _hasPermis,
      phone:      _phoneCtrl.text.trim(),
    );
    notifier.updateVehicle(
      plate:               _plateCtrl.text.trim().toUpperCase(),
      brand:               _brandCtrl.text.trim(),
      model:               _modelCtrl.text.trim(),
      color:               _colorCtrl.text.trim(),
      hasCarteGrise:       _hasCarteGrise,
      hasAssurance:        _hasAssurance,
      hasControleTechnique: _hasControle,
    );

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isConfirming = false);
      context.push('/police/location'); // Move to infractions/location
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StitchColors.background,
      body: Stack(
        children: [
          // Content
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              right: 16,
              bottom: 40,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Indicator
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: StitchColors.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: StitchColors.primaryContainer.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.verified, color: StitchColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SCAN RÉUSSI',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: StitchColors.onPrimaryFixedVariant,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Veuillez vérifier et confirmer les informations extraites des documents du conducteur.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: StitchColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  // Section 1: Conducteur
                  _buildSectionHeader('person', 'Informations du Conducteur'),
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: StitchColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: StitchColors.outlineVariant),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInputField(label: 'Nom Complet', controller: _nameCtrl),
                        const SizedBox(height: 12),
                        _buildInputField(label: 'N° de Permis de Conduire', controller: _licCtrl, isMono: true),
                        const SizedBox(height: 12),
                        _buildInputField(label: 'Date de Naissance', controller: _dobCtrl, icon: Icons.calendar_today),
                        const SizedBox(height: 12),
                        _buildInputField(label: 'N° de Téléphone', controller: _phoneCtrl, keyboard: TextInputType.phone),
                        const SizedBox(height: 12),
                        _buildInputField(label: 'Adresse de Résidence', controller: _addressCtrl),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  // Section 2: Véhicule
                  _buildSectionHeader('directions_car', 'Détails du Véhicule'),
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: StitchColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: StitchColors.outlineVariant),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      children: [
                        // Photo Preview Area
                        Container(
                          height: 160,
                          decoration: const BoxDecoration(
                            color: StitchColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            image: DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1549399542-7e3f8b79c341?q=80&w=600&auto=format&fit=crop'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade700,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    _plateCtrl.text.isEmpty ? 'INCONNUE' : _plateCtrl.text,
                                    style: GoogleFonts.courierPrime(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: IconButton(
                                  icon: const Icon(Icons.search, color: Colors.white),
                                  onPressed: _searchByPlate,
                                  tooltip: 'Rechercher la plaque',
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildInputField(label: 'Immatriculation', controller: _plateCtrl, isMono: true, uppercase: true),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildInputField(label: 'Marque', controller: _brandCtrl)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildInputField(label: 'Modèle', controller: _modelCtrl)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInputField(label: 'Couleur', controller: _colorCtrl),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  // Section 3: Verification Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip('Permis Valide', _hasPermis, (v) => setState(() => _hasPermis = v)),
                      _buildChip('Carte Grise', _hasCarteGrise, (v) => setState(() => _hasCarteGrise = v)),
                      _buildChip('Assurance Valide', _hasAssurance, (v) => setState(() => _hasAssurance = v)),
                      _buildChip('Contrôle Tech. OK', _hasControle, (v) => setState(() => _hasControle = v)),
                    ],
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 32),

                  // Validation Action
                  ElevatedButton(
                    onPressed: _isConfirming ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StitchColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: _isConfirming
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('CONTINUER', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward),
                            ],
                          ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 12),
                  Text(
                    'En validant, vous confirmez l\'exactitude des données pour le rapport officiel.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),

          // TopAppBar (Glass Header)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 56,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 16, right: 16),
              decoration: BoxDecoration(
                color: StitchColors.background.withValues(alpha: 0.8),
                border: const Border(bottom: BorderSide(color: StitchColors.outlineVariant)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: StitchColors.primary),
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        'Circulation+',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: StitchColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Icon(Icons.security, color: StitchColors.onSurfaceVariant, size: 20),
                      SizedBox(width: 8),
                      Icon(Icons.signal_cellular_alt, color: StitchColors.onSurfaceVariant, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String iconName, String title) {
    IconData icon;
    switch (iconName) {
      case 'person': icon = Icons.person; break;
      case 'directions_car': icon = Icons.directions_car; break;
      default: icon = Icons.circle;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: StitchColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: StitchColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isMono = false,
    bool uppercase = false,
    IconData? icon,
    TextInputType? keyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: StitchColors.onSurfaceVariant,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.none,
          style: isMono ? GoogleFonts.courierPrime(fontSize: 14) : GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: StitchColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: icon != null ? Icon(icon, color: StitchColors.onSurfaceVariant, size: 20) : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: StitchColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: StitchColors.primary, width: 2),
            ),
          ),
          onChanged: (v) {
            if (uppercase && controller == _plateCtrl) setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildChip(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value ? StitchColors.primary.withValues(alpha: 0.1) : StitchColors.errorContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? StitchColors.primary.withValues(alpha: 0.2) : StitchColors.error.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.warning,
              color: value ? StitchColors.primary : StitchColors.onErrorContainer,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value ? StitchColors.primary : StitchColors.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
