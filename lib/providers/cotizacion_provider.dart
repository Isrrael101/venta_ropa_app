import 'package:flutter/foundation.dart';
import '../models/database_helper.dart';
import '../models/cotizacion.dart';

class CotizacionProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  double _cotizacionActual = 0.01095;

  double get cotizacionActual => _cotizacionActual;

  Future<void> cargarUltimaCotizacion() async {
    final cotizacion = await _db.getUltimaCotizacion();
    if (cotizacion != null) {
      _cotizacionActual = cotizacion.valor;
      notifyListeners();
    }
  }

  Future<void> cargarCotizacionPorFecha(DateTime fecha) async {
    final cotizacion = await _db.getCotizacionByFecha(fecha);
    if (cotizacion != null) {
      _cotizacionActual = cotizacion.valor;
      notifyListeners();
    }
  }

  Future<bool> guardarCotizacion(double valor) async {
    try {
      final cotizacion = Cotizacion(valor: valor, fecha: DateTime.now());
      await _db.insertCotizacion(cotizacion);
      _cotizacionActual = valor;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al guardar cotización: $e');
      return false;
    }
  }

  Future<List<Cotizacion>> getHistorialCotizaciones() async {
    return await _db.getCotizaciones();
  }
}
