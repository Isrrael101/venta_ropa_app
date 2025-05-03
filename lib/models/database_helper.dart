import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'cliente.dart';
import 'venta.dart';
import 'detalle_venta.dart';
import 'detalle_venta_con_cliente.dart';
import 'cotizacion.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ventas_ropa.db');
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clientes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ventas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        fecha_hora TEXT NOT NULL,
        moneda TEXT,
        cotizacion REAL,
        total_bob REAL,
        total_ars REAL,
        FOREIGN KEY (cliente_id) REFERENCES clientes (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE detalles_venta(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL,
        descripcion TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario_bob REAL NOT NULL,
        precio_unitario_ars REAL NOT NULL,
        subtotal_bob REAL NOT NULL,
        subtotal_ars REAL NOT NULL,
        FOREIGN KEY (venta_id) REFERENCES ventas (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cotizaciones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valor REAL NOT NULL,
        fecha TEXT NOT NULL
      )
    ''');
  }

  // Métodos para Cliente
  Future<int> insertCliente(Cliente cliente) async {
    Database db = await database;
    return await db.insert('clientes', cliente.toMap());
  }

  Future<int> updateCliente(Cliente cliente) async {
    Database db = await database;
    try {
      return await db.update(
        'clientes',
        cliente.toMap(),
        where: 'id = ?',
        whereArgs: [cliente.id],
      );
    } catch (e) {
      debugPrint('Error en updateCliente: $e');
      return 0;
    }
  }

  Future<int> deleteCliente(int id) async {
    Database db = await database;
    try {
      return await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('Error en deleteCliente: $e');
      return 0;
    }
  }

  Future<List<Cliente>> getClientes() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clientes',
      orderBy: 'nombre',
    );
    return List.generate(maps.length, (i) {
      return Cliente.fromMap(maps[i]);
    });
  }

  Future<Cliente?> getCliente(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Cliente.fromMap(maps.first);
    }
    return null;
  }

  // Métodos para Venta
  Future<int> insertVenta(Venta venta) async {
    Database db = await database;
    return await db.insert('ventas', venta.toMap());
  }

  Future<int> updateVenta(Venta venta) async {
    Database db = await database;
    try {
      return await db.update(
        'ventas',
        venta.toMap(),
        where: 'id = ?',
        whereArgs: [venta.id],
      );
    } catch (e) {
      debugPrint('Error en updateVenta: $e');
      return 0;
    }
  }

  Future<int> deleteVenta(int id) async {
    Database db = await database;
    try {
      // Usar una transacción para asegurar la integridad de los datos
      return await db.transaction((txn) async {
        // Primero eliminar los detalles de la venta
        await txn.delete(
          'detalles_venta',
          where: 'venta_id = ?',
          whereArgs: [id],
        );

        // Luego eliminar la venta
        return await txn.delete('ventas', where: 'id = ?', whereArgs: [id]);
      });
    } catch (e) {
      debugPrint('Error en deleteVenta: $e');
      return 0;
    }
  }

  Future<List<Venta>> getVentas() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ventas',
      orderBy: 'fecha_hora DESC',
    );
    return List.generate(maps.length, (i) {
      return Venta.fromMap(maps[i]);
    });
  }

  Future<List<Venta>> getVentasPorCliente(int clienteId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ventas',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
    );
    return List.generate(maps.length, (i) {
      return Venta.fromMap(maps[i]);
    });
  }

  // Métodos para DetalleVenta
  Future<int> insertDetalleVenta(DetalleVenta detalleVenta) async {
    Database db = await database;
    return await db.insert('detalles_venta', detalleVenta.toMap());
  }

  Future<int> updateDetalleVenta(DetalleVenta detalleVenta) async {
    Database db = await database;
    try {
      return await db.update(
        'detalles_venta',
        detalleVenta.toMap(),
        where: 'id = ?',
        whereArgs: [detalleVenta.id],
      );
    } catch (e) {
      debugPrint('Error en updateDetalleVenta: $e');
      return 0;
    }
  }

  Future<int> deleteDetalleVenta(int id) async {
    Database db = await database;
    return await db.delete('detalles_venta', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DetalleVenta>> getDetallesByVenta(int ventaId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'detalles_venta',
      where: 'venta_id = ?',
      whereArgs: [ventaId],
    );
    return List.generate(maps.length, (i) {
      return DetalleVenta.fromMap(maps[i]);
    });
  }

  // Consulta para obtener detalles con información del cliente
  Future<List<DetalleVentaConCliente>> getDetallesConCliente() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        dv.id,
        dv.venta_id,
        c.nombre as cliente_nombre,
        dv.descripcion,
        dv.cantidad,
        dv.precio_unitario_bob,
        dv.precio_unitario_ars,
        dv.subtotal_bob,
        dv.subtotal_ars,
        v.fecha_hora
      FROM 
        detalles_venta dv
      JOIN 
        ventas v ON dv.venta_id = v.id
      JOIN 
        clientes c ON v.cliente_id = c.id
      ORDER BY 
        v.fecha_hora DESC, dv.id
    ''');
    return List.generate(maps.length, (i) {
      return DetalleVentaConCliente.fromMap(maps[i]);
    });
  }

  // Consulta para obtener detalles con información del cliente filtrados por fecha
  Future<List<DetalleVentaConCliente>> getDetallesConClienteByFecha(
    String fecha,
  ) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        dv.id,
        dv.venta_id,
        c.nombre as cliente_nombre,
        dv.descripcion,
        dv.cantidad,
        dv.precio_unitario_bob,
        dv.precio_unitario_ars,
        dv.subtotal_bob,
        dv.subtotal_ars,
        v.fecha_hora
      FROM 
        detalles_venta dv
      JOIN 
        ventas v ON dv.venta_id = v.id
      JOIN 
        clientes c ON v.cliente_id = c.id
      WHERE
        v.fecha_hora LIKE '$fecha%'
      ORDER BY 
        v.fecha_hora DESC, dv.id
    ''');
    return List.generate(maps.length, (i) {
      return DetalleVentaConCliente.fromMap(maps[i]);
    });
  }

  // Método para actualizar una venta completa con sus detalles
  Future<bool> updateVentaCompleta(
    Venta venta,
    List<DetalleVenta> detalles,
  ) async {
    Database db = await database;
    try {
      return await db.transaction((txn) async {
        // Actualizar la venta principal
        final ventaResult = await txn.update(
          'ventas',
          venta.toMap(),
          where: 'id = ?',
          whereArgs: [venta.id],
        );

        if (ventaResult == 0) {
          throw Exception('No se pudo actualizar la venta');
        }

        // Eliminar los detalles existentes
        await txn.delete(
          'detalles_venta',
          where: 'venta_id = ?',
          whereArgs: [venta.id],
        );

        // Insertar los nuevos detalles
        for (var detalle in detalles) {
          await txn.insert('detalles_venta', {
            ...detalle.toMap(),
            'venta_id': venta.id,
          });
        }

        return true;
      });
    } catch (e) {
      debugPrint('Error en updateVentaCompleta: $e');
      return false;
    }
  }

  // Métodos de utilidad
  static String getCurrentDateTime() {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  }

  static double convertBobToArs(double bobAmount, double cotizacion) {
    return bobAmount / cotizacion;
  }

  static double convertArsToBob(double arsAmount, double cotizacion) {
    return arsAmount * cotizacion;
  }

  Future<Venta?> getVenta(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ventas',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Venta.fromMap(maps.first);
    }
    return null;
  }

  // Métodos para cotizaciones
  Future<int> insertCotizacion(Cotizacion cotizacion) async {
    final db = await database;
    return await db.insert('cotizaciones', cotizacion.toMap());
  }

  Future<List<Cotizacion>> getCotizaciones() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cotizaciones',
      orderBy: 'fecha DESC',
    );
    return List.generate(maps.length, (i) => Cotizacion.fromMap(maps[i]));
  }

  Future<Cotizacion?> getUltimaCotizacion() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cotizaciones',
      orderBy: 'fecha DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Cotizacion.fromMap(maps.first);
  }

  Future<Cotizacion?> getCotizacionByFecha(DateTime fecha) async {
    final db = await database;
    final fechaStr = fecha.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'cotizaciones',
      where: 'date(fecha) = ?',
      whereArgs: [fechaStr],
      orderBy: 'fecha DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Cotizacion.fromMap(maps.first);
  }
}
