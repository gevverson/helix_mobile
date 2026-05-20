/// Represents a Helix user profile returned by GET /api/v1/users/me.
class User {
  final String? id;
  final String email;
  final String? fullName;
  final String? genotype;
  final String? bloodGroup;
  final String? rhesus;

  const User({
    this.id,
    required this.email,
    this.fullName,
    this.genotype,
    this.bloodGroup,
    this.rhesus,
  });

  /// Create a [User] from the API response:
  /// { id, email, full_name, bio_profile: { genotype, blood_group, rhesus_factor } }
  factory User.fromJson(Map<String, dynamic> json) {
    final bio = json['bio_profile'] as Map<String, dynamic>?;
    return User(
      id: json['id']?.toString(),
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      genotype: bio?['genotype'] as String?,
      bloodGroup: bio?['blood_group'] as String?,
      rhesus: bio?['rhesus_factor'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'email': email,
      if (fullName != null) 'full_name': fullName,
      if (genotype != null) 'genotype': genotype,
      if (bloodGroup != null) 'blood_group': bloodGroup,
      if (rhesus != null) 'rhesus_factor': rhesus,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? genotype,
    String? bloodGroup,
    String? rhesus,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      genotype: genotype ?? this.genotype,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      rhesus: rhesus ?? this.rhesus,
    );
  }
}
