// المسار: lib/features/contacts/data/mapper/contact_mapper.dart

import '../response/contact_response.dart';
import '../../domain/models/contact_model.dart';

class ContactMapper {
  static ContactModel toModel(ContactResponse response) {
    return ContactModel(
      id: response.id,
      name: response.name,
      phone: response.phone,
      imageUrl: response.imageUrl,
      bio: response.bio,
      lastSeen: response.lastSeen != null
          ? DateTime.parse(response.lastSeen!)
          : null,
      isOnline: response.isOnline,
      createdAt: DateTime.parse(response.createdAt),
    );
  }

  static List<ContactModel> toModelList(List<ContactResponse> responses) {
    return responses.map((response) => toModel(response)).toList();
  }

  static ContactResponse toResponse(ContactModel model) {
    return ContactResponse(
      id: model.id,
      name: model.name,
      phone: model.phone,
      phoneCanon: _normalizePhone(model.phone),
      imageUrl: model.imageUrl,
      bio: model.bio,
      lastSeen: model.lastSeen?.toIso8601String(),
      isOnline: model.isOnline,
      createdAt: model.createdAt.toIso8601String(),
    );
  }

  static String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }
}