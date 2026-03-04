/// Represents a Helix user profile.
class User {
  final String? id;
  final String email;
  final String? name;
  final String? genotype;
  final String? bloodGroup;

  const User({
    this.id,
    required this.email,
    this.name,
    this.genotype,
    this.bloodGroup,
  });

  /// Create a [User] from a JSON map returned by the API.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      email: json['email'] as String,
      name: json['name'] as String?,
      genotype: json['genotype'] as String?,
      bloodGroup: json['blood_group'] as String?,
    );
  }

  /// Serialize to JSON for API requests.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'email': email,
      if (name != null) 'name': name,
      if (genotype != null) 'genotype': genotype,
      if (bloodGroup != null) 'blood_group': bloodGroup,
    };
  }

  /// Returns a copy with updated fields.
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? genotype,
    String? bloodGroup,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      genotype: genotype ?? this.genotype,
      bloodGroup: bloodGroup ?? this.bloodGroup,
    );
  }
}
