enum FeedbackRating { helpful, notHelpful }

class ActionProposalModel {
  ActionProposalModel({
    required this.id,
    required this.actionType,
    required this.title,
    required this.description,
    required this.payload,
    required this.expiresAt,
    this.isConfirmed = false,
    this.isDismissed = false,
  });

  factory ActionProposalModel.fromJson(Map<String, dynamic> json) =>
      ActionProposalModel(
        id: json['id'] as String,
        actionType: json['actionType'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        payload: json['payload'] as Map<String, dynamic>? ?? {},
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
            DateTime.now().add(const Duration(hours: 1)),
      );

  final String id;
  final String actionType;
  final String title;
  final String description;
  final Map<String, dynamic> payload;
  final DateTime expiresAt;
  bool isConfirmed;
  bool isDismissed;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'id': id,
    'actionType': actionType,
    'title': title,
    'description': description,
    'payload': payload,
    'expiresAt': expiresAt.toIso8601String(),
    'isConfirmed': isConfirmed,
    'isDismissed': isDismissed,
  };
}

class AssistantMessage {
  AssistantMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.references = const [],
    this.actionProposal,
    this.feedback,
    this.isOfflineFallback = false,
    this.errorMessage,
  });

  final String id;
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final List<String> references;
  ActionProposalModel? actionProposal;
  FeedbackRating? feedback;
  final bool isOfflineFallback;
  final String? errorMessage;
}
