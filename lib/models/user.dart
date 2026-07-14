/// Represents a Helix user profile returned by GET /api/v1/users/me.
class User {
  final String? id;
  final String email;
  final String? fullName;
  final String? genotype;
  final String? bloodGroup;
  final String? rhesus;

  // Dating profile (Phase 1)
  final String? dateOfBirth; // ISO yyyy-MM-dd
  final int? age;
  final String? gender;
  final String? seeking;
  final String? bio;
  final String? city;

  const User({
    this.id,
    required this.email,
    this.fullName,
    this.genotype,
    this.bloodGroup,
    this.rhesus,
    this.dateOfBirth,
    this.age,
    this.gender,
    this.seeking,
    this.bio,
    this.city,
  });

  /// Create a [User] from the API response:
  /// { id, email, full_name, date_of_birth, age, gender, seeking, bio,
  ///   bio_profile: { genotype, blood_group, rhesus_factor } }
  factory User.fromJson(Map<String, dynamic> json) {
    final bio = json['bio_profile'] as Map<String, dynamic>?;
    return User(
      id: json['id']?.toString(),
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      genotype: bio?['genotype'] as String?,
      bloodGroup: bio?['blood_group'] as String?,
      rhesus: bio?['rhesus_factor'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      seeking: json['seeking'] as String?,
      bio: json['bio'] as String?,
      city: json['city'] as String?,
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
    String? dateOfBirth,
    int? age,
    String? gender,
    String? seeking,
    String? bio,
    String? city,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      genotype: genotype ?? this.genotype,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      rhesus: rhesus ?? this.rhesus,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      seeking: seeking ?? this.seeking,
      bio: bio ?? this.bio,
      city: city ?? this.city,
    );
  }
}
