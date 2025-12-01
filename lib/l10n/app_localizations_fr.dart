// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Application des Cantiques';

  @override
  String get home => 'Accueil';

  @override
  String get hymns => 'Cantiques';

  @override
  String get favorites => 'Favoris';

  @override
  String get search => 'Rechercher';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get theme => 'Thème';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get system => 'Système';

  @override
  String get font => 'Police';

  @override
  String get color => 'Couleur';

  @override
  String get history => 'Historique';

  @override
  String get about => 'À propos';

  @override
  String get contact => 'Contact';

  @override
  String get privacy => 'Politique de confidentialité';

  @override
  String get terms => 'Conditions d\'utilisation';

  @override
  String get rateApp => 'Évaluer l\'application';

  @override
  String get shareApp => 'Partager l\'application';

  @override
  String get feedback => 'Commentaires';

  @override
  String get help => 'Aide';

  @override
  String get logout => 'Déconnexion';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'S\'inscrire';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié?';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get send => 'Envoyer';

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Sauvegarder';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get remove => 'Retirer';

  @override
  String get clear => 'Effacer';

  @override
  String get all => 'Tous';

  @override
  String get none => 'Aucun';

  @override
  String get select => 'Sélectionner';

  @override
  String get selected => 'Sélectionné';

  @override
  String get no => 'Non';

  @override
  String get yes => 'Oui';

  @override
  String get on => 'Activé';

  @override
  String get off => 'Désactivé';

  @override
  String get enabled => 'Activé';

  @override
  String get disabled => 'Désactivé';

  @override
  String get available => 'Disponible';

  @override
  String get unavailable => 'Indisponible';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get errorUpdatingFavorites => 'Erreur lors de la mise à jour des favoris';

  @override
  String get success => 'Succès';

  @override
  String get warning => 'Avertissement';

  @override
  String get info => 'Information';

  @override
  String get confirm => 'Confirmer';

  @override
  String get newHymn => 'Nouveau cantique';

  @override
  String get deleteVerse => 'Supprimer le verset';

  @override
  String get addVerse => 'Ajouter un verset';

  @override
  String get hymnHint => 'Indice du cantique';

  @override
  String get confirmDelete => 'Êtes-vous sûr de vouloir supprimer cet élément?';

  @override
  String get confirmLogout => 'Êtes-vous sûr de vouloir vous déconnecter?';

  @override
  String get noResults => 'Aucun résultat trouvé';

  @override
  String get searchHint => 'Rechercher des cantiques, titres ou numéros...';

  @override
  String hymnNumber(int number) {
    return 'Cantique $number';
  }

  @override
  String get hymnAlreadyDownloaded => 'Cantique déjà téléchargé';

  @override
  String get playlistNotFound => 'Liste de lecture non trouvée';

  @override
  String get share => 'Partager';

  @override
  String get copy => 'Copier';

  @override
  String get view => 'Voir';

  @override
  String get download => 'Télécharger';

  @override
  String get hymnNotDownloaded => 'Cantique non téléchargé';

  @override
  String get addToFavorites => 'Ajouter aux favoris';

  @override
  String get removeFromFavorites => 'Retirer des favoris';

  @override
  String get shareHymn => 'Partager le cantique';

  @override
  String get copyHymn => 'Copier le cantique';

  @override
  String get viewOriginal => 'Voir l\'original';

  @override
  String get viewTranslation => 'Voir la traduction';

  @override
  String get hymnNotFound => 'Cantique non trouvé';

  @override
  String get hymnNotAvailable => 'Cantique non disponible';

  @override
  String get downloadHymns => 'Télécharger des cantiques';

  @override
  String get downloadingHymns => 'Téléchargement des cantiques...';

  @override
  String get downloadComplete => 'Téléchargement terminé';

  @override
  String get downloadFailed => 'Échec du téléchargement';

  @override
  String get downloadCanceled => 'Téléchargement annulé';

  @override
  String get checkForUpdates => 'Vérifier les mises à jour';

  @override
  String get updateAvailable => 'Mise à jour disponible';

  @override
  String get updateNow => 'Mettre à jour maintenant';

  @override
  String get updateLater => 'Mettre à jour plus tard';

  @override
  String get noUpdates => 'Aucune mise à jour disponible';

  @override
  String get lastUpdated => 'Dernière mise à jour';

  @override
  String get version => 'Version';

  @override
  String get newVersionAvailable => 'Une nouvelle version est disponible';

  @override
  String get pleaseUpdate => 'Veuillez mettre à jour pour obtenir les dernières fonctionnalités';

  @override
  String get networkError => 'Erreur réseau';

  @override
  String get connectionError => 'Erreur de connexion';

  @override
  String get serverError => 'Erreur serveur';

  @override
  String get unknownError => 'Une erreur inconnue s\'est produite';

  @override
  String get retry => 'Réessayer';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get close => 'Fermer';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get previous => 'Précédent';

  @override
  String get finish => 'Terminer';

  @override
  String get start => 'Commencer';

  @override
  String get stop => 'Arrêter';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Reprendre';

  @override
  String get play => 'Lire';

  @override
  String get alphabeticalOrder => 'Ordre alphabétique';

  @override
  String get numericalOrder => 'Ordre numérique';

  @override
  String get sortBy => 'Trier par';

  @override
  String get filter => 'Filtrer';

  @override
  String get category => 'Catégorie';

  @override
  String get categories => 'Catégories';

  @override
  String get allCategories => 'Toutes catégories';

  @override
  String get book => 'Livre';

  @override
  String get books => 'Livres';

  @override
  String get selectCategory => 'Sélectionner catégorie';

  @override
  String get selectBook => 'Sélectionner livre';

  @override
  String get favoritesOnly => 'Favoris seulement';

  @override
  String get showFavorites => 'Afficher favoris';

  @override
  String get hideFavorites => 'Masquer favoris';

  @override
  String get recentHymns => 'Cantiques récents';

  @override
  String get mostViewed => 'Les plus vus';

  @override
  String get randomHymn => 'Cantique aléatoire';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get relatedHymns => 'Cantiques connexes';

  @override
  String get similarHymns => 'Cantiques similaires';

  @override
  String get hymnOfTheDay => 'Cantique du jour';

  @override
  String get dailyHymn => 'Cantique quotidien';

  @override
  String get readMore => 'Lire davantage';

  @override
  String get readLess => 'Lire moins';

  @override
  String get expand => 'Développer';

  @override
  String get collapse => 'Réduire';

  @override
  String get showMore => 'Afficher plus';

  @override
  String get showLess => 'Afficher moins';

  @override
  String get viewAll => 'Tout afficher';

  @override
  String get viewDetails => 'Voir détails';

  @override
  String get details => 'Détails';

  @override
  String get information => 'Information';

  @override
  String get aboutApp => 'À propos de l\'application';

  @override
  String get appDescription => 'Application de cantiques avec support multilingue';

  @override
  String get developedBy => 'Développé par';

  @override
  String get rightsReserved => 'Tous droits réservés';

  @override
  String get copyright => 'Droits d\'auteur';

  @override
  String get license => 'Licence';

  @override
  String get openSource => 'Open source';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get contactUs => 'Nous contacter';

  @override
  String get support => 'Support';

  @override
  String get feedbackMessage => 'Vos commentaires sont importants pour nous';

  @override
  String get sendFeedback => 'Envoyer des commentaires';

  @override
  String get rateThisApp => 'Évaluer cette application';

  @override
  String get shareWithFriends => 'Partager avec des amis';

  @override
  String get tellAFriend => 'Dire à un ami';

  @override
  String get invite => 'Inviter';

  @override
  String get export => 'Exporter';

  @override
  String get import => 'Importer';

  @override
  String get backup => 'Sauvegarde';

  @override
  String get restore => 'Restaurer';

  @override
  String get dataBackup => 'Sauvegarde de données';

  @override
  String get backupData => 'Sauvegarder données';

  @override
  String get restoreData => 'Restaurer données';

  @override
  String get exportData => 'Exporter données';

  @override
  String get importData => 'Importer données';

  @override
  String get dataExported => 'Données exportées avec succès';

  @override
  String get dataImported => 'Données importées avec succès';

  @override
  String get backupCreated => 'Sauvegarde créée avec succès';

  @override
  String get backupRestored => 'Sauvegarde restaurée avec succès';

  @override
  String get cannotCheckUpdates => 'Impossible de vérifier les mises à jour';

  @override
  String get cannotRefresh => 'Impossible d\'actualiser';

  @override
  String get cannotSave => 'Impossible de sauvegarder';

  @override
  String get chooseFont => 'Choisir une police';

  @override
  String get chooseLanguage => 'Choisir la langue';

  @override
  String get searchHymnsHint => 'Rechercher des cantiques';

  @override
  String chaptersCount(Object count) {
    return '$count chapitres';
  }

  @override
  String chooseColorFor(String colorType) {
    return 'Choisir la couleur pour $colorType';
  }

  @override
  String get chooseColor => 'Choisir la couleur';

  @override
  String get accept => 'Accepter';

  @override
  String get presetColors => 'Couleurs prédéfinies';

  @override
  String get customColors => 'Couleurs personnalisées';

  @override
  String get primaryColor => 'Couleur primaire';

  @override
  String get textColor => 'Couleur du texte';

  @override
  String get backgroundColor => 'Couleur de fond';

  @override
  String get drawerColor => 'Couleur du tiroir';

  @override
  String get iconColor => 'Couleur de l\'icône';

  @override
  String get chooseFontStyle => 'Choisir le style de police';

  @override
  String get sampleText => 'Jésus Sauve Nos Âmes';

  @override
  String get yesLowercase => 'oui';

  @override
  String createdByLabel(String name, String email) {
    return 'Créé par : $name$email';
  }

  @override
  String confirmDeleteHymn(String title) {
    return 'Êtes-vous sûr de vouloir supprimer le cantique \"$title\" ?';
  }

  @override
  String get copyHymnContent => 'Copier le contenu du cantique';

  @override
  String get deleteHymn => 'Supprimer le cantique';

  @override
  String get deleteHymnContent => 'Supprimer le cantique sélectionné';

  @override
  String get deleteHymnError => 'Erreur lors de la suppression du cantique';

  @override
  String get emptyHymnsList => 'Aucun cantique disponible';

  @override
  String get emptyTitle => 'Titre vide';

  @override
  String get errorLoadingNotes => 'Erreur lors du chargement des notes';

  @override
  String get errorOccurred => 'Une erreur est survenue';

  @override
  String get exitWithoutSaving => 'Quitter sans sauvegarder?';

  @override
  String get favoriteRemoved => 'Retiré des favoris';

  @override
  String get favoriteAdded => 'Ajouté aux favoris';

  @override
  String get fillAllFields => 'Veuillez remplir tous les champs';

  @override
  String get hymnDeleted => 'Cantique supprimé';

  @override
  String hymnDetails(Object number, Object title) {
    return '$number - $title';
  }

  @override
  String get hymnSaved => 'Cantique sauvegardé';

  @override
  String get loginRequired => 'Veuillez vous connecter d\'abord';

  @override
  String get noHymnsFound => 'Aucun cantique trouvé';

  @override
  String get noInternetConnection => 'Aucune connexion Internet';

  @override
  String get permissionDenied => 'Permission refusée';

  @override
  String refreshFailed(Object error) {
    return 'Échec de l\'actualisation: $error';
  }

  @override
  String get refreshSuccess => 'Actualisation réussie';

  @override
  String get saveChanges => 'Sauvegarder les modifications';

  @override
  String searchError(Object error) {
    return 'Erreur: $error';
  }

  @override
  String get selectHymnFirst => 'Veuillez sélectionner un cantique d\'abord';

  @override
  String get updateAvailableContent => 'Une nouvelle mise à jour est disponible. Souhaitez-vous l\'installer?';

  @override
  String get updateAvailableTitle => 'Mise à jour disponible';

  @override
  String get updateFailed => 'Échec de la mise à jour';

  @override
  String get updateFailedDownload => 'Échec du téléchargement de la mise à jour';

  @override
  String get updateFailedInstall => 'Échec de l\'installation de la mise à jour';

  @override
  String get updating => 'Mise à jour en cours...';

  @override
  String get userHymns => 'Cantiques des utilisateurs';

  @override
  String get yesDelete => 'Oui, supprimer';

  @override
  String get noCancel => 'Non, annuler';

  @override
  String get appTitleShort => 'JFF';

  @override
  String get checkUpdateError => 'Impossible de vérifier les mises à jour';

  @override
  String errorOccurredMessage(Object error) {
    return 'Erreur: $error';
  }

  @override
  String get noHymnsAvailable => 'Aucun cantique disponible';

  @override
  String get chorus => 'Refrain';

  @override
  String get verse => 'Verset';

  @override
  String verseWithNumber(int number) {
    return 'Verset $number';
  }

  @override
  String get bridge => 'Pont';

  @override
  String get enterHymnNumber => 'Entrez le numéro du cantique';

  @override
  String get invalidNumber => 'Numéro invalide';

  @override
  String get enterTitle => 'Entrez le titre';

  @override
  String get verses => 'Versets';

  @override
  String get bridgeOptional => 'Pont (Optionnel)';

  @override
  String get notes => 'Notes';

  @override
  String get submit => 'Soumettre';

  @override
  String get hymnSavedSuccessfully => 'Cantique enregistré avec succès';

  @override
  String errorSavingHymn(String error) {
    return 'Erreur lors de l\'enregistrement du cantique: $error';
  }

  @override
  String get enterVerse => 'Entrez le verset';

  @override
  String noPermissionToCreate(String email) {
    return 'Bonjour $email,\nPour des raisons spécifiques, vous n\'avez pas encore la permission de créer des cantiques.\nVeuillez patienter.\nOu contactez l\'administrateur (manassé) pour obtenir la permission.';
  }

  @override
  String get createHymn => 'Créer un cantique';

  @override
  String get addHymn => 'Ajouter un cantique';

  @override
  String get number => 'Numéro';

  @override
  String get title => 'Titre';

  @override
  String get hymnUpdatedSuccessfully => 'Cantique mis à jour avec succès';

  @override
  String errorUpdating(String error) {
    return 'Erreur: $error';
  }

  @override
  String get editNote => 'Modifier la note';

  @override
  String get myPersonalNote => 'Note';

  @override
  String get noteInstructions => 'Entrez votre note sur le cantique, comme les accords, les rappels de prière ou d\'autres informations.';

  @override
  String get enterYourNote => 'Écrivez votre note ici...';

  @override
  String get noteDeleted => 'Note supprimée';

  @override
  String get noteSaved => 'Note enregistrée';

  @override
  String get deleteNoteConfirm => 'Supprimer la note?';

  @override
  String get deleteNoteMessage => 'Êtes-vous vraiment sûr de vouloir supprimer la note?';

  @override
  String get leave => 'Quitter';

  @override
  String get signIn => 'Se connecter';

  @override
  String get additionalHymns => 'Cantiques supplémentaires';

  @override
  String errorOccurredColon(String error) {
    return 'Erreur survenue: $error';
  }

  @override
  String get noAdditionalHymns => 'Aucun cantique supplémentaire';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get signedInSuccessfully => 'Vous vous êtes connecté avec succès.';

  @override
  String get favoriteHymns => 'Cantiques favoris';

  @override
  String get hymnHistory => 'Historique des cantiques';

  @override
  String get changeColor => 'Changer la couleur';

  @override
  String get fontStyle => 'Style de police';

  @override
  String get announcements => 'Annonces';

  @override
  String get bible => 'Bible';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get aboutUs => 'À propos';

  @override
  String get cannotUpdate => 'Impossible de mettre à jour';

  @override
  String cannotDownload(String error) {
    return 'Impossible de télécharger: $error';
  }

  @override
  String get noPermissionAdmin => 'Vous n\'avez pas la permission d\'accéder au panneau d\'administration';

  @override
  String get allSelectedHymnsDeleted => 'Tous les cantiques sélectionnés ont été supprimés';

  @override
  String get problem => 'Problème';

  @override
  String get enterNamePlease => 'Veuillez entrer un nom';

  @override
  String get nameNotSaved => 'Nom non enregistré';

  @override
  String get searchHymns => 'Rechercher des cantiques...';

  @override
  String get syncInformation => 'Informations de synchronisation';

  @override
  String get notLoggedIn => 'Non connecté';

  @override
  String get notLoggedInMessage => 'Vous n\'êtes pas connecté. Connectez-vous à votre compte pour accéder à toutes les fonctionnalités.';

  @override
  String get clearAllHistory => 'Effacer tout l\'historique';

  @override
  String get removeAllHistory => 'Supprimer tout votre historique';

  @override
  String createdBy(String name) {
    return 'Créé par';
  }

  @override
  String deleteFailed(String error) {
    return 'Échec de la suppression: $error';
  }

  @override
  String get sortByRecent => 'Récent';

  @override
  String get sortByOldest => 'Ancien';

  @override
  String get sortByNumber => 'Numéro';

  @override
  String get everyVerseChorus => 'Refrain:';

  @override
  String get checkingForUpdates => 'Vérification des mises à jour...';

  @override
  String get downloadAndInstall => 'Télécharger & Installer';

  @override
  String get downloading => 'Téléchargement...';

  @override
  String get deleteHymnQuestion => 'Supprimer le cantique?';

  @override
  String get deleteHymnFailed => 'Échec de la suppression.';

  @override
  String get hymnDeletedSuccess => 'Cantique supprimé';

  @override
  String get errorCheckingUpdate => 'Échec de la vérification des mises à jour';

  @override
  String get errorDownloadingUpdate => 'Échec du téléchargement de la mise à jour';

  @override
  String get noAdminPermission => 'Vous n\'avez pas la permission d\'accéder au panneau d\'administration';

  @override
  String get selectedHymnsDeleted => 'Les cantiques sélectionnés ont été supprimés';

  @override
  String get noHymns => 'Aucun cantique';

  @override
  String get adminPanel => 'Panneau d\'administration';

  @override
  String get date => 'Date';

  @override
  String get errorLabel => 'Erreur';

  @override
  String get newest => 'Nouveau';

  @override
  String get oldest => 'Ancien';

  @override
  String get noPermission => 'Vous n\'avez pas la permission';

  @override
  String get userManagement => 'Gestion des utilisateurs';

  @override
  String get noEmail => 'Pas d\'email';

  @override
  String get unknownUser => 'Inconnu';

  @override
  String get noUsers => 'Aucun utilisateur';

  @override
  String get lastLogin => 'Dernière connexion';

  @override
  String get registered => 'Inscrit';

  @override
  String hymnCount(int count) {
    return '$count cantiques';
  }

  @override
  String get sortBySongs => 'Par nombre de cantiques';

  @override
  String get typeYesToConfirm => 'Tapez \"OUI\" pour confirmer';

  @override
  String get downloading2 => 'Téléchargement...';

  @override
  String get errorCheckingUpdates => 'Échec de la vérification des mises à jour';

  @override
  String get errorDownloadingUpdate2 => 'Échec du téléchargement';

  @override
  String get errorInstallingUpdate => 'Échec de l\'installation de la mise à jour';

  @override
  String get installUpdateTitle => 'Installer la mise à jour';

  @override
  String get installUpdateContent => 'Voulez-vous vraiment installer la nouvelle version? Cela téléchargera le fichier et l\'installera automatiquement.';

  @override
  String get install => 'Installer';

  @override
  String get downloading3 => 'Téléchargement...';

  @override
  String get deleteNote => 'Supprimer la note';

  @override
  String get cancel2 => 'Annuler';

  @override
  String get createAnnouncement => 'Créer une annonce';

  @override
  String get message => 'Message';

  @override
  String get expirationDate => 'Date d\'expiration';

  @override
  String get noDate => 'Pas de date';

  @override
  String get create => 'Créer';

  @override
  String get editAnnouncement => 'Modifier l\'annonce';

  @override
  String get update => 'Mettre à jour';

  @override
  String get noExpirationDate => 'Pas de date d\'expiration';

  @override
  String get loadingBooks => 'Chargement des livres...';

  @override
  String loadingChapter(Object book, Object chapter) {
    return 'Chargement du chapitre $chapter de $book...';
  }

  @override
  String get settingsSaved => 'Paramètres enregistrés avec succès';

  @override
  String get errorSavingSettings => 'Erreur lors de l\'enregistrement des paramètres';

  @override
  String get deleteHistorySuccess => 'Historique sélectionné supprimé';

  @override
  String get deleteHistoryError => 'Erreur lors de la suppression de l\'historique';

  @override
  String get clearHistorySuccess => 'Historique effacé';

  @override
  String get clearHistoryError => 'Erreur lors de l\'effacement de l\'historique';

  @override
  String get cannotAddHymns => 'Impossible d\'ajouter des cantiques pour le moment';

  @override
  String get searchBooks => 'Rechercher des livres';

  @override
  String searchCurrentChapter(Object chapter) {
    return 'Rechercher dans le chapitre $chapter';
  }

  @override
  String get searchEntireBible => 'Rechercher dans toute la Bible';

  @override
  String get change => 'Changer';

  @override
  String get bibleReader => 'Lecteur de Bible';

  @override
  String emailLabel(String email) {
    return 'Email: $email';
  }

  @override
  String get addressLabel => 'Adresse:';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get appNameSuffix => 'JFF';

  @override
  String get headquarters => 'Siège:';

  @override
  String get headquartersAddress => 'Antsororokavo Fianarantsoa 301';

  @override
  String get phoneNumber => '+261 34 29 439 71';

  @override
  String get github => 'GitHub';

  @override
  String get noHistory => 'Pas d\'historique';

  @override
  String get clearAllHistoryQuestion => 'Effacer tout l\'historique?';

  @override
  String get historyCannotBeUndone => 'L\'historique ne peut pas être annulé une fois supprimé.';

  @override
  String get deleteSelectedHistoryQuestion => 'Supprimer l\'historique sélectionné?';

  @override
  String selectedItems(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get aboutTheApp => 'À propos de l\'application';

  @override
  String get features => 'Fonctionnalités';

  @override
  String get feature1 => 'Cantiques créés pour l\'église JFF';

  @override
  String get feature2 => 'Facilite l\'adoration de Dieu';

  @override
  String get feature3 => 'Vous pouvez ajouter de nouveaux cantiques';

  @override
  String get feature4 => 'Nécessite un compte Google pour les fonctionnalités supplémentaires';

  @override
  String get termsOfUse => 'Conditions d\'utilisation';

  @override
  String get term1 => 'Je n\'utiliserai pas l\'application de manière inappropriée';

  @override
  String get term2 => 'Je n\'ajouterai pas de cantiques qui ne correspondent pas à l\'adoration JFF';

  @override
  String get agreement => 'J\'accepte les conditions ci-dessous';

  @override
  String get enterYourName => 'Entrez votre nom';

  @override
  String get continueText => 'Continuer';

  @override
  String get splashScreenTitle => 'Cantiques de l\'eglise Jesosy Famonjena Fahamarinantsika';

  @override
  String get splashScreenSubtitle => 'Louez le Seigneur car il est bon';

  @override
  String get termsAndConditions => 'Conditions et modalités';

  @override
  String get acceptTerms => 'Accepter les conditions';

  @override
  String get dailyBibleVerse => 'Verset biblique quotidien';

  @override
  String get dailyInspiration => 'Inspiration quotidienne';

  @override
  String get receiveVerseEveryDay => 'Recevoir un verset biblique chaque jour';

  @override
  String get enableDailyVerse => 'Activer le verset quotidien';

  @override
  String get youWillReceiveDailyNotifications => 'Vous recevrez des notifications quotidiennes';

  @override
  String get turnOnToReceiveDailyVerses => 'Activez pour recevoir des versets quotidiens';

  @override
  String get notificationTime => 'Heure de notification';

  @override
  String get todaysVerse => 'Verset du jour';

  @override
  String get noVerseAvailable => 'Aucun verset disponible';

  @override
  String get sendTestNotification => 'Envoyer une notification de test';

  @override
  String get testNotificationSent => 'Notification de test envoyée!';

  @override
  String get myPlaylists => 'Mes listes de lecture';

  @override
  String get noPlaylistsYet => 'Pas encore de listes de lecture';

  @override
  String get createFirstPlaylist => 'Créez votre première liste de lecture';

  @override
  String get newPlaylist => 'Nouvelle liste de lecture';

  @override
  String get deletePlaylist => 'Supprimer la liste de lecture';

  @override
  String get addToPlaylist => 'playlist';

  @override
  String get createNewPlaylist => 'Créer une nouvelle liste de lecture';

  @override
  String get playlistName => 'Nom de la liste de lecture';

  @override
  String get clearExpired => 'Effacer les expirés';

  @override
  String get clearAllCache => 'Effacer tout le cache';

  @override
  String get clearCacheWarning => 'Cela supprimera toutes les données de disponibilité audio mises en cache. L\'application devra vérifier à nouveau la disponibilité audio.';

  @override
  String get allCacheCleared => 'Tout le cache a été effacé';

  @override
  String get expiredCacheCleared => 'Cache expiré effacé';

  @override
  String get couldNotLaunchGoogleFonts => 'Impossible de lancer Google Fonts';

  @override
  String get getFonts => 'Obtenir des polices';

  @override
  String errorPlayingAudio(String error) {
    return 'Erreur lors de la lecture audio: $error';
  }

  @override
  String get playlistExampleHint => 'ex: Service du dimanche';

  @override
  String confirmDeletePlaylist(String playlistTitle) {
    return 'Êtes-vous sûr de vouloir supprimer \"$playlistTitle\"?';
  }

  @override
  String get searchFavoriteSongsHint => 'Rechercher vos chants favoris...';

  @override
  String get searchWordsOrVersesHint => 'Rechercher des mots ou des versets...';

  @override
  String get wholeBible => 'Bible entière';

  @override
  String get audioPlayer => 'Lecteur audio';

  @override
  String get playAudio => 'Lire l\'audio';

  @override
  String get audioCacheManagement => 'Gestion du cache audio';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get guest => 'Invité';

  @override
  String get library => 'Bibliothèque';

  @override
  String get personal => 'Personnel';

  @override
  String get playlists => 'Listes de lecture';

  @override
  String get audioCache => 'Cache audio';

  @override
  String get added => 'Ajouté';

  @override
  String get noHymnsAddedYet => 'Aucun cantique ajouté pour le moment';

  @override
  String get errorLoadingHymns => 'Erreur lors du chargement des cantiques';

  @override
  String get audioAvailable => 'Audio disponible';

  @override
  String get noAudioAvailable => 'Pas d\'audio disponible';

  @override
  String get searchBible => 'Recherche biblique';

  @override
  String get enterWordToSearch => 'Entrez le mot à rechercher';

  @override
  String get noSearchResults => 'Aucun résultat de recherche';

  @override
  String get changeWordToSearch => 'Changer le mot à rechercher';

  @override
  String hymnsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cantiques',
      one: '1 cantique',
      zero: 'Aucun cantique',
    );
    return '$_temp0';
  }

  @override
  String get noChaptersFound => 'Aucun chapitre trouvé';

  @override
  String get yourProfile => 'Votre profil';

  @override
  String usernameLabel(String username) {
    return 'Nom d\'utilisateur: $username';
  }

  @override
  String userIdLabel(String userId) {
    return 'ID: $userId';
  }

  @override
  String get syncInfoMessage1 => 'Vos cantiques favoris et votre historique sont enregistrés sur votre compte Google.';

  @override
  String get syncInfoMessage2 => 'Cela ne sera pas perdu si vous changez de compte.';

  @override
  String errorOccurredWithDetails(String error) {
    return 'Une erreur s\'est produite: $error';
  }

  @override
  String get clearSearch => 'Effacer la recherche';

  @override
  String get appSection => 'Application';

  @override
  String get account => 'Compte';

  @override
  String totalCachedHymns(int count) {
    return 'Total des cantiques mis en cache: $count';
  }

  @override
  String withAudio(int count) {
    return 'Avec audio: $count';
  }

  @override
  String withoutAudio(int count) {
    return 'Sans audio: $count';
  }

  @override
  String get currentVersion => 'Version actuelle';

  @override
  String get latestVersion => 'Dernière version';

  @override
  String get whatsNew => 'Quoi de neuf';

  @override
  String get upToDate => 'À jour';

  @override
  String get appIsUpToDate => 'Votre application est à jour';

  @override
  String get recordings => 'Enregistrements';

  @override
  String get refreshRecordings => 'Actualiser les enregistrements';

  @override
  String get syncFromGoogleDrive => 'Synchroniser depuis Google Drive';

  @override
  String signedInAs(String email) {
    return 'Connecté en tant que $email';
  }

  @override
  String get signInToGoogleDrive => 'Se connecter à Google Drive';

  @override
  String get noRecordingsYet => 'Aucun enregistrement pour le moment';

  @override
  String get startRecordingYourFavoriteHymns => 'Commencez à enregistrer vos cantiques préférés';

  @override
  String get personalRecordings => 'Enregistrements personnels';

  @override
  String get publicRecordings => 'Enregistrements publics';

  @override
  String recordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count enregistrement$_temp0';
  }

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get signedInAsLabel => 'Connecté en tant que:';

  @override
  String get sync => 'Synchroniser';

  @override
  String hymnDuration(String hymnId, String duration) {
    return 'Cantique $hymnId • $duration';
  }

  @override
  String get public => 'Public';

  @override
  String get uploadToDrive => 'Télécharger vers Drive';

  @override
  String uploadFailedTapToRetry(String error) {
    return 'Échec du téléchargement. Appuyez pour réessayer.\nErreur: $error';
  }

  @override
  String get deleteRecording => 'Supprimer l\'enregistrement';

  @override
  String deleteRecordingConfirmation(String title) {
    return 'Êtes-vous sûr de vouloir supprimer \"$title\"? Cette action est irréversible.';
  }

  @override
  String get deleted => 'Supprimé';

  @override
  String get recordingDeletedSuccessfully => 'Enregistrement supprimé avec succès';

  @override
  String get downloadStarted => 'Téléchargement démarré';

  @override
  String get recordingInProgressDialog => 'Enregistrement en cours';

  @override
  String get pleaseStopRecordingBeforePlaying => 'Veuillez arrêter l\'enregistrement avant de lire.';

  @override
  String get stopAndPlay => 'Arrêter & Lire';

  @override
  String get recordingSessionActive => 'Session d\'enregistrement active';

  @override
  String get pleaseCloseRecordingOverlayFirst => 'Veuillez d\'abord fermer l\'overlay d\'enregistrement.';

  @override
  String get recordingInProgress => 'Enregistrement en cours...';

  @override
  String get recordingCompleted => 'Enregistrement terminé';

  @override
  String get recordingSaved => 'Enregistrement enregistré avec succès';

  @override
  String failedToSaveRecording(String error) {
    return 'Échec de l\'enregistrement: $error';
  }

  @override
  String get failedToPlayRecording => 'Échec de la lecture de l\'enregistrement';

  @override
  String get recordingUploadSuccess => 'Enregistrement téléchargé vers Drive avec succès';

  @override
  String get recordingUploadFailed => 'Échec du téléchargement';

  @override
  String failedToUploadRecording(String error) {
    return 'Échec du téléchargement de l\'enregistrement: $error';
  }

  @override
  String get syncFailed => 'Échec de la synchronisation';

  @override
  String failedToSyncFromDrive(String error) {
    return 'Échec de la synchronisation des enregistrements depuis Drive: $error';
  }

  @override
  String get driveSyncCompleted => 'Synchronisation Drive terminée';

  @override
  String driveSignInFailed(Object error) {
    return 'Échec de la connexion à Drive: $error';
  }

  @override
  String get driveFileNotFound => 'Fichier d\'enregistrement introuvable';

  @override
  String get uploadInProgress => 'Téléchargement en cours...';

  @override
  String get storageUsage => 'Utilisation du stockage';

  @override
  String totalStorageUsed(String size) {
    return 'Stockage total utilisé: $size';
  }

  @override
  String recordingOverlayTitle(String hymnId) {
    return 'Enregistrement du cantique $hymnId';
  }

  @override
  String get minimize => 'Minimiser';

  @override
  String get recordingPaused => 'Enregistrement mis en pause';

  @override
  String get recordingResumed => 'Enregistrement repris';

  @override
  String get recordingStopped => 'Enregistrement arrêté';

  @override
  String get playbackSpeed => 'Vitesse de lecture';

  @override
  String get normalSpeed => 'Vitesse normale';

  @override
  String get renameRecording => 'Renommer l\'enregistrement';

  @override
  String get enterNewTitle => 'Entrez un nouveau titre';

  @override
  String get rename => 'Renommer';

  @override
  String get recordingRenamed => 'Enregistrement renommé avec succès';

  @override
  String failedToRenameRecording(String error) {
    return 'Échec du renommage de l\'enregistrement: $error';
  }

  @override
  String get recordingManager => 'Gestionnaire d\'enregistrements';

  @override
  String get createNewRecording => 'Créer un nouvel enregistrement';

  @override
  String get viewRecordings => 'Voir les enregistrements';

  @override
  String get recordingPermissionRequired => 'Autorisation d\'enregistrement requise';

  @override
  String get pleaseGrantMicrophonePermission => 'Veuillez accorder l\'autorisation du microphone pour enregistrer des cantiques.';

  @override
  String get grantPermission => 'Accorder l\'autorisation';

  @override
  String get recordingNotAllowed => 'Enregistrement non autorisé';

  @override
  String get microphoneAccessDenied => 'Accès au microphone refusé. Veuillez l\'activer dans les paramètres pour enregistrer des cantiques.';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get recordingError => 'Erreur d\'enregistrement';

  @override
  String anErrorOccurredDuringRecording(String error) {
    return 'Une erreur s\'est produite pendant l\'enregistrement: $error';
  }

  @override
  String get playbackError => 'Erreur de lecture';

  @override
  String anErrorOccurredDuringPlayback(String error) {
    return 'Une erreur s\'est produite pendant la lecture: $error';
  }

  @override
  String get signInWithGoogle => 'Se connecter avec Google';

  @override
  String get continueAsGuest => 'Continuer en tant qu\'invité';

  @override
  String get signingIn => 'Connexion en cours...';

  @override
  String get googleSignInFailed => 'Échec de la connexion Google';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get orDivider => 'OU';

  @override
  String get skipForNow => 'Ignorer pour l\'instant';

  @override
  String get getStarted => 'Commencer';

  @override
  String get appFeature1 => 'Parcourir des milliers de cantiques';

  @override
  String get appFeature2 => 'Enregistrer vos propres versions et des nouveaux cantiques';

  @override
  String get appFeature3 => 'Synchroniser sur tous les appareils';

  @override
  String get contacts => 'Contacts';

  @override
  String get addContact => 'Ajouter un contact';

  @override
  String get editContact => 'Modifier le contact';

  @override
  String get noContactsFound => 'Aucun contact trouvé sur votre appareil.';

  @override
  String get searchContacts => 'Rechercher des contacts...';

  @override
  String get contactName => 'Nom';

  @override
  String get confirmDeleteContact => 'Êtes-vous sûr de vouloir supprimer ce contact ?';

  @override
  String get contactSaved => 'Contact enregistré avec succès';

  @override
  String get contactLocation => 'Localisation';

  @override
  String get contactPhone => 'Téléphone';

  @override
  String get appFeature4 => 'Partager avec les autres et la communauté';

  @override
  String continueAs(String name) {
    return 'Continuer en tant que : $name';
  }

  @override
  String get portfolio => 'Portfolio';

  @override
  String get playFirstHymn => 'Lire le premier cantique';

  @override
  String get nowPlaying => 'En lecture';

  @override
  String get accessDenied => 'Accès refusé';

  @override
  String get accountRestricted => 'Votre compte a été restreint';

  @override
  String get reason => 'Raison';

  @override
  String get alternativeAccess => 'Accès alternatif';

  @override
  String get autoTranslate => 'Traduction automatique';

  @override
  String get translationEnabled => 'Traduction activée';

  @override
  String get translationDisabled => 'Traduction désactivée';

  @override
  String get translating => 'Traduction en cours...';

  @override
  String get translationError => 'Erreur de traduction';

  @override
  String get selectTranslationLanguage => 'Sélectionner la langue de traduction';

  @override
  String get translated => 'Traduit';

  @override
  String get showOriginal => 'Afficher l\'original';

  @override
  String get showTranslation => 'Afficher la traduction';

  @override
  String get translationSettings => 'Paramètres de traduction';

  @override
  String get automaticTranslation => 'Traduction automatique';

  @override
  String get automaticTranslationDescription => 'Traduire automatiquement le contenu des cantiques dans votre langue préférée';

  @override
  String get translationModelsLoading => 'Veuillez patienter pendant le chargement des modèles de traduction...';

  @override
  String get translationNotAvailable => 'Traduction non disponible pour cette paire de langues';

  @override
  String get clearTranslationCache => 'Vider le cache de traduction';

  @override
  String get translationCacheCleared => 'Cache de traduction vidé';

  @override
  String get translationStatistics => 'Statistiques de traduction';

  @override
  String get cacheSize => 'Taille du cache';

  @override
  String get currentlyTranslating => 'Traduction en cours';

  @override
  String get supportedLanguages => 'Langues prises en charge:';

  @override
  String get detectLanguage => 'Détecter la langue';

  @override
  String get detectedLanguage => 'Langue détectée';

  @override
  String get sourceLanguage => 'Langue source';

  @override
  String get targetLanguage => 'Langue cible';

  @override
  String get translateFrom => 'Traduire de';

  @override
  String get translateTo => 'Traduire vers';

  @override
  String get emergencyModeActive => 'MODE D\'URGENCE ACTIF';

  @override
  String get allUpdatesDisabled => 'Toutes les mises à jour sont actuellement désactivées';

  @override
  String get appStatistics => 'Statistiques de l\'application';

  @override
  String get activeUsers => 'Utilisateurs actifs';

  @override
  String get updateStatus => 'Statut de mise à jour';

  @override
  String get updateControl => 'Contrôle de mise à jour';

  @override
  String get manage => 'Gérer';

  @override
  String get updatesEnabled => 'Les mises à jour sont activées';

  @override
  String get updatesDisabled => 'Les mises à jour sont désactivées';

  @override
  String versionBlocked(Object version) {
    return 'La version $version est bloquée';
  }

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get emergencyStop => 'Arrêt d\'urgence';

  @override
  String get emergencyStopConfirm => 'Cela désactivera immédiatement toutes les mises à jour. Continuer?';

  @override
  String get forceUpdateCheck => 'Forcer la vérification des mises à jour';

  @override
  String get clearCache => 'Vider le cache';

  @override
  String get recentActivity => 'Activité récente';

  @override
  String get configurationUpdated => 'Configuration mise à jour';

  @override
  String get updateCheckPerformed => 'Vérification de mise à jour effectuée';

  @override
  String get systemCheckCompleted => 'Vérification système terminée';

  @override
  String get dashboardLoaded => 'Tableau de bord chargé';

  @override
  String get adminDashboardInitialized => 'Tableau de bord administrateur initialisé';

  @override
  String get emergencyModeCleared => 'Mode d\'urgence effacé';

  @override
  String get saving => 'Enregistrement...';

  @override
  String get saveConfiguration => 'Enregistrer la configuration';

  @override
  String get enableUpdates => 'Activer les mises à jour';

  @override
  String get allowUsersToDownloadUpdates => 'Permettre aux utilisateurs de télécharger les mises à jour';

  @override
  String get forceUpdate => 'Forcer la mise à jour';

  @override
  String get forceUsersToUpdate => 'Forcer les utilisateurs à mettre à jour';

  @override
  String get blockedVersion => 'Version bloquée';

  @override
  String get minimumSupportedVersion => 'Version minimale prise en charge';

  @override
  String get recommendedVersion => 'Version recommandée';

  @override
  String get allowedVersions => 'Versions autorisées';

  @override
  String get adminMessage => 'Message d\'administrateur';

  @override
  String get messageToDisplayToAllUsers => 'Message à afficher à tous les utilisateurs';

  @override
  String get versionEG => 'ex: 1.0.15';

  @override
  String get versionsEG => 'ex: 1.0.10, 1.0.11, 1.0.12';

  @override
  String get searchDeletedRecordings => 'Rechercher les enregistrements supprimés...';

  @override
  String get refresh => 'Actualiser';

  @override
  String get restoreRecording => 'Restaurer l\'enregistrement';

  @override
  String get permanentDelete => 'Suppression permanente';

  @override
  String get deletePermanently => 'Supprimer définitivement';

  @override
  String get deleteRecordingQuestion => 'Supprimer l\'enregistrement?';

  @override
  String chooseHowToDelete(Object title) {
    return 'Choisissez comment supprimer \"$title\"';
  }

  @override
  String sureToDelete(Object title) {
    return 'Êtes-vous sûr de vouloir supprimer \"$title\"?';
  }

  @override
  String get moveToTrash => 'Déplacer vers la corbeille';

  @override
  String get makePublic => 'Rendre public';

  @override
  String get enterRecordingTitle => 'Entrer le titre de l\'enregistrement';

  @override
  String get enterNewName => 'Entrer un nouveau nom';

  @override
  String get contactsPermissionRequired => 'L\'autorisation des contacts est requise pour importer les contacts.';

  @override
  String errorAccessingContacts(Object error) {
    return 'Erreur lors de l\'accès aux contacts: $error';
  }

  @override
  String get couldNotOpenMaps => 'Impossible d\'ouvrir les cartes. Veuillez installer une application de cartes.';

  @override
  String get redirectingToGoogleMaps => 'Redirection vers le téléchargement de Google Maps...';

  @override
  String errorPlayingNextHymn(Object error) {
    return 'Erreur lors de la lecture du cantique suivant: $error';
  }

  @override
  String errorPlayingPreviousHymn(Object error) {
    return 'Erreur lors de la lecture du cantique précédent: $error';
  }

  @override
  String get importContact => 'Importer le contact';

  @override
  String get record => 'Enregistrer';

  @override
  String get playerStats => 'Statistiques du lecteur';

  @override
  String get startRecording => 'Commencer l\'enregistrement';

  @override
  String get recordingStats => 'Statistiques d\'enregistrement';

  @override
  String get addAnnouncement => 'Ajouter une annonce';

  @override
  String errorLoadingUsers(Object error) {
    return 'Erreur lors du chargement des utilisateurs: $error';
  }

  @override
  String errorUpdatingUser(Object error) {
    return 'Erreur lors de la mise à jour de l\'utilisateur: $error';
  }

  @override
  String get pleaseTypeYesToConfirm => 'Veuillez taper \"OUI\" pour confirmer';

  @override
  String get deletingAllUserData => 'Suppression de toutes les données utilisateur...';

  @override
  String errorDeletingUserData(Object error) {
    return 'Erreur lors de la suppression des données utilisateur: $error';
  }

  @override
  String get searchUsers => 'Rechercher des utilisateurs...';

  @override
  String get duplicateTitle => 'Titre en double';

  @override
  String get searchRecordings => 'Rechercher des enregistrements...';

  @override
  String get searchForAPlace => 'Rechercher un lieu...';

  @override
  String get searchLanguage => 'Rechercher une langue...';

  @override
  String get testTranslation => 'Test de traduction';

  @override
  String get enterTextToTranslate => 'Entrer le texte à traduire';

  @override
  String get translate => 'Traduire';

  @override
  String get exampleTranslatedTexts => 'Exemples de textes traduits';

  @override
  String get cacheManagement => 'Gestion du cache';

  @override
  String get currentLocale => 'Locale actuelle';

  @override
  String get discard => 'Annuler';

  @override
  String get saveRecording => 'Enregistrer l\'enregistrement';

  @override
  String get skip => 'Ignorer';

  @override
  String get done => 'Terminé';

  @override
  String get recordingNotSaved => 'L\'enregistrement n\'a pas été sauvegardé';
}
