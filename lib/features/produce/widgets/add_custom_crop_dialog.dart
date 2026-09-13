import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/crop_profile.dart';
import '../../../services/crop/crop_condition_lookup_service.dart';
import '../../../state/produce_providers.dart';

class AddCustomCropDialog extends ConsumerStatefulWidget {
  final String initialName;

  const AddCustomCropDialog({
    super.key,
    required this.initialName,
  });

  static Future<CropProfile?> show(BuildContext context, String initialName) {
    return showModalBottomSheet<CropProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddCustomCropDialog(initialName: initialName),
    );
  }

  @override
  ConsumerState<AddCustomCropDialog> createState() =>
      _AddCustomCropDialogState();
}

class _AddCustomCropDialogState extends ConsumerState<AddCustomCropDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _tempMinController;
  late TextEditingController _tempMaxController;
  late TextEditingController _humidityMinController;
  late TextEditingController _humidityMaxController;
  late TextEditingController _storageDaysController;
  late TextEditingController _priceController;
  late TextEditingController _chillingTempController;
  late TextEditingController _adviceController;
  String _selectedEmoji = '🌱';

  bool _isFetching = true;
  String _fetchStatus = 'Fetching scientific cold-storage conditions...';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName.trim());
    _categoryController = TextEditingController(text: 'Fresh Produce');
    _tempMinController = TextEditingController(text: '4.0');
    _tempMaxController = TextEditingController(text: '8.0');
    _humidityMinController = TextEditingController(text: '90');
    _humidityMaxController = TextEditingController(text: '95');
    _storageDaysController = TextEditingController(text: '28');
    _priceController = TextEditingController(text: '40.0');
    _chillingTempController = TextEditingController(text: '2.0');
    _adviceController = TextEditingController();

    _fetchRealTimeConditions(widget.initialName.trim());
  }

  Future<void> _fetchRealTimeConditions(String name) async {
    if (name.isEmpty) return;

    setState(() {
      _isFetching = true;
      _fetchStatus = 'Querying agricultural database for "$name"...';
    });

    try {
      final conditions =
          await CropConditionLookupService.fetchConditionsForCrop(name);

      if (mounted) {
        setState(() {
          _isFetching = false;
          _selectedEmoji = conditions.iconEmoji;
          _categoryController.text = conditions.category;
          _tempMinController.text =
              conditions.optimalTempMin.toStringAsFixed(1);
          _tempMaxController.text =
              conditions.optimalTempMax.toStringAsFixed(1);
          _humidityMinController.text =
              conditions.optimalHumidityMin.toStringAsFixed(0);
          _humidityMaxController.text =
              conditions.optimalHumidityMax.toStringAsFixed(0);
          _storageDaysController.text = conditions.maxStorageDays.toString();
          _priceController.text =
              conditions.defaultPricePerKg.toStringAsFixed(0);
          _chillingTempController.text =
              conditions.chillingInjuryTemp.toStringAsFixed(1);
          _adviceController.text = conditions.storageAdvice;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFetching = false;
          _fetchStatus = 'Could not fetch automatically. Please fill manually.';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _tempMinController.dispose();
    _tempMaxController.dispose();
    _humidityMinController.dispose();
    _humidityMaxController.dispose();
    _storageDaysController.dispose();
    _priceController.dispose();
    _chillingTempController.dispose();
    _adviceController.dispose();
    super.dispose();
  }

  void _saveCrop() {
    if (!_formKey.currentState!.validate()) return;

    final tempMin = double.tryParse(_tempMinController.text) ?? 4.0;
    final tempMax = double.tryParse(_tempMaxController.text) ?? 8.0;
    final humMin = double.tryParse(_humidityMinController.text) ?? 90.0;
    final humMax = double.tryParse(_humidityMaxController.text) ?? 95.0;
    final days = int.tryParse(_storageDaysController.text) ?? 21;
    final price = double.tryParse(_priceController.text) ?? 40.0;
    final chill = double.tryParse(_chillingTempController.text) ?? 2.0;

    final customCrop = CropProfile(
      id: 'CUSTOM-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      iconEmoji: _selectedEmoji,
      optimalTempMin: tempMin,
      optimalTempMax: tempMax,
      optimalHumidityMin: humMin,
      optimalHumidityMax: humMax,
      maxStorageDays: days,
      defaultPricePerKg: price,
      chillingInjuryTemp: chill,
      storageAdvice: _adviceController.text.trim().isNotEmpty
          ? _adviceController.text.trim()
          : 'Store at ${tempMin.toStringAsFixed(0)}°C - ${tempMax.toStringAsFixed(0)}°C with high humidity.',
      isCustom: true,
      aliases: [_nameController.text.trim()],
    );

    // Save to user custom crops provider
    ref.read(userCustomCropsProvider.notifier).addCustomCrop(customCrop);

    Navigator.of(context).pop(customCrop);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_selectedEmoji,
                        style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Vegetable / Crop',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Real-time condition derivation engine',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Real-Time Fetching Indicator
              if (_isFetching) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondaryContainer),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _fetchStatus,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusGoodBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.statusGood.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.statusGood, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Conditions fetched in real time. You can review or customize parameters below.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusGood,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Vegetable Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Vegetable / Crop Name',
                  hintText: 'e.g. Oyster Mushroom, Purple Cabbage',
                  prefixIcon:
                      const Icon(Icons.eco_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    tooltip: 'Re-fetch conditions',
                    onPressed: () =>
                        _fetchRealTimeConditions(_nameController.text),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a vegetable name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Category Field
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Botanical Category',
                  hintText: 'e.g. Leafy Greens, Cucurbit, Tuber',
                  prefixIcon: const Icon(Icons.category_outlined,
                      color: AppColors.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Temperature Section
              const Text(
                'COLD STORAGE TEMPERATURE CONDITIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempMinController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      decoration: InputDecoration(
                        labelText: 'Min Temp (°C)',
                        prefixIcon: const Icon(Icons.thermostat,
                            color: AppColors.secondary, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _tempMaxController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      decoration: InputDecoration(
                        labelText: 'Max Temp (°C)',
                        prefixIcon: const Icon(Icons.thermostat,
                            color: AppColors.primary, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Humidity Section
              const Text(
                'RELATIVE HUMIDITY CONDITIONS (%)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _humidityMinController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Min RH (%)',
                        prefixIcon: const Icon(Icons.water_drop_outlined,
                            color: AppColors.secondary, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _humidityMaxController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Max RH (%)',
                        prefixIcon: const Icon(Icons.water_drop,
                            color: AppColors.primary, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Shelf Life & Chilling Injury
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _storageDaysController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Max Shelf Life (Days)',
                        prefixIcon: const Icon(Icons.calendar_month,
                            color: AppColors.primary, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _chillingTempController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      decoration: InputDecoration(
                        labelText: 'Chilling Injury (< °C)',
                        prefixIcon: const Icon(Icons.ac_unit,
                            color: AppColors.statusCritical, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Baseline Market Rate (₹/kg)
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Wholesale Baseline Rate (₹/kg)',
                  prefixIcon: const Icon(Icons.currency_rupee,
                      color: AppColors.statusGood, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // Storage Advice
              TextFormField(
                controller: _adviceController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Farmer Storage Advice',
                  hintText:
                      'Actionable tips on ventilation, pre-cooling, ethylene sensitivity',
                  prefixIcon: const Icon(Icons.lightbulb_outline,
                      color: AppColors.statusWarning, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text(
                        'Save & Select Vegetable',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: _saveCrop,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
