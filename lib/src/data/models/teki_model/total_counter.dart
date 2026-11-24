class TotalCounter {
  final int total;

  TotalCounter({required this.total});

  factory TotalCounter.fromJson(Map<String, dynamic> json) {
    return TotalCounter(
      total: json['totalElements'] ?? 0,
    );
  }
}
