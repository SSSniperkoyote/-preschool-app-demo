class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      role: json['role'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
