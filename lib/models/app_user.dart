enum UserRole {
  farmer,
  technician,
}

class AppUser {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final List<String> ownedUnitIds;

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.ownedUnitIds = const [],
  });

  bool get isFarmer => role == UserRole.farmer;
  bool get isTechnician => role == UserRole.technician;

  // Pre-configured personas for testing and active demo
  static const AppUser farmerA = AppUser(
    id: 'farmer-a',
    name: 'Ramesh Patel (Farmer A)',
    phone: '+91 98765 11001',
    role: UserRole.farmer,
    ownedUnitIds: ['AC-NER-001', 'AC-NER-002'],
  );

  static const AppUser farmerB = AppUser(
    id: 'farmer-b',
    name: 'Suresh Kumar (Farmer B)',
    phone: '+91 98765 22002',
    role: UserRole.farmer,
    ownedUnitIds: ['AC-NER-003'],
  );

  static const AppUser technician = AppUser(
    id: 'tech-01',
    name: 'Bikash Sharma (Field Technician)',
    phone: '+91 98765 33003',
    role: UserRole.technician,
    ownedUnitIds: [],
  );

  static List<AppUser> get allUsers => [farmerA, farmerB, technician];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
