import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_preferences_provider.dart';

final languageProvider = NotifierProvider<LanguageNotifier, String>(() {
  return LanguageNotifier();
});

class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('language_code') ?? 'en';
  }

  Future<void> setLanguage(String code) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('language_code', code);
    state = code;
  }
}

String tr(String key, String lang) {
  final Map<String, Map<String, String>> strings = {
    'en': {
      'personal_info': 'Personal Information',
      'full_name': 'Full Name',
      'email_address': 'Email Address',
      'phone_number': 'Phone Number',
      'lang_pref': 'Language & Preferences',
      'lang_settings': 'Language Settings',
      'security_settings': 'Security Settings',
      'change_password': 'Change Password',
      'biometric_login': 'Biometric PIN Login',
      'log_out': 'LOG OUT',
      'manage_availability': 'Manage Availability',
      'dashboard': 'Dashboard',
      'notifications': 'Notifications',
      'upcoming_appointments': 'Upcoming Appointments',
      'health_tips': 'Health Tips',
      'search_patients': 'Search patients or files...',
      'consulted_patients': 'Consulted Patients',
      'request_file_access': 'Request File Access',
      'patient_account': 'PATIENT ACCOUNT',
      'doctor_account': 'DOCTOR ACCOUNT',
      'no_notifications': 'No notifications at this time.',
      'appointment_reminder': 'Appointment reminder',
      'appointment_reminder_desc': 'Your next consultation is coming up.',
      'new_message': 'New message',
      'new_message_desc': 'You have a new care-team message.',
      'prescription_update': 'Prescription update',
      'prescription_update_desc': 'A digital prescription was updated.',
      'active_appointments': 'Active Appointments',
      'completed': 'Completed',
      'upcoming': 'Upcoming',
      'pending': 'Pending',
      'cancelled': 'Cancelled',
      'unread_chats': 'Unread Chats',
      'todays_patients': "Today's Patients",
      'welcome': 'Welcome',
      'view_all': 'View All',
      'recent_chats': 'Recent Chats',
      'edit_phone': 'Edit Phone Number',
      'change_photo': 'Change Profile Photo',
    },
    'fr': {
      'personal_info': 'Informations Personnelles',
      'full_name': 'Nom Complet',
      'email_address': 'Adresse E-mail',
      'phone_number': 'Numéro de Téléphone',
      'lang_pref': 'Langue et Préférences',
      'lang_settings': 'Paramètres de Langue',
      'security_settings': 'Paramètres de Sécurité',
      'change_password': 'Modifier le Mot de Passe',
      'biometric_login': 'Connexion Biométrique PIN',
      'log_out': 'SE DÉCONNECTER',
      'manage_availability': 'Gérer la Disponibilité',
      'dashboard': 'Tableau de bord',
      'notifications': 'Notifications',
      'upcoming_appointments': 'Rendez-vous à Venir',
      'health_tips': 'Conseils de Santé',
      'search_patients': 'Rechercher des patients ou des fichiers...',
      'consulted_patients': 'Patients Consultés',
      'request_file_access': 'Demander l\'Accès aux Fichiers',
      'patient_account': 'COMPTE PATIENT',
      'doctor_account': 'COMPTE MÉDECIN',
      'no_notifications': 'Aucune notification pour le moment.',
      'appointment_reminder': 'Rappel de rendez-vous',
      'appointment_reminder_desc': 'Votre prochaine consultation approche.',
      'new_message': 'Nouveau message',
      'new_message_desc': 'Vous avez un nouveau message de l\'équipe de soins.',
      'prescription_update': 'Mise à jour de l\'ordonnance',
      'prescription_update_desc': 'Une ordonnance numérique a été mise à jour.',
      'active_appointments': 'Rendez-vous Actifs',
      'completed': 'Complété',
      'upcoming': 'À Venir',
      'pending': 'En Attente',
      'cancelled': 'Annulé',
      'unread_chats': 'Discussion non lues',
      'todays_patients': "Patients d'aujourd'hui",
      'welcome': 'Bienvenue',
      'view_all': 'Voir Tout',
      'recent_chats': 'Discussions Récentes',
      'edit_phone': 'Modifier le numéro de téléphone',
      'change_photo': 'Modifier la photo de profil',
    }
  };
  return strings[lang]?[key] ?? key;
}
