// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'VisionAI';

  @override
  String get home => 'Accueil';

  @override
  String get welcome => 'Bienvenue sur VisionAI';

  @override
  String get chooseFeature => 'Choisissez une fonctionnalité';

  @override
  String get imageLabeling => 'Étiquetage d\'images';

  @override
  String get imageLabelingDesc =>
      'Identifier les objets, animaux, lieux dans les images';

  @override
  String get selfieSegmentation => 'Segmentation de selfie';

  @override
  String get selfieSegmentationDesc =>
      'Isoler la personne de l\'arrière-plan dans les selfies';

  @override
  String get faceDetection => 'Détection de visages';

  @override
  String get faceDetectionDesc =>
      'Détecter les visages avec repères et expressions';

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
      'VisionAI est une application Flutter qui utilise Google ML Kit pour des fonctionnalités d\'intelligence visuelle, incluant l\'étiquetage d\'images, la segmentation de selfies et la détection de visages.';

  @override
  String get apiInfo =>
      'Propulsé par Google ML Kit — apprentissage automatique sur l\'appareil pour les applications mobiles. ML Kit traite les images localement sans nécessiter de connexion Internet.';

  @override
  String get personDetected => 'Personne détectée';

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
}
