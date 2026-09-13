import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/produce_batch.dart';
import '../../../models/transit_manifest.dart';
import '../../../state/produce_providers.dart';
import '../../../state/transit_providers.dart';

class DispatchTransitScreen extends ConsumerStatefulWidget {
  final String batchId;

  const DispatchTransitScreen({super.key, required this.batchId});

  @override
  ConsumerState<DispatchTransitScreen> createState() =>
      _DispatchTransitScreenState();
}

class _DispatchTransitScreenState extends ConsumerState<DispatchTransitScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedMandi;
  TransitMode _selectedMode = TransitMode.solarReeferVan;
  int _transitHours = 3;
  final TextEditingController _vehicleCtrl = TextEditingController(text: 'AS-01-GB-3342');
  final TextEditingController _driverNameCtrl =
      TextEditingController(text: 'Manoj Bora');
  final TextEditingController _driverPhoneCtrl =
      TextEditingController(text: '+91 94351 88201');
  final TextEditingController _notesCtrl = TextEditingController();

  final List<String> _mandiOptions = [
    'Guwahati APMC Mandi (Pamohi)',
    'Shillong Iewduh Market (Bara Bazaar)',
    'Tezpur APMC Mandi',
    'Imphal Khwairamband Mandi',
    'Silchar Regulated Market',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMandi = _mandiOptions.first;
  }

  @override
  void dispose() {
    _vehicleCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batches = ref.watch(produceBatchesProvider);
    final ProduceBatch? batch = batches.cast<ProduceBatch?>().firstWhere(
          (b) => b?.batchId == widget.batchId,
          orElse: () => null,
        );

    if (batch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dispatch Batch')),
        body: const Center(
          child: Text('Batch not found or already dispatched.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cold Chain Dispatch'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Batch Info Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        batch.cropProfile.iconEmoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            batch.cropProfile.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Batch ${batch.batchId} • ${batch.quantityKg.toInt()} kg',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Origin: ${batch.unitName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'DESTINATION & TRANSIT MODE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              // Destination Mandi Dropdown
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedMandi,
                    items: _mandiOptions.map((mandi) {
                      return DropdownMenuItem<String>(
                        value: mandi,
                        child: Row(
                          children: [
                            const Icon(Icons.storefront_rounded,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                mandi,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedMandi = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Transit Mode Radio Selection Cards
              ...TransitMode.values.map((mode) {
                final isSelected = _selectedMode == mode;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => setState(() => _selectedMode = mode),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLight.withValues(alpha: 0.4)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(mode.iconEmoji,
                              style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      mode.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? AppColors.primaryDark
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (mode.hasActiveCooling) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  mode.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Temp envelope: ${mode.typicalTempRange}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),
              const Text(
                'LOGISTICS & VEHICLE DETAILS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              // Estimated Transit Hours Slider
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Transit Duration',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$_transitHours Hours',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _transitHours.toDouble(),
                      min: 1,
                      max: 12,
                      divisions: 11,
                      label: '$_transitHours Hours',
                      activeColor: AppColors.primary,
                      onChanged: (val) =>
                          setState(() => _transitHours = val.round()),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Vehicle Number & Driver Name
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _vehicleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Reg #',
                        prefixIcon: const Icon(Icons.pin_outlined, size: 18),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter vehicle #'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _driverNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Driver Name',
                        prefixIcon: const Icon(Icons.person_outline, size: 18),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter driver' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Driver Contact & Dispatch Notes
              TextFormField(
                controller: _driverPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Driver Contact Phone',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter phone #' : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Consignment / Buyer Special Notes (Optional)',
                  hintText: 'e.g., Gate 4 drop-off, auction lot 12',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Launch Transit Button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      ref
                          .read(transitManifestsProvider.notifier)
                          .dispatchBatchToTransit(
                            batch: batch,
                            destinationMandi: _selectedMandi ?? _mandiOptions.first,
                            transitMode: _selectedMode,
                            vehicleNumber: _vehicleCtrl.text.trim(),
                            driverName: _driverNameCtrl.text.trim(),
                            driverPhone: _driverPhoneCtrl.text.trim(),
                            estimatedTransitHours: _transitHours,
                            notes: _notesCtrl.text.trim(),
                          );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              '🚚 Cold-Chain Transit initiated! Live telemetry enabled.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );

                      // Navigate to Produce Screen (Active Transits Tab)
                      context.go('/produce');
                    }
                  },
                  icon: const Icon(Icons.local_shipping_rounded),
                  label: const Text(
                    'INITIATE COLD-CHAIN DISPATCH',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
