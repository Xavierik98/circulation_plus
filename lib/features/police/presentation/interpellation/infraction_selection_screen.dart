import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/stitch_colors.dart';
import '../../../../shared/models/infraction_model.dart';
import '../../../../data/providers.dart';
import '../../../../shared/models/interpellation_state.dart';

class InfractionSelectionScreen extends ConsumerStatefulWidget {
  const InfractionSelectionScreen({super.key});

  @override
  ConsumerState<InfractionSelectionScreen> createState() =>
      _InfractionSelectionScreenState();
}

class _InfractionSelectionScreenState extends ConsumerState<InfractionSelectionScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _categoryMeta = {
    InfractionCategory.speed: ('Vitesse', Icons.speed, StitchColors.primary),
    InfractionCategory.safety: ('Sécurité', Icons.health_and_safety, StitchColors.primary),
    InfractionCategory.documents: ('Documents Obligatoires', Icons.description, StitchColors.tertiary),
    InfractionCategory.behavior: ('Comportement', Icons.psychology, StitchColors.secondary),
    InfractionCategory.parking: ('Stationnement', Icons.local_parking, StitchColors.onSurfaceVariant),
  };

  String _fmtAmount(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final remaining = s.length - 1 - i;
      if (remaining > 0 && remaining % 3 == 0) buf.write(',');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedInfractionsProvider);
    final totalAmount = selected.fold<int>(0, (sum, i) => sum + i.fineAmount);
    final query = _searchCtrl.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: StitchColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // TopAppBar
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: StitchColors.surface,
                border: Border(bottom: BorderSide(color: StitchColors.outlineVariant)),
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: StitchColors.primary, size: 20), onPressed: () => context.pop()),
                  const Icon(Icons.security, color: StitchColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Circulation+', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: StitchColors.primary)),
                ],
              ),
            ),
            Expanded(
              child: ref.watch(infractionsProvider).when(
                    loading: () => const Center(child: CircularProgressIndicator(color: StitchColors.primary)),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Catalogue indisponible.\n$e', textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: StitchColors.onSurfaceVariant)),
                      ),
                    ),
                    data: (all) {
                      final filtered = query.isEmpty
                          ? all
                          : all.where((i) =>
                              i.labelFr.toLowerCase().contains(query) || i.code.toLowerCase().contains(query)).toList();
                      final grouped = <InfractionCategory, List<InfractionType>>{};
                      for (final inf in filtered) {
                        grouped.putIfAbsent(inf.category, () => []).add(inf);
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nouvelle Infraction', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: StitchColors.onSurface)),
                            const SizedBox(height: 4),
                            Text('Sélectionnez le ou les types d\'infractions constatées lors du contrôle.',
                                style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurfaceVariant)),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() {}),
                              style: GoogleFonts.inter(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Rechercher une infraction...',
                                prefixIcon: const Icon(Icons.search, color: StitchColors.onSurfaceVariant),
                                filled: true,
                                fillColor: StitchColors.surfaceContainerLowest,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: StitchColors.outlineVariant)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: StitchColors.outlineVariant)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: StitchColors.primary, width: 2)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            for (final entry in grouped.entries) _buildCategorySection(entry.key, entry.value, selected),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: selected.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: StitchColors.surfaceContainerLow,
                border: const Border(top: BorderSide(color: StitchColors.outlineVariant)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('TOTAL PROVISOIRE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: StitchColors.onSurfaceVariant)),
                          Text('${_fmtAmount(totalAmount)} FCFA',
                              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: StitchColors.primary)),
                          Text('${selected.length} infraction${selected.length > 1 ? "s" : ""}', style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => context.push('/police/fine-calc'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StitchColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: Row(
                          children: [
                            Text('SUIVANT', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().slideY(begin: 1, end: 0, duration: 250.ms),
    );
  }

  Widget _buildCategorySection(InfractionCategory cat, List<InfractionType> items, List<InfractionType> selected) {
    final meta = _categoryMeta[cat]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(meta.$2, size: 18, color: meta.$3),
              const SizedBox(width: 8),
              Text(meta.$1.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: meta.$3)),
            ],
          ),
          const SizedBox(height: 8),
          for (final inf in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InfractionCheckTile(
                infraction: inf,
                isSelected: selected.any((s) => s.id == inf.id),
                onToggle: () {
                  final current = List<InfractionType>.from(ref.read(selectedInfractionsProvider));
                  final isSel = current.any((s) => s.id == inf.id);
                  if (isSel) {
                    current.removeWhere((s) => s.id == inf.id);
                  } else {
                    current.add(inf);
                  }
                  ref.read(selectedInfractionsProvider.notifier).state = current;
                  ref.read(interpellationProvider.notifier).setInfractions(current);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _InfractionCheckTile extends StatelessWidget {
  final InfractionType infraction;
  final bool isSelected;
  final VoidCallback onToggle;

  const _InfractionCheckTile({required this.infraction, required this.isSelected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? StitchColors.primaryFixed.withValues(alpha: 0.08) : StitchColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? StitchColors.primary : StitchColors.outlineVariant, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) => onToggle(),
              activeColor: StitchColors.primary,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(infraction.labelFr, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: StitchColors.onSurface)),
                    Text(infraction.code, style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: StitchColors.primaryFixed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
              child: Text('${_fmt(infraction.fineAmount)} FCFA',
                  style: GoogleFonts.courierPrime(fontSize: 13, fontWeight: FontWeight.bold, color: StitchColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final remaining = s.length - 1 - i;
      if (remaining > 0 && remaining % 3 == 0) buf.write(',');
    }
    return buf.toString();
  }
}
