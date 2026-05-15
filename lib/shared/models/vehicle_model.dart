class VehicleModel {
  final String id;
  final String plate;
  final String brand;
  final String model;
  final String color;
  final int year;
  final String type;
  final String ownerName;
  final DateTime registrationExpiry;
  final bool hasInsurance;
  final DateTime? insuranceExpiry;

  const VehicleModel({
    required this.id,
    required this.plate,
    required this.brand,
    required this.model,
    required this.color,
    required this.year,
    required this.type,
    required this.ownerName,
    required this.registrationExpiry,
    required this.hasInsurance,
    this.insuranceExpiry,
  });

  static VehicleModel get mockVehicle => VehicleModel(
        id: 'VEH001',
        plate: 'BZV-4521-A',
        brand: 'Toyota',
        model: 'Corolla',
        color: 'Blanc',
        year: 2019,
        type: 'Véhicule léger',
        ownerName: 'Thierry Nguesso',
        registrationExpiry: DateTime.now().add(const Duration(days: 180)),
        hasInsurance: true,
        insuranceExpiry: DateTime.now().add(const Duration(days: 90)),
      );

  static List<VehicleModel> get mockVehicles => [
        mockVehicle,
        VehicleModel(
          id: 'VEH002',
          plate: 'PNR-1123-B',
          brand: 'Honda',
          model: 'CB 125',
          color: 'Rouge',
          year: 2021,
          type: 'Motocyclette',
          ownerName: 'Cédric Okemba',
          registrationExpiry: DateTime.now().subtract(const Duration(days: 30)),
          hasInsurance: false,
        ),
        VehicleModel(
          id: 'VEH003',
          plate: 'BZV-9876-C',
          brand: 'Peugeot',
          model: '308',
          color: 'Gris',
          year: 2018,
          type: 'Véhicule léger',
          ownerName: 'Pauline Massamba',
          registrationExpiry: DateTime.now().add(const Duration(days: 270)),
          hasInsurance: true,
          insuranceExpiry: DateTime.now().add(const Duration(days: 200)),
        ),
      ];
}
