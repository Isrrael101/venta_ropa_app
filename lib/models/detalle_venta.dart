class DetalleVenta {
  final int? id;
  final int? ventaId;
  final String descripcion;
  final int cantidad;
  double precioUnitarioBob;
  double precioUnitarioArs;
  double subtotalBob;
  double subtotalArs;

  DetalleVenta({
    this.id,
    this.ventaId,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitarioBob,
    required this.precioUnitarioArs,
    required this.subtotalBob,
    required this.subtotalArs,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venta_id': ventaId,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'precio_unitario_bob': precioUnitarioBob,
      'precio_unitario_ars': precioUnitarioArs,
      'subtotal_bob': subtotalBob,
      'subtotal_ars': subtotalArs,
    };
  }

  factory DetalleVenta.fromMap(Map<String, dynamic> map) {
    return DetalleVenta(
      id: map['id'] as int?,
      ventaId: map['venta_id'] as int?,
      descripcion: map['descripcion'] as String,
      cantidad: map['cantidad'] as int,
      precioUnitarioBob: map['precio_unitario_bob'] as double,
      precioUnitarioArs: map['precio_unitario_ars'] as double,
      subtotalBob: map['subtotal_bob'] as double,
      subtotalArs: map['subtotal_ars'] as double,
    );
  }
}
