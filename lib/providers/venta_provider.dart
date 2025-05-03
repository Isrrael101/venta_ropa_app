import 'package:flutter/foundation.dart';
import '../models/database_helper.dart';
import '../models/cliente.dart';
import '../models/venta.dart';
import '../models/detalle_venta.dart';
import '../models/detalle_venta_con_cliente.dart';

class VentaProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Cotización predeterminada (1 ARS = X BOB)
  double _cotizacion = 1.0;

  // Cliente seleccionado
  Cliente? _clienteSeleccionado;

  // Lista de productos en la venta actual
  List<DetalleVenta> _carrito = [];

  // Moneda seleccionada para la venta (BOB o ARS)
  String _moneda = 'BOB';

  // Getters
  double get cotizacion => _cotizacion;
  Cliente? get clienteSeleccionado => _clienteSeleccionado;
  List<DetalleVenta> get carrito => _carrito;
  String get moneda => _moneda;

  // Totales calculados
  double get totalBob =>
      _carrito.fold(0, (sum, item) => sum + item.subtotalBob);

  double get totalArs =>
      _carrito.fold(0, (sum, item) => sum + item.subtotalArs);

  // Setters
  void setCotizacion(double value) {
    _cotizacion = value;
    notifyListeners();
  }

  void setCliente(Cliente? cliente) {
    _clienteSeleccionado = cliente;
    notifyListeners();
  }

  void setMoneda(String moneda) {
    _moneda = moneda;
    notifyListeners();
  }

  // Métodos para gestionar el carrito
  void agregarAlCarrito(DetalleVenta detalle) {
    _carrito.add(detalle);
    notifyListeners();
  }

  void eliminarDelCarrito(int index) {
    if (index >= 0 && index < _carrito.length) {
      _carrito.removeAt(index);
      notifyListeners();
    }
  }

  void limpiarCarrito() {
    _carrito.clear();
    _clienteSeleccionado = null;
    _moneda = 'BOB';
    _cotizacion = 1.0;
    notifyListeners();
  }

  // Calcular precio en la otra moneda
  double calcularPrecioEquivalente(double precio, String monedaOrigen) {
    if (monedaOrigen == 'BOB') {
      return DatabaseHelper.convertBobToArs(precio, _cotizacion);
    } else {
      return DatabaseHelper.convertArsToBob(precio, _cotizacion);
    }
  }

  // Guardar la venta completa en la base de datos
  Future<bool> guardarVenta() async {
    if (_clienteSeleccionado == null || _carrito.isEmpty) {
      return false;
    }

    try {
      final venta = Venta(
        clienteId: _clienteSeleccionado!.id!,
        fechaHora: DatabaseHelper.getCurrentDateTime(),
        moneda: _moneda,
        cotizacion: _cotizacion,
        totalBob: totalBob,
        totalArs: totalArs,
      );

      final ventaId = await _dbHelper.insertVenta(venta);
      if (ventaId != 0) {
        for (var detalle in _carrito) {
          await _dbHelper.insertDetalleVenta(
            DetalleVenta(
              ventaId: ventaId,
              descripcion: detalle.descripcion,
              cantidad: detalle.cantidad,
              precioUnitarioBob: detalle.precioUnitarioBob,
              precioUnitarioArs: detalle.precioUnitarioArs,
              subtotalBob: detalle.subtotalBob,
              subtotalArs: detalle.subtotalArs,
            ),
          );
        }
        limpiarCarrito();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al guardar la venta: $e');
      return false;
    }
  }

  // Actualizar una venta existente
  Future<bool> actualizarVenta(Venta venta, List<DetalleVenta> detalles) async {
    try {
      // Verificar si la venta existe
      final ventaExistente = await _dbHelper.getVenta(venta.id!);
      if (ventaExistente == null) {
        debugPrint('La venta no existe');
        return false;
      }

      // Verificar que haya al menos un detalle
      if (detalles.isEmpty) {
        debugPrint('La venta debe tener al menos un detalle');
        return false;
      }

      // Actualizar la venta y sus detalles
      return await _dbHelper.updateVentaCompleta(venta, detalles);
    } catch (e) {
      debugPrint('Error al actualizar la venta: $e');
      return false;
    }
  }

  // Eliminar una venta
  Future<bool> eliminarVenta(int id) async {
    try {
      // Verificar si la venta existe
      final ventaExistente = await _dbHelper.getVenta(id);
      if (ventaExistente == null) {
        debugPrint('La venta no existe');
        return false;
      }

      // Eliminar la venta y sus detalles
      final resultado = await _dbHelper.deleteVenta(id);
      return resultado != 0;
    } catch (e) {
      debugPrint('Error al eliminar la venta: $e');
      return false;
    }
  }

  // Obtener historial completo de ventas con detalles y cliente
  Future<List<DetalleVentaConCliente>> getDetallesConCliente() async {
    return await _dbHelper.getDetallesConCliente();
  }

  Future<List<DetalleVentaConCliente>> getDetallesConClienteByFecha(
    String fecha,
  ) async {
    return await _dbHelper.getDetallesConClienteByFecha(fecha);
  }

  Future<void> cargarVentaEnCarrito(Venta venta) async {
    try {
      // Verificar si la venta existe
      final ventaExistente = await _dbHelper.getVenta(venta.id!);
      if (ventaExistente == null) {
        debugPrint('La venta no existe');
        return;
      }

      // Limpiar el carrito actual
      limpiarCarrito();

      // Cargar el cliente
      final cliente = await _dbHelper.getCliente(venta.clienteId);
      if (cliente != null) {
        _clienteSeleccionado = cliente;
      }

      // Cargar la moneda y cotización
      _moneda = venta.moneda;
      _cotizacion = venta.cotizacion;

      // Cargar los detalles
      final detalles = await _dbHelper.getDetallesByVenta(venta.id!);
      _carrito = detalles;

      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar la venta en el carrito: $e');
    }
  }
}
