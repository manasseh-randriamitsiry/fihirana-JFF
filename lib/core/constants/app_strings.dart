/// Application-wide string constants to eliminate hardcoded strings
class AppStrings {
  // Common Actions
  static const String ok = 'OK';
  static const String cancel = 'Annuler';
  static const String save = 'Enregistrer';
  static const String delete = 'Supprimer';
  static const String edit = 'Modifier';
  static const String add = 'Ajouter';
  static const String remove = 'Retirer';
  static const String close = 'Fermer';
  static const String back = 'Retour';
  static const String next = 'Suivant';
  static const String previous = 'Précédent';
  static const String retry = 'Réessayer';
  static const String refresh = 'Actualiser';
  static const String loading = 'Chargement...';
  static const String error = 'Erreur';
  static const String success = 'Succès';
  static const String warning = 'Avertissement';
  static const String info = 'Info';

  // Navigation
  static const String home = 'Accueil';
  static const String settings = 'Paramètres';
  static const String profile = 'Profil';
  static const String favorites = 'Favoris';
  static const String history = 'Historique';
  static const String search = 'Rechercher';

  // Status Messages
  static const String noData = 'Aucune donnée disponible';
  static const String noResults = 'Aucun résultat trouvé';
  static const String connectionError = 'Erreur de connexion';
  static const String serverError = 'Erreur du serveur';
  static const String timeoutError = "Délai d'attente dépassé";
  static const String unknownError = "Une erreur inconnue s'est produite";

  // Validation Messages
  static const String requiredField = 'Ce champ est obligatoire';
  static const String invalidEmail = 'Adresse e-mail invalide';
  static const String invalidPhone = 'Numéro de téléphone invalide';
  static const String passwordTooShort = 'Mot de passe trop court';
  static const String passwordsDontMatch =
      'Les mots de passe ne correspondent pas';

  // Permissions
  static const String cameraPermission = 'Autorisation de la caméra requise';
  static const String microphonePermission =
      'Autorisation du microphone requise';
  static const String storagePermission = 'Autorisation de stockage requise';
  static const String locationPermission =
      'Autorisation de localisation requise';

  // File Operations
  static const String fileNotFound = 'Fichier introuvable';
  static const String fileTooLarge = 'Fichier trop volumineux';
  static const String invalidFileFormat = 'Format de fichier invalide';
  static const String uploadFailed = "Échec de l'envoi";
  static const String downloadFailed = 'Échec du téléchargement';

  // Audio
  static const String play = 'Lire';
  static const String pause = 'Pause';
  static const String stop = 'Arrêter';
  static const String nextTrack = 'Suivant';
  static const String previousTrack = 'Précédent';
  static const String shuffle = 'Lecture aléatoire';
  static const String repeat = 'Répéter';
  static const String volume = 'Volume';

  // Time
  static const String today = "Aujourd'hui";
  static const String yesterday = 'Hier';
  static const String tomorrow = 'Demain';
  static const String now = 'Maintenant';
  static const String ago = 'il y a';
  static const String justNow = "À l'instant";

  // Units
  static const String seconds = 'secondes';
  static const String minutes = 'minutes';
  static const String hours = 'heures';
  static const String days = 'jours';
  static const String weeks = 'semaines';
  static const String months = 'mois';
  static const String years = 'ans';

  // Sizes
  static const String bytes = 'B';
  static const String kilobytes = 'KB';
  static const String megabytes = 'MB';
  static const String gigabytes = 'GB';

  // Network
  static const String online = 'En ligne';
  static const String offline = 'Hors ligne';
  static const String connecting = 'Connexion...';
  static const String connected = 'Connecté';
  static const String disconnected = 'Déconnecté';

  // Confirmation Messages
  static const String confirmDelete =
      'Voulez-vous vraiment supprimer cet élément ?';
  static const String confirmExit = 'Voulez-vous vraiment quitter ?';
  static const String unsavedChanges =
      'Des modifications ne sont pas enregistrées. Voulez-vous les enregistrer ?';

  // Empty States
  static const String noFavorites = 'Aucun favori pour le moment';
  static const String noHistory = 'Aucun historique disponible';
  static const String noSearchResults = 'Aucun résultat de recherche';
  static const String emptyList = 'La liste est vide';

  // Helper methods
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes $bytes';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} $kilobytes';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} $megabytes';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} $gigabytes';
  }
}
