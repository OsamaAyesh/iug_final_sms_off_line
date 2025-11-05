// المسار: lib/features/contacts/data/request/add_contact_request.dart

class AddContactRequest {
  final String name;
  final String phone;
  final String? imageUrl;

  AddContactRequest({
    required this.name,
    required this.phone,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'phoneCanon': _normalizePhone(phone),
    if (imageUrl != null) 'imageUrl': imageUrl,
    'createdAt': DateTime.now().toIso8601String(),
  };

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }
}