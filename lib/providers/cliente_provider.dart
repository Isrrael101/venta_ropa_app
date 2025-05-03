import 'package:flutter/foundation.dart';
import '../models/database_helper.dart';
import '../models/cliente.dart';

class ClienteProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Cliente> _clientes = [];
  bool _isLoading = false;

  // Getters
  List<Cliente> get clientes => _clientes;
  bool get isLoading => _isLoading;

  // Cargar clientes de la base de datos
  Future<void> cargarClientes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final clientes = await _dbHelper.getClientes();
      _clientes = clientes;
    } catch (e) {
      debugPrint('Error al cargar clientes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Agregar nuevo cliente
  Future<bool> agregarCliente(String nombre) async {
    if (nombre.trim().isEmpty) {
      return false;
    }

    try {
      final cliente = Cliente(nombre: nombre.trim());
      final id = await _dbHelper.insertCliente(cliente);
      if (id != 0) {
        _clientes.add(Cliente(id: id, nombre: nombre.trim()));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al agregar cliente: $e');
      return false;
    }
  }

  // Buscar cliente por nombre
  List<Cliente> buscarClientesPorNombre(String query) {
    if (query.trim().isEmpty) {
      return _clientes;
    }

    return _clientes
        .where(
          (cliente) =>
              cliente.nombre.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  Future<bool> actualizarCliente(Cliente cliente) async {
    try {
      // Validar que el cliente exista
      final clienteExistente = await obtenerCliente(cliente.id!);
      if (clienteExistente == null) {
        debugPrint('No se encontró el cliente a actualizar');
        return false;
      }

      // Validar que el nombre no esté vacío
      if (cliente.nombre.trim().isEmpty) {
        debugPrint('El nombre del cliente no puede estar vacío');
        return false;
      }

      // Actualizar el cliente
      final resultado = await _dbHelper.updateCliente(cliente);
      if (resultado != 0) {
        // Actualizar la lista local
        final index = _clientes.indexWhere((c) => c.id == cliente.id);
        if (index != -1) {
          _clientes[index] = cliente;
          notifyListeners();
        }
        debugPrint('Cliente actualizado correctamente');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al actualizar cliente: $e');
      return false;
    }
  }

  Future<bool> eliminarCliente(int id) async {
    try {
      // Verificar si el cliente tiene ventas asociadas
      final ventas = await _dbHelper.getVentasPorCliente(id);
      if (ventas.isNotEmpty) {
        debugPrint(
          'No se puede eliminar el cliente porque tiene ventas asociadas',
        );
        return false;
      }

      // Eliminar el cliente
      final resultado = await _dbHelper.deleteCliente(id);
      if (resultado != 0) {
        // Eliminar de la lista local
        _clientes.removeWhere((c) => c.id == id);
        notifyListeners();
        debugPrint('Cliente eliminado correctamente');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al eliminar cliente: $e');
      return false;
    }
  }

  Future<Cliente?> obtenerCliente(int id) async {
    try {
      return await _dbHelper.getCliente(id);
    } catch (e) {
      debugPrint('Error al obtener cliente: $e');
      return null;
    }
  }
}
