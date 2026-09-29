class WhatsappEvolutionMessageRequest {
  final String number;
  final String text;

  const WhatsappEvolutionMessageRequest({
    required this.number,
    required this.text,
  });

  Map<String, dynamic> toJson() => {'number': number, 'text': text};
}
