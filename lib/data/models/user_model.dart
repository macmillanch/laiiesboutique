class User {
  final String id;
  String get displayId => 'RKJ${id.padLeft(3, '0')}';
  final String phone;
  final String? email;
  final String? name;
  final String? profileImageUrl;
  final String role;

  User({
    required this.id,
    required this.phone,
    this.email,
    this.name,
    this.profileImageUrl,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      phone: json['phone'] ?? '',
      email: json['email'],
      name: json['name'],
      profileImageUrl: json['profile_image_url'],
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'name': name,
      'profile_image_url': profileImageUrl,
      'role': role,
    };
  }
}
