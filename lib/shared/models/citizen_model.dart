class CitizenModel {
  final String id;
  final String nationalId;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String address;
  final String city;
  final DateTime birthDate;
  final String licenseNumber;
  final int licensePoints;
  final bool licenseValid;
  final DateTime licenseExpiry;
  final int pendingFines;
  final int totalDebt;

  const CitizenModel({
    required this.id,
    required this.nationalId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.birthDate,
    required this.licenseNumber,
    required this.licensePoints,
    required this.licenseValid,
    required this.licenseExpiry,
    required this.pendingFines,
    required this.totalDebt,
  });

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';

  static CitizenModel get mockCitizen => CitizenModel(
        id: 'CIT001',
        nationalId: 'CG-1988-047821',
        firstName: 'Thierry',
        lastName: 'Nguesso',
        phone: '+242 06 789 0123',
        email: 'thierry.nguesso@email.cg',
        address: 'Avenue de la Paix, Poto-Poto',
        city: 'Brazzaville',
        birthDate: DateTime(1988, 4, 15),
        licenseNumber: 'BZV-2024-047821',
        licensePoints: 9,
        licenseValid: true,
        licenseExpiry: DateTime(2025, 6, 20),
        pendingFines: 1,
        totalDebt: 30000,
      );
}
