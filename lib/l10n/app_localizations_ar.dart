// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'VisionAI';

  @override
  String get home => 'الرئيسية';

  @override
  String get welcome => 'مرحبًا بكم في VisionAI';

  @override
  String get chooseFeature => 'اختر ميزة';

  @override
  String get imageLabeling => 'تصنيف الصور';

  @override
  String get imageLabelingDesc => 'تحديد الأشياء والحيوانات والأماكن في الصور';

  @override
  String get selfieSegmentation => 'تقسيم السيلفي';

  @override
  String get selfieSegmentationDesc => 'عزل الشخص عن الخلفية في صور السيلفي';

  @override
  String get faceDetection => 'كشف الوجوه';

  @override
  String get faceDetectionDesc => 'كشف الوجوه مع المعالم والتعبيرات';

  @override
  String get facesDetected => 'وجوه مكتشفة';

  @override
  String get smilingProbability => 'احتمال الابتسام';

  @override
  String get leftEyeOpen => 'احتمال فتح العين اليسرى';

  @override
  String get rightEyeOpen => 'احتمال فتح العين اليمنى';

  @override
  String get headAngleY => 'زاوية الرأس ص';

  @override
  String get headAngleZ => 'زاوية الرأس ع';

  @override
  String get noFacesDetected => 'لم يتم اكتشاف وجوه';

  @override
  String get about => 'حول';

  @override
  String get history => 'السجل';

  @override
  String get settings => 'الإعدادات';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟';

  @override
  String get pickImage => 'اختيار صورة';

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';

  @override
  String get processing => 'جاري المعالجة...';

  @override
  String get results => 'النتائج';

  @override
  String get saveResult => 'حفظ النتيجة';

  @override
  String get noResults => 'لم يتم العثور على نتائج';

  @override
  String get labelsDetected => 'التصنيفات المكتشفة';

  @override
  String get confidence => 'الثقة';

  @override
  String get noHistory => 'لا يوجد سجل محفوظ بعد';

  @override
  String get deleteAll => 'حذف الكل';

  @override
  String get theme => 'المظهر';

  @override
  String get language => 'اللغة';

  @override
  String get sound => 'الصوت';

  @override
  String get vibration => 'الاهتزاز';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get error => 'خطأ';

  @override
  String get success => 'نجاح';

  @override
  String get cancel => 'إلغاء';

  @override
  String get ok => 'موافق';

  @override
  String get delete => 'حذف';

  @override
  String get appInfo =>
      'VisionAI هو تطبيق Flutter يستخدم Google ML Kit لميزات الذكاء البصري بما في ذلك تصنيف الصور وتقسيم السيلفي وكشف الوجوه.';

  @override
  String get apiInfo =>
      'مدعوم بواسطة Google ML Kit — التعلم الآلي على الجهاز لتطبيقات الهاتف المحمول. يعالج ML Kit الصور محليًا على الجهاز دون الحاجة إلى اتصال بالإنترنت.';

  @override
  String get personDetected => 'تم اكتشاف شخص';

  @override
  String get savedSuccessfully => 'تم الحفظ بنجاح';

  @override
  String get resultSaved => 'تم حفظ النتيجة في السجل';

  @override
  String get confirmDelete => 'هل أنت متأكد من حذف هذا؟';

  @override
  String get confirmDeleteAll => 'هل أنت متأكد من حذف كل السجل؟';

  @override
  String get invalidEmail => 'الرجاء إدخال بريد إلكتروني صحيح';

  @override
  String get passwordTooShort => 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String get registerFailed => 'فشل إنشاء الحساب';

  @override
  String get french => 'الفرنسية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPasswordDesc =>
      'أدخل عنوان بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.';

  @override
  String get resetEmailSent =>
      'تم إرسال بريد إعادة تعيين كلمة المرور. يرجى التحقق من صندوق الوارد.';

  @override
  String get sendResetEmail => 'إرسال بريد إعادة التعيين';

  @override
  String get profile => 'الملف الشخصي';
}
