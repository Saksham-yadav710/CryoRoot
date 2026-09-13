import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/auth_providers.dart';

class FarmerRegistrationDialog extends ConsumerStatefulWidget {
  const FarmerRegistrationDialog({super.key});

  @override
  ConsumerState<FarmerRegistrationDialog> createState() =>
      _FarmerRegistrationDialogState();
}

class _FarmerRegistrationDialogState
    extends ConsumerState<FarmerRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _villageController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _isLoading = false;
  String? _localError;

  final Set<String> _selectedUnits = {'AC-NER-001'};

  final List<Map<String, String>> _availableUnits = [
    {
      'id': 'AC-NER-001',
      'name': 'Cold Storage 1',
      'village': 'Sonapur, Kamrup Metro (Assam)'
    },
    {
      'id': 'AC-NER-002',
      'name': 'Cold Storage 2',
      'village': 'Barapani, Ri-Bhoi (Meghalaya)'
    },
    {
      'id': 'AC-NER-003',
      'name': 'Cold Storage 3',
      'village': 'Sonitpur Orchard Unit (Assam)'
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _autofillDemo() {
    setState(() {
      _nameController.text = 'Tenzing Norbu';
      _phoneController.text = '98111 22334';
      _villageController.text = 'Barapani, Ri-Bhoi';
      _pinController.text = '7788';
      _confirmPinController.text = '7788';
      _selectedUnits.clear();
      _selectedUnits.addAll({'AC-NER-001', 'AC-NER-002'});
      _localError = null;
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin != confirmPin) {
      setState(() {
        _localError = 'PINs do not match. Please enter the same 4-digit PIN in both fields.';
      });
      return;
    }

    if (_selectedUnits.isEmpty) {
      setState(() {
        _localError = 'Please select at least one Cold Storage unit to link to your account.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _localError = null;
    });

    final success = await ref.read(authStateProvider.notifier).registerFarmer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          pin: pin,
          ownedUnitIds: _selectedUnits.toList(),
          village: _villageController.text.trim().isNotEmpty
              ? _villageController.text.trim()
              : null,
        );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Welcome to CryoRoots, ${_nameController.text.trim()}! Your account is created.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      try {
        context.go('/');
      } catch (_) {}
    } else {
      final globalError = ref.read(authStateProvider).errorMessage;
      setState(() {
        _localError = globalError ?? 'Registration failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Farmer Registration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Create your account to control cold storages',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick Demo Autofill chip
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: const Icon(Icons.bolt_rounded,
                        size: 16, color: AppColors.primary),
                    label: const Text(
                      'Demo Fill: Tenzing Norbu',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: AppColors.primaryLight,
                    onPressed: _autofillDemo,
                  ),
                ),
                const SizedBox(height: 12),

                // Error Callout Banner if any
                if (_localError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.statusCriticalBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.statusCriticalBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.statusCritical, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _localError!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.statusCritical,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Full Name
                const Text(
                  'Full Name *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  key: const Key('register_name_field'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_rounded, size: 20),
                    hintText: 'e.g. Ramesh Gogoi',
                    filled: true,
                    fillColor: const Color(0xFFF8FAF8),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Mobile Number
                const Text(
                  'Mobile Number * (10 Digits)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  key: const Key('register_phone_field'),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                    hintText: 'e.g. 98123 45678',
                    filled: true,
                    fillColor: const Color(0xFFF8FAF8),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
                    ),
                  ),
                  validator: (value) {
                    final clean = (value ?? '').replaceAll(RegExp(r'\D'), '');
                    if (clean.length < 10) {
                      return 'Please enter a valid 10-digit phone number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Village / District
                const Text(
                  'Village / Block / District (Optional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _villageController,
                  key: const Key('register_village_field'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_rounded, size: 20),
                    hintText: 'e.g. Sonapur, Kamrup Metro (Assam)',
                    filled: true,
                    fillColor: const Color(0xFFF8FAF8),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Assigned Cold Storage Chambers
                const Text(
                  'Select Your Cold Storage Chamber(s) *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'You will have owner permissions to control temperatures for selected units.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Column(
                  children: _availableUnits.map((unit) {
                    final isChecked = _selectedUnits.contains(unit['id']);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isChecked) {
                            if (_selectedUnits.length > 1) {
                              _selectedUnits.remove(unit['id']);
                            }
                          } else {
                            _selectedUnits.add(unit['id']!);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isChecked
                              ? AppColors.primaryContainer.withValues(alpha: 0.35)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isChecked
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedUnits.add(unit['id']!);
                                  } else if (_selectedUnits.length > 1) {
                                    _selectedUnits.remove(unit['id']);
                                  }
                                });
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    unit['name']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isChecked
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isChecked
                                          ? AppColors.primaryDark
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    unit['village']!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // 4-Digit Security PIN and Confirm PIN in Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Choose 4-Digit PIN *',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _pinController,
                            key: const Key('register_pin_field'),
                            obscureText: _obscurePin,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: InputDecoration(
                              counterText: '',
                              prefixIcon:
                                  const Icon(Icons.pin_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePin
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePin = !_obscurePin),
                              ),
                              hintText: '4 digits',
                              filled: true,
                              fillColor: const Color(0xFFF8FAF8),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFDCDCDC)),
                              ),
                            ),
                            validator: (val) {
                              if (val == null ||
                                  val.trim().length != 4 ||
                                  int.tryParse(val.trim()) == null) {
                                return '4 digits';
                              }
                              return null;
                            },
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
                            'Confirm PIN *',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmPinController,
                            key: const Key('register_confirm_pin_field'),
                            obscureText: _obscureConfirmPin,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: InputDecoration(
                              counterText: '',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPin
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                ),
                                onPressed: () => setState(() =>
                                    _obscureConfirmPin = !_obscureConfirmPin),
                              ),
                              hintText: 'Re-enter PIN',
                              filled: true,
                              fillColor: const Color(0xFFF8FAF8),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFDCDCDC)),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    key: const Key('submit_farmer_registration_btn'),
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.how_to_reg_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'CREATE ACCOUNT & LOG IN',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
