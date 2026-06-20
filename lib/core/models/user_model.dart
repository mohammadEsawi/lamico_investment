class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String? profileImage;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.profileImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? '',
        isActive: json['isActive'] ?? true,
        profileImage: json['profileImage'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'isActive': isActive,
        'profileImage': profileImage,
      };

  String get roleArabic {
    switch (role) {
      case 'ADMIN':       return 'مدير';
      case 'ENGINEER':    return 'مهندس';
      case 'ACCOUNTANT':  return 'محاسب';
      case 'WORKER':      return 'عامل';
      case 'SALES_REP':   return 'مندوب مبيعات';
      default:            return role;
    }
  }
}
