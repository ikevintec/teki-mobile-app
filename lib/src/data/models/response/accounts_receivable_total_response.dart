class AccountsReceivableTotalResponse {
  final double totalCredito;
  final double totalPagado;
  final String codigoMoneda;

  AccountsReceivableTotalResponse({
    required this.totalCredito,
    required this.totalPagado,
    required this.codigoMoneda,
  });

  double get saldo => totalCredito - totalPagado;

  factory AccountsReceivableTotalResponse.fromJson(Map<String, dynamic> json) {
    return AccountsReceivableTotalResponse(
      totalCredito: (json['totalCredito'] as num?)?.toDouble() ?? 0,
      totalPagado: (json['totalPagado'] as num?)?.toDouble() ?? 0,
      codigoMoneda: json['codigoMoneda'] ?? '',
    );
  }
}
