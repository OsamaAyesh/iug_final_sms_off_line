class UserModel {
  final String name;
  final String phone;
  final String phoneCanon;
  final bool isVerified;

  UserModel({
    required this.name,
    required this.phone,
    required this.phoneCanon,
    required this.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json["name"] ?? "",
      phone: json["phone"] ?? "",
      phoneCanon: json["phoneCanon"] ?? "",
      isVerified: json["isVerified"] ?? false,
    );
  }
}
