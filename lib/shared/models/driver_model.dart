class DriverModel {
  final String id;
  final String licenseNumber;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String address;
  final String phone;
  final String licenseCategory;
  final DateTime licenseIssued;
  final DateTime licenseExpiry;
  final int totalPoints;
  final int remainingPoints;
  final bool isSuspended;
  final int totalFines;
  final int unpaidFines;
  final int totalAmount;

  const DriverModel({
    required this.id,
    required this.licenseNumber,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.address,
    required this.phone,
    required this.licenseCategory,
    required this.licenseIssued,
    required this.licenseExpiry,
    required this.totalPoints,
    required this.remainingPoints,
    required this.isSuspended,
    required this.totalFines,
    required this.unpaidFines,
    required this.totalAmount,
  });

  String get fullName => '$firstName $lastName';
  bool get licenseExpired => licenseExpiry.isBefore(DateTime.now());
  bool get licenseExpiringSoon =>
      licenseExpiry.isAfter(DateTime.now()) &&
      licenseExpiry.isBefore(DateTime.now().add(const Duration(days: 30)));

  static DriverModel get mockDriver => DriverModel(
        id: 'DRV001',
        licenseNumber: 'BZV-2024-047821',
        firstName: 'Thierry',
        lastName: 'Nguesso',
        birthDate: DateTime(1988, 4, 15),
        address: 'Avenue de la Paix, Quartier Poto-Poto, Brazzaville',
        phone: '+242 06 789 0123',
        licenseCategory: 'B',
        licenseIssued: DateTime(2015, 6, 20),
        licenseExpiry: DateTime(2025, 6, 20),
        totalPoints: 12,
        remainingPoints: 9,
        isSuspended: false,
        totalFines: 3,
        unpaidFines: 1,
        totalAmount: 65000,
      );
}
