import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('fr')
  ];

  /// Application title
  ///
  /// In fr, this message translates to:
  /// **'Circulation+'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// No description provided for @username.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant'**
  String get username;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @otp.
  ///
  /// In fr, this message translates to:
  /// **'Code OTP'**
  String get otp;

  /// No description provided for @enterOtp.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code OTP'**
  String get enterOtp;

  /// No description provided for @sendOtp.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le code'**
  String get sendOtp;

  /// No description provided for @officerId.
  ///
  /// In fr, this message translates to:
  /// **'Matricule de l\'agent'**
  String get officerId;

  /// No description provided for @loginAsOfficer.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Agent'**
  String get loginAsOfficer;

  /// No description provided for @loginAsCitizen.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Citoyen'**
  String get loginAsCitizen;

  /// No description provided for @loginAsAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Administrateur'**
  String get loginAsAdmin;

  /// No description provided for @welcomeBack.
  ///
  /// In fr, this message translates to:
  /// **'Bon retour'**
  String get welcomeBack;

  /// No description provided for @selectRole.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez votre profil'**
  String get selectRole;

  /// No description provided for @policeOfficer.
  ///
  /// In fr, this message translates to:
  /// **'Agent de Police'**
  String get policeOfficer;

  /// No description provided for @citizen.
  ///
  /// In fr, this message translates to:
  /// **'Citoyen'**
  String get citizen;

  /// No description provided for @administrator.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get administrator;

  /// No description provided for @dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboard;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @newInterpellation.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle Interpellation'**
  String get newInterpellation;

  /// No description provided for @scanLicense.
  ///
  /// In fr, this message translates to:
  /// **'Scanner le permis'**
  String get scanLicense;

  /// No description provided for @scanRegistration.
  ///
  /// In fr, this message translates to:
  /// **'Scanner la carte grise'**
  String get scanRegistration;

  /// No description provided for @ocrPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu OCR'**
  String get ocrPreview;

  /// No description provided for @selectInfraction.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner l\'infraction'**
  String get selectInfraction;

  /// No description provided for @fineAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant de l\'amende'**
  String get fineAmount;

  /// No description provided for @digitalSignature.
  ///
  /// In fr, this message translates to:
  /// **'Signature numérique'**
  String get digitalSignature;

  /// No description provided for @confirmInterpellation.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l\'interpellation'**
  String get confirmInterpellation;

  /// No description provided for @interpellationSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Interpellation enregistrée'**
  String get interpellationSuccess;

  /// No description provided for @driverHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique du conducteur'**
  String get driverHistory;

  /// No description provided for @unpaidFines.
  ///
  /// In fr, this message translates to:
  /// **'Amendes impayées'**
  String get unpaidFines;

  /// No description provided for @paidFines.
  ///
  /// In fr, this message translates to:
  /// **'Amendes payées'**
  String get paidFines;

  /// No description provided for @totalFines.
  ///
  /// In fr, this message translates to:
  /// **'Total des amendes'**
  String get totalFines;

  /// No description provided for @activeFines.
  ///
  /// In fr, this message translates to:
  /// **'Amendes actives'**
  String get activeFines;

  /// No description provided for @paymentStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut de paiement'**
  String get paymentStatus;

  /// No description provided for @payNow.
  ///
  /// In fr, this message translates to:
  /// **'Payer maintenant'**
  String get payNow;

  /// No description provided for @paymentMethod.
  ///
  /// In fr, this message translates to:
  /// **'Méthode de paiement'**
  String get paymentMethod;

  /// No description provided for @mtnMobileMoney.
  ///
  /// In fr, this message translates to:
  /// **'MTN Mobile Money'**
  String get mtnMobileMoney;

  /// No description provided for @airtelMoney.
  ///
  /// In fr, this message translates to:
  /// **'Airtel Money'**
  String get airtelMoney;

  /// No description provided for @paymentSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Paiement réussi'**
  String get paymentSuccess;

  /// No description provided for @paymentProcessing.
  ///
  /// In fr, this message translates to:
  /// **'Traitement en cours...'**
  String get paymentProcessing;

  /// No description provided for @downloadReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le reçu'**
  String get downloadReceipt;

  /// No description provided for @licenseStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut du permis'**
  String get licenseStatus;

  /// No description provided for @licenseValid.
  ///
  /// In fr, this message translates to:
  /// **'Permis valide'**
  String get licenseValid;

  /// No description provided for @licenseSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Permis suspendu'**
  String get licenseSuspended;

  /// No description provided for @licenseExpired.
  ///
  /// In fr, this message translates to:
  /// **'Permis expiré'**
  String get licenseExpired;

  /// No description provided for @licenseNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de permis'**
  String get licenseNumber;

  /// No description provided for @expiryDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'expiration'**
  String get expiryDate;

  /// No description provided for @points.
  ///
  /// In fr, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @pointsRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Points restants'**
  String get pointsRemaining;

  /// No description provided for @analyticsOverview.
  ///
  /// In fr, this message translates to:
  /// **'Vue analytique'**
  String get analyticsOverview;

  /// No description provided for @totalInfractions.
  ///
  /// In fr, this message translates to:
  /// **'Total infractions'**
  String get totalInfractions;

  /// No description provided for @revenueOverview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu revenus'**
  String get revenueOverview;

  /// No description provided for @paymentRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de paiement'**
  String get paymentRate;

  /// No description provided for @activeOfficers.
  ///
  /// In fr, this message translates to:
  /// **'Agents actifs'**
  String get activeOfficers;

  /// No description provided for @officersManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des agents'**
  String get officersManagement;

  /// No description provided for @revenueDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau revenus'**
  String get revenueDashboard;

  /// No description provided for @interactiveMap.
  ///
  /// In fr, this message translates to:
  /// **'Carte interactive'**
  String get interactiveMap;

  /// No description provided for @riskZones.
  ///
  /// In fr, this message translates to:
  /// **'Zones à risque'**
  String get riskZones;

  /// No description provided for @heatmap.
  ///
  /// In fr, this message translates to:
  /// **'Carte thermique'**
  String get heatmap;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner la langue'**
  String get selectLanguage;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get english;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get darkMode;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// No description provided for @version.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @support.
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer'**
  String get filter;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @submit.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre'**
  String get submit;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée'**
  String get noData;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @success.
  ///
  /// In fr, this message translates to:
  /// **'Succès'**
  String get success;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In fr, this message translates to:
  /// **'Avertissement'**
  String get warning;

  /// No description provided for @fcfa.
  ///
  /// In fr, this message translates to:
  /// **'FCFA'**
  String get fcfa;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In fr, this message translates to:
  /// **'Cette année'**
  String get thisYear;

  /// No description provided for @infraction_speeding.
  ///
  /// In fr, this message translates to:
  /// **'Excès de vitesse'**
  String get infraction_speeding;

  /// No description provided for @infraction_noHelmet.
  ///
  /// In fr, this message translates to:
  /// **'Sans casque'**
  String get infraction_noHelmet;

  /// No description provided for @infraction_redLight.
  ///
  /// In fr, this message translates to:
  /// **'Grillage de feu rouge'**
  String get infraction_redLight;

  /// No description provided for @infraction_noSeatbelt.
  ///
  /// In fr, this message translates to:
  /// **'Sans ceinture'**
  String get infraction_noSeatbelt;

  /// No description provided for @infraction_noLicense.
  ///
  /// In fr, this message translates to:
  /// **'Sans permis'**
  String get infraction_noLicense;

  /// No description provided for @infraction_noRegistration.
  ///
  /// In fr, this message translates to:
  /// **'Sans carte grise'**
  String get infraction_noRegistration;

  /// No description provided for @infraction_phone.
  ///
  /// In fr, this message translates to:
  /// **'Usage téléphone au volant'**
  String get infraction_phone;

  /// No description provided for @infraction_parking.
  ///
  /// In fr, this message translates to:
  /// **'Stationnement interdit'**
  String get infraction_parking;

  /// No description provided for @infraction_noInsurance.
  ///
  /// In fr, this message translates to:
  /// **'Sans assurance'**
  String get infraction_noInsurance;

  /// No description provided for @infraction_overload.
  ///
  /// In fr, this message translates to:
  /// **'Surcharge'**
  String get infraction_overload;

  /// No description provided for @status_pending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get status_pending;

  /// No description provided for @status_paid.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get status_paid;

  /// No description provided for @status_overdue.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get status_overdue;

  /// No description provided for @status_contested.
  ///
  /// In fr, this message translates to:
  /// **'Contesté'**
  String get status_contested;

  /// No description provided for @status_cancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get status_cancelled;

  /// No description provided for @officer_active.
  ///
  /// In fr, this message translates to:
  /// **'En service'**
  String get officer_active;

  /// No description provided for @officer_inactive.
  ///
  /// In fr, this message translates to:
  /// **'Hors service'**
  String get officer_inactive;

  /// No description provided for @officer_suspended.
  ///
  /// In fr, this message translates to:
  /// **'Suspendu'**
  String get officer_suspended;

  /// No description provided for @brazzaville.
  ///
  /// In fr, this message translates to:
  /// **'Brazzaville'**
  String get brazzaville;

  /// No description provided for @pointeNoire.
  ///
  /// In fr, this message translates to:
  /// **'Pointe-Noire'**
  String get pointeNoire;

  /// No description provided for @republic_congo.
  ///
  /// In fr, this message translates to:
  /// **'République du Congo'**
  String get republic_congo;

  /// No description provided for @ministry.
  ///
  /// In fr, this message translates to:
  /// **'Ministère de l\'Intérieur'**
  String get ministry;

  /// No description provided for @splashTagline.
  ///
  /// In fr, this message translates to:
  /// **'Infrastructure Nationale de Contrôle Routier'**
  String get splashTagline;

  /// No description provided for @poweredBy.
  ///
  /// In fr, this message translates to:
  /// **'Propulsé par la DGST'**
  String get poweredBy;

  /// No description provided for @officerPortal.
  ///
  /// In fr, this message translates to:
  /// **'Portail Agent'**
  String get officerPortal;

  /// No description provided for @citizenPortal.
  ///
  /// In fr, this message translates to:
  /// **'Portail Citoyen'**
  String get citizenPortal;

  /// No description provided for @adminPortal.
  ///
  /// In fr, this message translates to:
  /// **'Portail Administrateur'**
  String get adminPortal;

  /// No description provided for @clearSignature.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get clearSignature;

  /// No description provided for @signHere.
  ///
  /// In fr, this message translates to:
  /// **'Signez ici'**
  String get signHere;

  /// No description provided for @vehicleInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations véhicule'**
  String get vehicleInfo;

  /// No description provided for @driverInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations conducteur'**
  String get driverInfo;

  /// No description provided for @infractionDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails de l\'infraction'**
  String get infractionDetails;

  /// No description provided for @location.
  ///
  /// In fr, this message translates to:
  /// **'Localisation'**
  String get location;

  /// No description provided for @date.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get time;

  /// No description provided for @officer.
  ///
  /// In fr, this message translates to:
  /// **'Agent'**
  String get officer;

  /// No description provided for @vehicle.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule'**
  String get vehicle;

  /// No description provided for @driver.
  ///
  /// In fr, this message translates to:
  /// **'Conducteur'**
  String get driver;

  /// No description provided for @plate.
  ///
  /// In fr, this message translates to:
  /// **'Plaque'**
  String get plate;

  /// No description provided for @brand.
  ///
  /// In fr, this message translates to:
  /// **'Marque'**
  String get brand;

  /// No description provided for @model.
  ///
  /// In fr, this message translates to:
  /// **'Modèle'**
  String get model;

  /// No description provided for @color.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get color;

  /// No description provided for @year.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get year;

  /// No description provided for @firstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get lastName;

  /// No description provided for @birthDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get birthDate;

  /// No description provided for @address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get address;

  /// No description provided for @phoneNumber.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phoneNumber;

  /// No description provided for @amount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get amount;

  /// No description provided for @deadline.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get deadline;

  /// No description provided for @reference.
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get reference;

  /// No description provided for @print.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer'**
  String get print;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
