import 'package:easy_localization/easy_localization.dart';

/// A class defined for strings the app
class ManagerStrings {

  ///Login Screen Strings.
  static String get loginTitleScreen => "ابدأ التواصل الآن";
  static String get loginSubTitleScreen => "أدخل رقم جوالك وابدأ استخدام تطبيق Offline SMS للتواصل بسهولة وبدون انترنت";
  static String get loginPrivacyPolicy => "بالضغط على تسجيل مستخدم جديد، فانت توافق على سياسة الاستخدام والخصوصية!";
  static String get enterDataLogin => "أدخل المعلومات التالية";
  static String get enterDataLogin1 => "الاسم بالكامل";
  static String get enterDataLogin2 => "رقم الهاتف";
  static String get enterDataLogin3 => "يجب أن يبدأ رقم الهاتف بـ 05";
  static String get enterDataLogin4 => "تسجيل الدخول";
  static String get hintPrivacyLogin1 => "بالضغط على تسجيل مستخدم جديد، فأنت توافق على ";
  static String get hintPrivacyLogin2 => "سياسة الخصوصية";

  ///Otp Screen Strings.
  static String get otpTitle => "أدخل رمز التحقق";
  static String get otpSubTitle => "لقد قمنا بإرسال رمز التأكيد لرقم الهاتف التالي";
  static String get otpEnterCode => "أدخل الرمز";
  static String get otpDidNotReceive => "لم تستلم رمزاً ؟";
  static String get otpRequestNew => "طلب رمز جديد";
  static String get otpVerify => "تحقق";
  static String get otpTimer => "00:59";

  // Success Verify Screen Strings
  static String get successTitle => "تهانينا!";
  static String get successDescription =>
      "لقد تم التحقق من الرمز بنجاح، يمكنك الآن متابعة العمل مع جميع مزايا تطبيقنا وقتاً سعيداً.";
  static String get successButton => "الذهاب إلى الرئيسية";
  static String get successPrivacyLink => "تصفح سياسات الاستخدام والخصوصية";
  static String get successWarning => "القسم قيد التطوير";

  // OnBoarding Screen Strings
  static String get onBoardingTitle1 => "ابدأ تواصلك المؤسسي الذكي!";
  static String get onBoardingDescription1 =>
      "أنشئ قنوات اتصال فعّالة بين الدكاترة والطلبة، وابقَ على اطلاع دائم بكل الإعلانات والرسائل من مؤسستك الأكاديمية.";

  static String get onBoardingTitle2 => "تواصل حتى دون إنترنت!";
  static String get onBoardingDescription2 =>
      "أرسل الرسائل والملاحظات عبر الإنترنت أو SMS لضمان وصولها لجميع الأعضاء في كل الظروف.";

  static String get onBoardingTitle3 => "إدارة ذكية للمجموعات والمحادثات!";
  static String get onBoardingDescription3 =>
      "تحكّم في المجموعات والمحادثات من مكان واحد، وشارك المرفقات والصور والملاحظات بسهولة تامة.";

  static String get onBoardingNextButton => "التالي";
  static String get onBoardingLoginButton => "تسجيل الدخول";
  static String get onBoardingSkipButton => "تخطي";


  /// Config Strings
  static String get noRouteFound => tr('noRouteFound');

  static String get success => tr('success');

  static String get noContent => tr('noContent');

  static String get badRequest => tr('badRequest');

  static String get forbidden => tr('forbidden');

  static String get unAuthorized => tr('unAuthorized');

  static String get notFound => tr('notFound');

  static String get internalServerError => tr('internalServerError');

  static String get connectTimeOut => tr('connectTimeOut');

  static String get cancel => tr('cancel');

  static String get receiveTimeOut => tr('receiveTimeOut');

  static String get sendTimeOut => tr('sendTimeOut');

  static String get cacheError => tr('cacheError');

  static String get noInternetConnection => tr('noInternetConnection');

  static String get unKnown => tr('unKnown');

  static String get sessionFinished => tr('sessionFinished');

  static String get invalidEmptyEmail => tr('invalidEmptyEmail');

  static String get invalidEmail => tr('invalidEmail');

  static String get doYouWantToChangeIt => tr('doYouWantToChangeIt');

  static String get invalidPasswordLength => tr('invalidEmptyPassword');

  static String get invalidPasswordUpper => tr('invalidPasswordUpper');

  static String get invalidPasswordLower => tr('invalidPasswordLower');

  static String get invalidPasswordDigit => tr('invalidPasswordDigit');

  static String get passwordNotMatch => tr('passwordNotMatch');

  static String get invalidEmptyPhoneNumber => tr('invalidEmptyPhoneNumber');

  static String get invalidEmptyCode => tr('invalidEmptyCode');

  static String get invalidPhoneNumber => tr('invalidPhoneNumber');

  static String get notVerifiedEmail => tr('notVerifiedEmail');

  static String get invalidFullName => tr('invalidFullName');

  static String get sorryFailed => tr('sorryFailed');

  static String get invalidEmptyDateOfBirth => tr('invalidEmptyDateOfBirth');

  static String get invalidEmptyFullName => tr('invalidEmptyFullName');
}
