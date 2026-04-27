import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PhotoCoach AI'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to PhotoCoach AI'**
  String get welcome;

  /// No description provided for @chooseFeature.
  ///
  /// In en, this message translates to:
  /// **'Choose a feature'**
  String get chooseFeature;

  /// No description provided for @imageLabeling.
  ///
  /// In en, this message translates to:
  /// **'Image Labeling'**
  String get imageLabeling;

  /// No description provided for @imageLabelingDesc.
  ///
  /// In en, this message translates to:
  /// **'Recognizes scenes & objects for smarter AI photo context'**
  String get imageLabelingDesc;

  /// No description provided for @selfieSegmentation.
  ///
  /// In en, this message translates to:
  /// **'Selfie Segmentation'**
  String get selfieSegmentation;

  /// No description provided for @selfieSegmentationDesc.
  ///
  /// In en, this message translates to:
  /// **'Measures how well you fill the frame for perfect composition'**
  String get selfieSegmentationDesc;

  /// No description provided for @faceDetection.
  ///
  /// In en, this message translates to:
  /// **'Face Detection'**
  String get faceDetection;

  /// No description provided for @faceDetectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Reads your smile & eye contact for expression-based tips'**
  String get faceDetectionDesc;

  /// No description provided for @facesDetected.
  ///
  /// In en, this message translates to:
  /// **'faces detected'**
  String get facesDetected;

  /// No description provided for @smilingProbability.
  ///
  /// In en, this message translates to:
  /// **'Smiling probability'**
  String get smilingProbability;

  /// No description provided for @leftEyeOpen.
  ///
  /// In en, this message translates to:
  /// **'Left eye open probability'**
  String get leftEyeOpen;

  /// No description provided for @rightEyeOpen.
  ///
  /// In en, this message translates to:
  /// **'Right eye open probability'**
  String get rightEyeOpen;

  /// No description provided for @headAngleY.
  ///
  /// In en, this message translates to:
  /// **'Head angle Y'**
  String get headAngleY;

  /// No description provided for @headAngleZ.
  ///
  /// In en, this message translates to:
  /// **'Head angle Z'**
  String get headAngleZ;

  /// No description provided for @noFacesDetected.
  ///
  /// In en, this message translates to:
  /// **'No faces detected'**
  String get noFacesDetected;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @pickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick Image'**
  String get pickImage;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @saveResult.
  ///
  /// In en, this message translates to:
  /// **'Save Result'**
  String get saveResult;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @labelsDetected.
  ///
  /// In en, this message translates to:
  /// **'Labels detected'**
  String get labelsDetected;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history saved yet'**
  String get noHistory;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'PhotoCoach AI helps you take better photos by scoring composition, detecting expressions, and delivering instant AI-powered tips — all on your device.'**
  String get appInfo;

  /// No description provided for @apiInfo.
  ///
  /// In en, this message translates to:
  /// **'Powered by Google ML Kit — on-device AI that keeps your photos 100% private. No uploads, no cloud, instant results.'**
  String get apiInfo;

  /// No description provided for @personDetected.
  ///
  /// In en, this message translates to:
  /// **'Person detected'**
  String get personDetected;

  /// No description provided for @testSound.
  ///
  /// In en, this message translates to:
  /// **'Test Sound'**
  String get testSound;

  /// No description provided for @testVibration.
  ///
  /// In en, this message translates to:
  /// **'Test Vibration'**
  String get testVibration;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfully;

  /// No description provided for @resultSaved.
  ///
  /// In en, this message translates to:
  /// **'Result saved to history'**
  String get resultSaved;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this?'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all history?'**
  String get confirmDeleteAll;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registerFailed;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we will send you a link to reset your password.'**
  String get resetPasswordDesc;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Please check your inbox.'**
  String get resetEmailSent;

  /// No description provided for @sendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Email'**
  String get sendResetEmail;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @landingTagline.
  ///
  /// In en, this message translates to:
  /// **'Take Better Photos with AI'**
  String get landingTagline;

  /// No description provided for @landingDescription.
  ///
  /// In en, this message translates to:
  /// **'PhotoCoach AI scores your composition, reads expressions, and gives you instant tips for your best shot — all on your device.'**
  String get landingDescription;

  /// No description provided for @landingServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'How PhotoCoach AI helps you'**
  String get landingServicesTitle;

  /// No description provided for @landingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Start Taking Better Photos'**
  String get landingGetStarted;

  /// No description provided for @mlServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'ML Kit Services'**
  String get mlServicesTitle;

  /// No description provided for @analyzePhoto.
  ///
  /// In en, this message translates to:
  /// **'Analyze My Photo'**
  String get analyzePhoto;

  /// No description provided for @photoReport.
  ///
  /// In en, this message translates to:
  /// **'Photo Report'**
  String get photoReport;

  /// No description provided for @aiTips.
  ///
  /// In en, this message translates to:
  /// **'AI Tips'**
  String get aiTips;

  /// No description provided for @advancedTools.
  ///
  /// In en, this message translates to:
  /// **'Advanced Tools'**
  String get advancedTools;

  /// No description provided for @photoScore.
  ///
  /// In en, this message translates to:
  /// **'Photo Score'**
  String get photoScore;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @tapPhotoToStart.
  ///
  /// In en, this message translates to:
  /// **'Pick a photo to get AI feedback on quality, composition and more.'**
  String get tapPhotoToStart;

  /// No description provided for @sceneContext.
  ///
  /// In en, this message translates to:
  /// **'Scene Context'**
  String get sceneContext;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Info'**
  String get accountInfo;

  /// No description provided for @whyOnDeviceAi.
  ///
  /// In en, this message translates to:
  /// **'Why On-Device AI?'**
  String get whyOnDeviceAi;

  /// No description provided for @aiFeatures.
  ///
  /// In en, this message translates to:
  /// **'AI Features & What They Do'**
  String get aiFeatures;

  /// No description provided for @mlKitModelsDesc.
  ///
  /// In en, this message translates to:
  /// **'Three Google ML Kit models work together to coach your photos:'**
  String get mlKitModelsDesc;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameRequired;

  /// No description provided for @segmentationResult.
  ///
  /// In en, this message translates to:
  /// **'Segmentation Result'**
  String get segmentationResult;

  /// No description provided for @subjectTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Subject too small — try moving closer.'**
  String get subjectTooSmall;

  /// No description provided for @subjectTooClose.
  ///
  /// In en, this message translates to:
  /// **'Subject too close — try stepping back.'**
  String get subjectTooClose;

  /// No description provided for @goodFraming.
  ///
  /// In en, this message translates to:
  /// **'Good framing — subject fills the frame well.'**
  String get goodFraming;

  /// No description provided for @subjectCoverage.
  ///
  /// In en, this message translates to:
  /// **'Subject Coverage'**
  String get subjectCoverage;

  /// No description provided for @topSceneLabels.
  ///
  /// In en, this message translates to:
  /// **'Top Scene Labels'**
  String get topSceneLabels;

  /// No description provided for @analysisSummary.
  ///
  /// In en, this message translates to:
  /// **'Analysis Summary'**
  String get analysisSummary;

  /// No description provided for @scoreExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get scoreExcellent;

  /// No description provided for @scoreGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get scoreGood;

  /// No description provided for @scoreFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get scoreFair;

  /// No description provided for @scoreNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'Needs Work'**
  String get scoreNeedsWork;

  /// No description provided for @person.
  ///
  /// In en, this message translates to:
  /// **'person'**
  String get person;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
