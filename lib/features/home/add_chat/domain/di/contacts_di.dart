// المسار: lib/features/contacts/domain/di/contacts_di.dart

import 'package:get/get.dart';
import '../../data/data_source/contacts_remote_data_source.dart';
import '../../data/repository/contacts_repository.dart';
import '../../data/repository/contacts_repository_impl.dart';
import '../../presentation/controller/contacts_controller.dart'; // ✅ المسار الصحيح
import '../use_cases/get_all_contacts_usecase.dart';
import '../use_cases/add_contact_usecase.dart';
import '../use_cases/find_contact_by_phone_usecase.dart';

class ContactsDI {
  static void init() {
    // Data Source
    Get.lazyPut<ContactsRemoteDataSource>(
          () => ContactsRemoteDataSourceImpl(),
      fenix: true,
    );

    // Repository
    Get.lazyPut<ContactsRepository>(
          () => ContactsRepositoryImpl(
        remoteDataSource: Get.find<ContactsRemoteDataSource>(),
      ),
      fenix: true,
    );

    // Use Cases
    Get.lazyPut(
          () => GetAllContactsUseCase(Get.find<ContactsRepository>()),
      fenix: true,
    );

    Get.lazyPut(
          () => AddContactUseCase(Get.find<ContactsRepository>()),
      fenix: true,
    );

    Get.lazyPut(
          () => FindContactByPhoneUseCase(Get.find<ContactsRepository>()),
      fenix: true,
    );

    // Controller - ✅ المسار الصحيح الآن
    Get.lazyPut(
          () => ContactsController(
        getAllContactsUseCase: Get.find<GetAllContactsUseCase>(),
        addContactUseCase: Get.find<AddContactUseCase>(),
        findContactByPhoneUseCase: Get.find<FindContactByPhoneUseCase>(),
      ),
    );
  }

  static void dispose() {
    Get.delete<ContactsController>();
    Get.delete<GetAllContactsUseCase>();
    Get.delete<AddContactUseCase>();
    Get.delete<FindContactByPhoneUseCase>();
    Get.delete<ContactsRepository>();
    Get.delete<ContactsRemoteDataSource>();
  }
}