enum NotificationType { fine, payment, alert, system, info }

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? actionId;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.actionId,
  });

  static final List<NotificationModel> mockOfficerNotifications = [
    NotificationModel(
      id: 'NOT001',
      type: NotificationType.alert,
      title: 'Zone de contrôle activée',
      body: 'Nouvelle zone de contrôle renforcé activée sur l\'Avenue de l\'Indépendance.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      isRead: false,
    ),
    NotificationModel(
      id: 'NOT002',
      type: NotificationType.system,
      title: 'Objectif journalier atteint',
      body: 'Vous avez atteint votre objectif de 10 interpellations aujourd\'hui. Félicitations!',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    NotificationModel(
      id: 'NOT003',
      type: NotificationType.info,
      title: 'Réunion de brigade',
      body: 'Rappel : réunion mensuelle demain à 08h00 au commissariat central.',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    NotificationModel(
      id: 'NOT004',
      type: NotificationType.fine,
      title: 'Amende contestée',
      body: 'L\'amende CP-2024-001523 a été contestée par le conducteur Nguesso T.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  static final List<NotificationModel> mockCitizenNotifications = [
    NotificationModel(
      id: 'NOT101',
      type: NotificationType.fine,
      title: 'Nouvelle amende reçue',
      body: 'Une amende de 30 000 FCFA vous a été émise pour excès de vitesse.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      isRead: false,
      actionId: 'FIN001',
    ),
    NotificationModel(
      id: 'NOT102',
      type: NotificationType.alert,
      title: 'Délai de paiement',
      body: 'L\'amende CP-2024-001847 expire dans 25 jours. Payez maintenant pour éviter les pénalités.',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      isRead: false,
      actionId: 'FIN001',
    ),
    NotificationModel(
      id: 'NOT103',
      type: NotificationType.payment,
      title: 'Paiement confirmé',
      body: 'Votre paiement de 20 000 FCFA a été reçu. Référence: MTN-2024-78923.',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      isRead: true,
      actionId: 'FIN002',
    ),
    NotificationModel(
      id: 'NOT104',
      type: NotificationType.info,
      title: 'Renouvellement permis',
      body: 'Votre permis de conduire expire dans 30 jours. Pensez à le renouveler.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
  ];
}
