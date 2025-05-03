class DetalleVentaConCliente {
  final int id;
  final int ventaId;
  final String clienteNombre;
  final String descripcion;
  final int cantidad;
  final double precioUnitarioBob;
  final double precioUnitarioArs;
  final double subtotalBob;
  final double subtotalArs;
  final String fechaHora;

  DetalleVentaConCliente({
    required this.id,
    required this.ventaId,
    required this.clienteNombre,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitarioBob,
    required this.precioUnitarioArs,
    required this.subtotalBob,
    required this.subtotalArs,
    required this.fechaHora,
  });

  factory DetalleVentaConCliente.fromMap(Map<String, dynamic> map) {
    return DetalleVentaConCliente(
      id: map['id'] as int,
      ventaId: map['venta_id'] as int,
      clienteNombre: map['cliente_nombre'] as String,
      descripcion: map['descripcion'] as String,
      cantidad: map['cantidad'] as int,
      precioUnitarioBob: map['precio_unitario_bob'] as double,
      precioUnitarioArs: map['precio_unitario_ars'] as double,
      subtotalBob: map['subtotal_bob'] as double,
      subtotalArs: map['subtotal_ars'] as double,
      fechaHora: map['fecha_hora'] as String,
    );
  }
}
