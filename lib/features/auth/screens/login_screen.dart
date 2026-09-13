import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int _selectedTabIndex = 0; // 0: Farmer, 1: Technician

  // Farmer Form
  final _farmerIdController = TextEditingController(text: '98765 11001');
  final _farmerPinController = TextEditingController(text: '1234');
  bool _obscureFarmerPin = true;

  // Technician Form
  final _techIdController = TextEditingController(text: 'tech-01');
  final _techPasswordController = TextEditingController(text: 'tech123');
  bool _obscureTechPassword = true;

  @override
  void dispose() {
    _farmerIdController.dispose();
    _farmerPinController.dispose();
    _techIdController.dispose();
    _techPasswordController.dispose();
    super.dispose();
  }

  void _autofillFarmerA() {
    setState(() {
      _farmerIdController.text = '98765 11001';
      _farmerPinController.text = '1234';
    });
    ref.read(authStateProvider.notifier).clearError();
  }

  void _autofillFarmerB() {
    setState(() {
      _farmerIdController.text = '98765 22002';
      _farmerPinController.text = '1234';
    });
    ref.read(authStateProvider.notifier).clearError();
  }

  void _autofillTechnician() {
    setState(() {
      _techIdController.text = 'tech-01';
      _techPasswordController.text = 'tech123';
    });
    ref.read(authStateProvider.notifier).clearError();
  }

  Future<void> _handleFarmerLogin() async {
    final success = await ref.read(authStateProvider.notifier).loginFarmer(
          identifier: _farmerIdController.text,
          pinOrPassword: _farmerPinController.text,
          rememberMe: true, // Auto-login preserved until explicit logout
        );
    if (success && mounted) {
      try {
        context.go('/');
      } catch (_) {
        // Safe fallback in widget tests without GoRouter ancestor
      }
    }
  }

  Future<void> _handleTechnicianLogin() async {
    final success = await ref.read(authStateProvider.notifier).loginTechnician(
          userId: _techIdController.text,
          password: _techPasswordController.text,
          rememberMe: true,
        );
    if (success && mounted) {
      try {
        context.go('/');
      } catch (_) {
        // Safe fallback in widget tests without GoRouter ancestor
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F2310), // Deep agro-cryo dark
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. App Branding Hero
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // 2. Main Login Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(64),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Portal Role Switcher
                        _buildRoleSegmentedButton(),
                        const SizedBox(height: 20),

                        // Error Banner if present
                        if (authState.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDE8E8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE53935),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFD32F2F), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authState.errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFC62828),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Tab Content
                        if (_selectedTabIndex == 0)
                          _buildFarmerForm(authState.isLoading)
                        else
                          _buildTechnicianForm(authState.isLoading),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Footer Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.solar_power_rounded,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'CryoRoots Solar Cold Storage • NER India Grid',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withAlpha(178),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF00897B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withAlpha(102),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.ac_unit_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Cryo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Roots',
              style: TextStyle(
                color: Color(0xFF81C784),
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Smart Solar Cold Storage & Telemetry Portal',
          style: TextStyle(
            color: Colors.white.withAlpha(204),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSegmentedButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F2),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTabIndex = 0);
                ref.read(authStateProvider.notifier).clearError();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(76),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.agriculture_rounded,
                      size: 18,
                      color: _selectedTabIndex == 0
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Farmer Portal',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _selectedTabIndex == 0
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTabIndex = 1);
                ref.read(authStateProvider.notifier).clearError();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1
                      ? const Color(0xFF1E3A8A)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1E3A8A).withAlpha(76),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.build_rounded,
                      size: 17,
                      color: _selectedTabIndex == 1
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Technician Portal',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _selectedTabIndex == 1
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Persistent Login Guarantee Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA5D6A7)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_clock_rounded,
                  color: Color(0xFF2E7D32), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Auto-Login Active: Once logged in, you remain logged in on this device until you explicitly log out.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Phone or Farmer ID
        const Text(
          'Mobile Number / Farmer ID',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _farmerIdController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
            hintText: 'e.g. 98765 11001 or farmer-a',
            filled: true,
            fillColor: const Color(0xFFF8FAF8),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 4-Digit PIN
        const Text(
          '4-Digit Security PIN',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _farmerPinController,
          obscureText: _obscureFarmerPin,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.pin_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureFarmerPin
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureFarmerPin = !_obscureFarmerPin),
            ),
            hintText: 'Enter 4-digit PIN (Demo: 1234)',
            filled: true,
            fillColor: const Color(0xFFF8FAF8),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // One-tap Demo Autofill Chips
        const Text(
          'Quick Demo Login:',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ActionChip(
              avatar: const Icon(Icons.person, size: 14, color: AppColors.primary),
              label: const Text('Farmer Ramesh (A)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFFE8F5E9),
              onPressed: _autofillFarmerA,
            ),
            ActionChip(
              avatar: const Icon(Icons.person_outline,
                  size: 14, color: Color(0xFF00897B)),
              label: const Text('Farmer Suresh (B)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFFE0F2F1),
              onPressed: _autofillFarmerB,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleFarmerLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
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
                      Icon(Icons.login_rounded, size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'LOG IN AS FARMER',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Technician Access Note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined,
                  color: Color(0xFF1D4ED8), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hardware Diagnostics & Calibration Access. Only authorized cold-chain technicians can log in.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E40AF),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Technician ID
        const Text(
          'Technician Service ID / Email',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _techIdController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            hintText: 'e.g. tech-01 or admin@cryoroot.com',
            filled: true,
            fillColor: const Color(0xFFF8FAF8),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Password
        const Text(
          'Service Password',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _techPasswordController,
          obscureText: _obscureTechPassword,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureTechPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureTechPassword = !_obscureTechPassword),
            ),
            hintText: 'Enter password (Demo: tech123)',
            filled: true,
            fillColor: const Color(0xFFF8FAF8),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Demo Chip
        const Text(
          'Quick Demo Technician:',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        ActionChip(
          avatar: const Icon(Icons.engineering_rounded,
              size: 14, color: Color(0xFF1E3A8A)),
          label: const Text('Tech Bikash (tech-01 / tech123)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFEFF6FF),
          onPressed: _autofillTechnician,
        ),
        const SizedBox(height: 20),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleTechnicianLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
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
                      Icon(Icons.verified_user_rounded, size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'VERIFY & ENTER AS TECHNICIAN',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
