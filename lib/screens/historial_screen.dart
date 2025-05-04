import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/venta_provider.dart';
import '../models/detalle_venta_con_cliente.dart';
import 'package:intl/intl.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  List<DetalleVentaConCliente> _detalles = [];
  bool _isLoading = false;
  String _filtroCliente = 'Todos';
  List<String> _clientes = ['Todos'];

  @override
  void initState() {
    super.initState();
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final fecha = _fechaSeleccionada.toString().split(' ')[0];
      final detalles = await Provider.of<VentaProvider>(
        context,
        listen: false,
      ).getDetallesConClienteByFecha(fecha);

      // Obtener lista única de clientes
      final clientesUnicos =
          detalles.map((d) => d.clienteNombre).toSet().toList();
      clientesUnicos.sort();
      setState(() {
        _detalles = detalles;
        _clientes = ['Todos', ...clientesUnicos];
      });
    } catch (e) {
      debugPrint('Error al cargar detalles: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
        _filtroCliente = 'Todos';
      });
      _cargarDetalles();
    }
  }

  List<DetalleVentaConCliente> _getDetallesFiltrados() {
    if (_filtroCliente == 'Todos') {
      return _detalles;
    }
    return _detalles.where((d) => d.clienteNombre == _filtroCliente).toList();
  }

  Map<String, List<DetalleVentaConCliente>> _agruparPorCliente(
      List<DetalleVentaConCliente> detalles) {
    final grupos = <String, List<DetalleVentaConCliente>>{};
    for (var detalle in detalles) {
      if (!grupos.containsKey(detalle.clienteNombre)) {
        grupos[detalle.clienteNombre] = [];
      }
      grupos[detalle.clienteNombre]!.add(detalle);
    }
    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final detallesFiltrados = _getDetallesFiltrados();
    final gruposPorCliente = _agruparPorCliente(detallesFiltrados);
    final formatter = NumberFormat.currency(
      locale: 'es_BO',
      symbol: '',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial de Ventas',
          style: TextStyle(fontSize: 20),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _seleccionarFecha(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Fecha seleccionada y filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ventas del ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _seleccionarFecha(context),
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Cambiar fecha'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _filtroCliente,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por Cliente',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _clientes.map((cliente) {
                    return DropdownMenuItem(
                      value: cliente,
                      child: Text(cliente),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _filtroCliente = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          // Lista de ventas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : detallesFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay ventas registradas\npara el ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: gruposPorCliente.length + 1,
                        itemBuilder: (context, index) {
                          if (index == gruposPorCliente.length) {
                            double totalBob = 0;
                            double totalArs = 0;
                            for (var detalle in detallesFiltrados) {
                              totalBob += detalle.subtotalBob;
                              totalArs += detalle.subtotalArs;
                            }

                            return Card(
                              margin: const EdgeInsets.all(8),
                              color: Colors.blue.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Resumen del Día',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total de Ventas:',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          detallesFiltrados.length.toString(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total BOB:',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          formatter.format(totalBob),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total ARS:',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          formatter.format(totalArs),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final cliente =
                              gruposPorCliente.keys.elementAt(index);
                          final ventasCliente = gruposPorCliente[cliente]!;
                          double totalClienteBob = 0;
                          double totalClienteArs = 0;
                          for (var venta in ventasCliente) {
                            totalClienteBob += venta.subtotalBob;
                            totalClienteArs += venta.subtotalArs;
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Encabezado del cliente
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  color: Colors.blue.shade100,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          cliente,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${ventasCliente.length} venta${ventasCliente.length > 1 ? 's' : ''}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Lista de ventas del cliente
                                ...ventasCliente.map((detalle) {
                                  return Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                detalle.descripcion,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${detalle.cantidad} unid.',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${formatter.format(detalle.precioUnitarioBob)} BOB',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                              ),
                                            ),
                                            Text(
                                              '${formatter.format(detalle.subtotalBob)} BOB',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                // Total del cliente
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    border: Border(
                                      top: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total Cliente:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${formatter.format(totalClienteBob)} BOB',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          Text(
                                            '${formatter.format(totalClienteArs)} ARS',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
