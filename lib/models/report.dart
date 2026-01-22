enum ReportCategory {
  bache,
  luminaria,
  basura,
  alcantarilla,
  otro,
}

enum ReportStatus {
  pendiente,
  en_proceso,
  resuelto,
}

class Report {
  final String id;
  final String usuarioId;
  final String titulo;
  final String descripcion;
  final ReportCategory categoria;
  final ReportStatus estado;
  final double latitud;
  final double longitud;
  final String? fotoUrl;
  final DateTime createdAt;

  Report({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.estado,
    required this.latitud,
    required this.longitud,
    this.fotoUrl,
    required this.createdAt,
  });

  // Convertir de JSON (desde Supabase)
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      categoria: _parseCategory(json['categoria'] as String),
      estado: _parseStatus(json['estado'] as String),
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      fotoUrl: json['foto_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convertir a JSON (para enviar a Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': _categoryToString(categoria),
      'estado': _statusToString(estado),
      'latitud': latitud,
      'longitud': longitud,
      'foto_url': fotoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copiar con cambios
  Report copyWith({
    String? id,
    String? usuarioId,
    String? titulo,
    String? descripcion,
    ReportCategory? categoria,
    ReportStatus? estado,
    double? latitud,
    double? longitud,
    String? fotoUrl,
    DateTime? createdAt,
  }) {
    return Report(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      estado: estado ?? this.estado,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helpers para convertir enums
  static ReportCategory _parseCategory(String value) {
    return ReportCategory.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => ReportCategory.otro,
    );
  }

  static ReportStatus _parseStatus(String value) {
    return ReportStatus.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => ReportStatus.pendiente,
    );
  }

  static String _categoryToString(ReportCategory category) {
    return category.toString().split('.').last;
  }

  static String _statusToString(ReportStatus status) {
    return status.toString().split('.').last;
  }

  // Obtener nombre legible de la categoría
  String getCategoryDisplay() {
    switch (categoria) {
      case ReportCategory.bache:
        return 'Bache';
      case ReportCategory.luminaria:
        return 'Luminaria dañada';
      case ReportCategory.basura:
        return 'Acumulación de basura';
      case ReportCategory.alcantarilla:
        return 'Alcantarilla obstruida';
      case ReportCategory.otro:
        return 'Otro';
    }
  }

  // Obtener nombre legible del estado
  String getStatusDisplay() {
    switch (estado) {
      case ReportStatus.pendiente:
        return 'Pendiente';
      case ReportStatus.en_proceso:
        return 'En proceso';
      case ReportStatus.resuelto:
        return 'Resuelto';
    }
  }
}
