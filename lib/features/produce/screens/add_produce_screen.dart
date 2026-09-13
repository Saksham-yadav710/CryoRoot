import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/crop_profile.dart';
import '../../../models/produce_batch.dart';
import '../../../state/produce_providers.dart';
import '../../../state/storage_providers.dart';

class AddProduceScreen extends ConsumerStatefulWidget {
  const AddProduceScreen({super.key});

  @override
  ConsumerState<AddProduceScreen> createState() => _AddProduceScreenState();
}

class _AddProduceScreenState extends ConsumerState<AddProduceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  CropProfile? _selectedCrop;
  String? _selectedUnitId;
  DateTime _entryDate = DateTime.now();
  DateTime? _targetSellingDate;
  late String _nextBatchId;

  @override
  void initState() {
    super.initState();
    final profiles = ref.read(cropProfilesProvider);
    if (profiles.isNotEmpty) {
      _selectedCrop = profiles.first;
    }
    final units = ref.read(storageUnitsProvider);
    if (units.isNotEmpty) {
      _selectedUnitId = units.first.id;
    }
    _nextBatchId =
        ref.read(produceBatchesProvider.notifier).generateNextBatchId();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cropProfiles = ref.watch(cropProfilesProvider);
    final units = ref.watch(storageUnitsProvider);
    final nextBatchId = _nextBatchId;

    final selectedUnit = units.firstWhere(
      (u) => u.id == _selectedUnitId,
      orElse: () => units.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Produce Intake & Batching'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Batch ID Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryContainer),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEW BATCH ASSIGNMENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Auto-generated QR Tracking ID',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        nextBatchId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 2. Select Crop Profile
              const Text(
                'SELECT CROP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CropProfile>(
                    value: _selectedCrop,
                    isExpanded: true,
                    items: cropProfiles.map((crop) {
                      return DropdownMenuItem<CropProfile>(
                        value: crop,
                        child: Row(
                          children: [
                            Text(crop.iconEmoji,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${crop.name} (${crop.category})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (crop) {
                      setState(() {
                        _selectedCrop = crop;
                      });
                    },
                  ),
                ),
              ),

              if (_selectedCrop != null) ...[
                const SizedBox(height: 10),
                // Live Scientific Crop Advice Callout
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Optimal Temp: ${_selectedCrop!.tempRangeFormatted}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                          Text(
                            'Humidity: ${_selectedCrop!.humidityRangeFormatted}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedCrop!.storageAdvice,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // 3. Select Storage Unit Destination
              const Text(
                'DESTINATION STORAGE UNIT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedUnitId,
                    isExpanded: true,
                    items: units.map((u) {
                      final availableKg = u.capacityKg - u.currentOccupancyKg;
                      return DropdownMenuItem<String>(
                        value: u.id,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${u.name} (${u.village})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${availableKg}kg free',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: availableKg > 500
                                    ? AppColors.statusGood
                                    : AppColors.statusWarning,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedUnitId = val;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 4. Quantity (Kg)
              const Text(
                'QUANTITY (KG)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 500',
                  filled: true,
                  fillColor: AppColors.surface,
                  suffixText: 'kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter quantity in kg';
                  }
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) {
                    return 'Please enter a valid positive weight';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // 5. Entry Date & Target Selling Date Picker
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ENTRY DATE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _entryDate,
                              firstDate: DateTime(2025),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _entryDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd MMM yyyy').format(_entryDate),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TARGET SELL DATE (OPTIONAL)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _targetSellingDate ??
                                  DateTime.now().add(const Duration(days: 14)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _targetSellingDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_available_rounded,
                                    size: 16, color: AppColors.secondary),
                                const SizedBox(width: 8),
                                Text(
                                  _targetSellingDate != null
                                      ? DateFormat('dd MMM yyyy')
                                          .format(_targetSellingDate!)
                                      : 'Set Date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _targetSellingDate != null
                                        ? AppColors.textPrimary
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 6. Notes & Harvest Details
              const Text(
                'HARVEST & QUALITY NOTES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText:
                      'e.g. Grade A harvest from North field, washed & sorted.',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 7. Save & Intake Produce Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      _selectedCrop != null &&
                      _selectedUnitId != null) {
                    final double qty =
                        double.parse(_quantityController.text.trim());

                    final newBatch = ProduceBatch(
                      batchId: nextBatchId,
                      cropProfile: _selectedCrop!,
                      quantityKg: qty,
                      unitId: selectedUnit.id,
                      unitName: selectedUnit.name,
                      entryDate: _entryDate,
                      targetSellingDate: _targetSellingDate,
                      notes: _notesController.text.trim(),
                    );

                    ref
                        .read(produceBatchesProvider.notifier)
                        .addBatch(newBatch);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Batch $nextBatchId (${_selectedCrop!.name}) successfully stored in ${selectedUnit.name}!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );

                    context.pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'CONFIRM PRODUCE INTAKE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
