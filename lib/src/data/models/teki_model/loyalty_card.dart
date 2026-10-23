class LoyaltyCard {
  final int id;
  final int? sellosParaPremio;
  final String nombre;
  final String? slug;
  final bool activo;
  final bool principal;
  final bool permitirSellos;
  final bool permitirPuntos;
  final bool permitirMembresia;
  final String? textoRecompensa;
  final String? logoUrl;
  final String? heroImageUrl;
  final String? hexBackgroundColor;

  const LoyaltyCard({
    required this.id,
    this.sellosParaPremio,
    required this.nombre,
    this.slug,
    this.activo = false,
    this.principal = false,
    this.permitirSellos = false,
    this.permitirPuntos = false,
    this.permitirMembresia = false,
    this.textoRecompensa,
    this.logoUrl,
    this.heroImageUrl,
    this.hexBackgroundColor,
  });

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) => LoyaltyCard(
    id: (json['id'] as num).toInt(),
    sellosParaPremio: (json['sellosParaPremio'] as num?)?.toInt(),
    nombre: (json['nombre'] as String?)?.trim() ?? 'Tarjeta de fidelización',
    slug: json['slug'] as String?,
    activo: json['activo'] == true,
    principal: json['principal'] == true,
    permitirSellos: json['permitirSellos'] == true,
    permitirPuntos: json['permitirPuntos'] == true,
    permitirMembresia: json['permitirMembresia'] == true,
    textoRecompensa: json['textoRecompensa'] as String?,
    logoUrl: json['logoUrl'] as String?,
    heroImageUrl: json['heroImageUrl'] as String?,
    hexBackgroundColor: json['hexBackgroundColor'] as String?,
  );

  String get tipo => [
    if (permitirSellos) 'Sellos',
    if (permitirPuntos) 'Puntos',
    if (permitirMembresia) 'Membresía',
  ].join(' · ');
}
