class Cliente {
  final int? id;
  final String nombre;

  Cliente({this.id, required this.nombre});

  Map<String, dynamic> toMap() {
    return {'id': id, 'nombre': nombre};
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(id: map['id'] as int?, nombre: map['nombre'] as String);
  }
}
