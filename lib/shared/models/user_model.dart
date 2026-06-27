enum UserRole { POLICE, CITOYEN, ADMIN }

UserRole userRoleFromString(String? s) {
  switch (s) {
    case 'POLICE':  return UserRole.POLICE;
    case 'CITOYEN': return UserRole.CITOYEN;
    case 'ADMIN':   return UserRole.ADMIN;
    default:        return UserRole.CITOYEN;
  }
}

String userRoleLabel(UserRole role) {
  switch (role) {
    case UserRole.POLICE:  return 'Police';
    case UserRole.CITOYEN: return 'Citoyen';
    case UserRole.ADMIN:   return 'Admin';
  }
}

class UserModel {
  final String id;
  final String email;
  final String prenom;
  final String nom;
  final UserRole role;
  final bool actif;
  final DateTime createdAt;
  final String? telephone;
  final String? photoUrl;
  final int? finesCount;

  const UserModel({
    required this.id,
    required this.email,
    required this.prenom,
    required this.nom,
    required this.role,
    required this.actif,
    required this.createdAt,
    this.telephone,
    this.photoUrl,
    this.finesCount,
  });

  String get fullName => '$prenom $nom'.trim();

  String get avatarInitials {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    if (p.isNotEmpty && n.isNotEmpty) return '$p$n';
    if (p.isNotEmpty) return p;
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Supporte deux formats : { prenom, nom } ou { name } (split sur espace)
    String prenom = json['prenom'] as String? ?? '';
    String nom = json['nom'] as String? ?? '';
    if (prenom.isEmpty && nom.isEmpty) {
      final name = (json['name'] as String? ?? '').trim();
      final parts = name.split(' ');
      prenom = parts.isNotEmpty ? parts.first : '';
      nom = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      prenom: prenom,
      nom: nom,
      role: userRoleFromString(json['role'] as String?),
      actif: json['actif'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime(2024),
      telephone: json['telephone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      finesCount: (json['finesCount'] as num?)?.toInt(),
    );
  }
}
