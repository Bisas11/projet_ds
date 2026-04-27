// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'PhotoCoach AI';

  @override
  String get home => 'Accueil';

  @override
  String get welcome => 'Bienvenue sur PhotoCoach AI';

  @override
  String get chooseFeature => 'Choisissez une fonctionnalité';

  @override
  String get imageLabeling => 'Étiquetage d\'images';

  @override
  String get imageLabelingDesc =>
      'Reconnaît les scènes et objets pour un contexte IA plus précis';

  @override
  String get selfieSegmentation => 'Segmentation de selfie';

  @override
  String get selfieSegmentationDesc =>
      'Mesure votre cadrage pour une composition parfaite';

  @override
  String get faceDetection => 'Détection de visages';

  @override
  String get faceDetectionDesc =>
      'Analyse votre sourire et regard pour des conseils personnalisés';

  @override
  String get facesDetected => 'visages détectés';

  @override
  String get smilingProbability => 'Probabilité de sourire';

  @override
  String get leftEyeOpen => 'Probabilité œil gauche ouvert';

  @override
  String get rightEyeOpen => 'Probabilité œil droit ouvert';

  @override
  String get headAngleY => 'Angle de la tête Y';

  @override
  String get headAngleZ => 'Angle de la tête Z';

  @override
  String get noFacesDetected => 'Aucun visage détecté';

  @override
  String get about => 'À propos';

  @override
  String get history => 'Historique';

  @override
  String get settings => 'Paramètres';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'Inscription';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get noAccount => 'Pas encore de compte ?';

  @override
  String get haveAccount => 'Déjà un compte ?';

  @override
  String get pickImage => 'Choisir une image';

  @override
  String get camera => 'Caméra';

  @override
  String get gallery => 'Galerie';

  @override
  String get processing => 'Traitement en cours...';

  @override
  String get results => 'Résultats';

  @override
  String get saveResult => 'Enregistrer le résultat';

  @override
  String get noResults => 'Aucun résultat trouvé';

  @override
  String get labelsDetected => 'Étiquettes détectées';

  @override
  String get confidence => 'Confiance';

  @override
  String get noHistory => 'Aucun historique sauvegardé';

  @override
  String get deleteAll => 'Tout supprimer';

  @override
  String get theme => 'Thème';

  @override
  String get language => 'Langue';

  @override
  String get sound => 'Son';

  @override
  String get vibration => 'Vibration';

  @override
  String get notifications => 'Notifications';

  @override
  String get logout => 'Déconnexion';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'OK';

  @override
  String get delete => 'Supprimer';

  @override
  String get appInfo =>
      'PhotoCoach AI vous aide à prendre de meilleures photos en évaluant la composition, en détectant les expressions et en proposant des conseils IA instantanés — tout sur votre appareil.';

  @override
  String get apiInfo =>
      'Propulsé par Google ML Kit — IA sur l\'appareil pour une confidentialité totale. Aucun téléchargement, aucun cloud, résultats instantanés.';

  @override
  String get personDetected => 'Personne détectée';

  @override
  String get testSound => 'Tester le son';

  @override
  String get testVibration => 'Tester la vibration';

  @override
  String get testNotification => 'Tester la notification';

  @override
  String get savedSuccessfully => 'Enregistré avec succès';

  @override
  String get resultSaved => 'Résultat sauvegardé dans l\'historique';

  @override
  String get confirmDelete => 'Êtes-vous sûr de vouloir supprimer ceci ?';

  @override
  String get confirmDeleteAll =>
      'Êtes-vous sûr de vouloir supprimer tout l\'historique ?';

  @override
  String get invalidEmail => 'Veuillez saisir un e-mail valide';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get loginFailed => 'Échec de la connexion';

  @override
  String get registerFailed => 'Échec de l\'inscription';

  @override
  String get french => 'Français';

  @override
  String get english => 'Anglais';

  @override
  String get arabic => 'Arabe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get resetPasswordDesc =>
      'Entrez votre adresse e-mail et nous vous enverrons un lien pour réinitialiser votre mot de passe.';

  @override
  String get resetEmailSent =>
      'E-mail de réinitialisation envoyé. Veuillez vérifier votre boîte de réception.';

  @override
  String get sendResetEmail => 'Envoyer l\'e-mail de réinitialisation';

  @override
  String get profile => 'Profil';

  @override
  String get landingTagline => 'Prenez de meilleures photos avec l\'IA';

  @override
  String get landingDescription =>
      'PhotoCoach AI évalue votre composition, lit vos expressions et vous donne des conseils instantanés pour votre meilleure prise de vue — sur votre appareil.';

  @override
  String get landingServicesTitle => 'Comment PhotoCoach AI vous aide';

  @override
  String get landingGetStarted => 'Commencer à mieux photographier';

  @override
  String get mlServicesTitle => 'Services ML Kit';

  @override
  String get analyzePhoto => 'Analyser ma photo';

  @override
  String get photoReport => 'Rapport photo';

  @override
  String get aiTips => 'Conseils IA';

  @override
  String get advancedTools => 'Outils avancés';

  @override
  String get photoScore => 'Score photo';

  @override
  String get analyzing => 'Analyse en cours...';

  @override
  String get tapPhotoToStart =>
      'Choisissez une photo pour obtenir des conseils IA sur la qualité et la composition.';

  @override
  String get sceneContext => 'Contexte de la scène';

  @override
  String get feedback => 'Retour';

  @override
  String get account => 'Compte';

  @override
  String get accountInfo => 'Infos du compte';

  @override
  String get whyOnDeviceAi => 'Pourquoi l\'IA sur l\'appareil ?';

  @override
  String get aiFeatures => 'Fonctionnalités IA et leur rôle';

  @override
  String get mlKitModelsDesc =>
      'Trois modèles Google ML Kit travaillent ensemble pour coacher vos photos :';

  @override
  String get displayName => 'Nom affiché';

  @override
  String get changePhoto => 'Changer la photo';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get saving => 'Enregistrement…';

  @override
  String get nameRequired => 'Le nom ne peut pas être vide';

  @override
  String get segmentationResult => 'Résultat de segmentation';

  @override
  String get subjectTooSmall => 'Sujet trop petit — rapprochez-vous.';

  @override
  String get subjectTooClose => 'Sujet trop proche — reculez.';

  @override
  String get goodFraming => 'Bon cadrage — le sujet remplit bien le cadre.';

  @override
  String get subjectCoverage => 'Couverture du sujet';

  @override
  String get topSceneLabels => 'Principales étiquettes de scène';

  @override
  String get analysisSummary => 'Résumé de l\'analyse';

  @override
  String get scoreExcellent => 'Excellent';

  @override
  String get scoreGood => 'Bien';

  @override
  String get scoreFair => 'Passable';

  @override
  String get scoreNeedsWork => 'À améliorer';

  @override
  String get person => 'personne';
}
