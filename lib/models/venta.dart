class Venta {
  final int? id;
  final int clienteId;
  final String fechaHora;
  final String moneda;
  final double cotizacion;
  final double totalBob;
  final double totalArs;

  Venta({
    this.id,
    required this.clienteId,
    required this.fechaHora,
    required this.moneda,
    required this.cotizacion,
    required this.totalBob,
    required this.totalArs,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'fecha_hora': fechaHora,
      'moneda': moneda,
      'cotizacion': cotizacion,
      'total_bob': totalBob,
      'total_ars': totalArs,
    };
  }

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'] as int?,
      clienteId: map['cliente_id'] as int,
      fechaHora: map['fecha_hora'] as String,
      moneda: map['moneda'] as String,
      cotizacion: map['cotizacion'] as double,
      totalBob: map['total_bob'] as double,
      totalArs: map['total_ars'] as double,
    );
  }
}
