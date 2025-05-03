class Cotizacion {
  final int? id;
  final double valor;
  final DateTime fecha;

  Cotizacion({this.id, required this.valor, required this.fecha});

  Map<String, dynamic> toMap() {
    return {'id': id, 'valor': valor, 'fecha': fecha.toIso8601String()};
  }

  factory Cotizacion.fromMap(Map<String, dynamic> map) {
    return Cotizacion(
      id: map['id'] as int,
      valor: map['valor'] as double,
      fecha: DateTime.parse(map['fecha'] as String),
    );
  }
}
