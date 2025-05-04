import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cliente_provider.dart';
import '../providers/venta_provider.dart';
import '../models/detalle_venta.dart';
import '../providers/cotizacion_provider.dart';

class NuevaVentaScreen extends StatefulWidget {
  const NuevaVentaScreen({super.key});

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  final _precioController = TextEditingController();
  final _cotizacionController = TextEditingController(text: '0.01095');
  final _busquedaClienteController = TextEditingController();

  String _monedaPrecio = 'BOB';
  double _precioEquivalente = 0.0;
  bool _mostrarBusquedaCliente = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final clienteProvider = context.read<ClienteProvider>();
      final cotizacionProvider = context.read<CotizacionProvider>();
      await clienteProvider.cargarClientes();
      if (!mounted) return;
      await cotizacionProvider.cargarUltimaCotizacion();
      if (!mounted) return;
      final cotizacion = cotizacionProvider.cotizacionActual;
      _cotizacionController.text = cotizacion.toString();
    });
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    _cotizacionController.dispose();
    _busquedaClienteController.dispose();
    super.dispose();
  }

  final _formatoNumero = NumberFormat.currency(
    locale: 'es_BO',
    symbol: '',
    decimalDigits: 2,
  );

  void _calcularPrecioEquivalente() {
    if (_precioController.text.isEmpty) {
      setState(() {
        _precioEquivalente = 0.0;
      });
      return;
    }

    double precio = double.tryParse(_precioController.text) ?? 0.0;
    double cotizacion = double.tryParse(_cotizacionController.text) ?? 0.01095;

    setState(() {
      if (_monedaPrecio == 'BOB') {
        _precioEquivalente = precio / cotizacion;
      } else {
        _precioEquivalente = precio * cotizacion;
      }
    });
  }

  void _agregarProducto() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final cantidad = int.parse(_cantidadController.text);
      final descripcion = _descripcionController.text.trim();
      double precioBob, precioArs;

      if (_monedaPrecio == 'BOB') {
        precioBob = double.parse(_precioController.text);
        precioArs = _precioEquivalente;
      } else {
        precioArs = double.parse(_precioController.text);
        precioBob = _precioEquivalente;
      }

      final detalle = DetalleVenta(
        descripcion: descripcion,
        cantidad: cantidad,
        precioUnitarioBob: precioBob,
        precioUnitarioArs: precioArs,
        subtotalBob: precioBob * cantidad,
        subtotalArs: precioArs * cantidad,
      );

      Provider.of<VentaProvider>(
        context,
        listen: false,
      ).agregarAlCarrito(detalle);

      // Limpiar el formulario después de agregar
      _descripcionController.clear();
      _cantidadController.text = '1';
      _precioController.clear();
      setState(() {
        _precioEquivalente = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto agregado al carrito'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _mostrarDialogoNuevoCliente(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sección de selección de cliente y cotización
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selección de cliente con búsqueda
                Consumer<VentaProvider>(
                  builder: (context, ventaProvider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _mostrarBusquedaCliente = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 12.0,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        ventaProvider.clienteSeleccionado !=
                                                null
                                            ? ventaProvider
                                                .clienteSeleccionado!.nombre
                                            : 'Seleccionar Cliente',
                                        style: TextStyle(
                                          color: ventaProvider
                                                      .clienteSeleccionado !=
                                                  null
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_mostrarBusquedaCliente)
                          Container(
                            margin: const EdgeInsets.only(top: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(
                                      red: 128,
                                      green: 128,
                                      blue: 128,
                                      alpha: 0.3),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextField(
                                    controller: _busquedaClienteController,
                                    decoration: const InputDecoration(
                                      hintText: 'Buscar cliente...',
                                      prefixIcon: Icon(Icons.search),
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                  ),
                                ),
                                Container(
                                  constraints:
                                      const BoxConstraints(maxHeight: 200),
                                  child: Consumer<ClienteProvider>(
                                    builder: (context, clienteProvider, child) {
                                      final clientes = clienteProvider.clientes
                                          .where((c) => c.nombre
                                              .toLowerCase()
                                              .contains(
                                                  _busquedaClienteController
                                                      .text
                                                      .toLowerCase()))
                                          .toList();

                                      return ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: clientes.length,
                                        itemBuilder: (context, index) {
                                          final cliente = clientes[index];
                                          return ListTile(
                                            title: Text(cliente.nombre),
                                            onTap: () {
                                              context
                                                  .read<VentaProvider>()
                                                  .setCliente(cliente);
                                              setState(() {
                                                _mostrarBusquedaCliente = false;
                                                _busquedaClienteController
                                                    .clear();
                                              });
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12.0),

                // Cotización
                Row(
                  children: [
                    const Text('Cotización:'),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: TextFormField(
                        controller: _cotizacionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 8.0,
                          ),
                          border: OutlineInputBorder(),
                          hintText: '0.01095',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            double cotizacion =
                                double.tryParse(value) ?? 0.01095;
                            context
                                .read<CotizacionProvider>()
                                .guardarCotizacion(cotizacion);
                            _calcularPrecioEquivalente();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    const Text('BOB por 1 ARS'),
                  ],
                ),
              ],
            ),
          ),

          // Formulario para agregar productos
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Descripción del producto
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese una descripción';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12.0),

                    // Cantidad y Precio en una fila
                    Row(
                      children: [
                        // Cantidad
                        Expanded(
                          child: TextFormField(
                            controller: _cantidadController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad',
                              border: OutlineInputBorder(),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese una cantidad';
                              }
                              final cantidad = int.tryParse(value);
                              if (cantidad == null || cantidad <= 0) {
                                return 'Cantidad inválida';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        // Precio
                        Expanded(
                          child: TextFormField(
                            controller: _precioController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Precio',
                              border: const OutlineInputBorder(),
                              suffixText: _monedaPrecio,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*$'),
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese un precio';
                              }
                              final precio = double.tryParse(value);
                              if (precio == null || precio <= 0) {
                                return 'Precio inválido';
                              }
                              return null;
                            },
                            onChanged: (_) => _calcularPrecioEquivalente(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),

                    // Selector de moneda
                    DropdownButtonFormField<String>(
                      value: _monedaPrecio,
                      decoration: const InputDecoration(
                        labelText: 'Moneda',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'BOB',
                          child: Text('BOB'),
                        ),
                        DropdownMenuItem(
                          value: 'ARS',
                          child: Text('ARS'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _monedaPrecio = value;
                            _calcularPrecioEquivalente();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8.0),

                    // Precio equivalente
                    if (_precioEquivalente > 0)
                      Text(
                        'Equivalente: ${_formatoNumero.format(_precioEquivalente)} ${_monedaPrecio == 'BOB' ? 'ARS' : 'BOB'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 16.0),

                    // Botón para agregar producto
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _agregarProducto,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Agregar Producto'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24.0),
                    const Divider(),
                    const SizedBox(height: 8.0),

                    // Productos en el carrito
                    const Text(
                      'Productos en el Carrito',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),

                    Consumer<VentaProvider>(
                      builder: (ctx, ventaProvider, child) {
                        if (ventaProvider.carrito.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Text(
                                'No hay productos en el carrito',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          );
                        }

                        return Container(
                          constraints: const BoxConstraints(
                            maxHeight: 400.0,
                          ),
                          child: SingleChildScrollView(
                            child: _buildCarrito(),
                          ),
                        );
                      },
                    ),

                    // Totales
                    Consumer<VentaProvider>(
                      builder: (ctx, ventaProvider, child) {
                        if (ventaProvider.carrito.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          children: [
                            const SizedBox(height: 16.0),
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'TOTAL:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${_formatoNumero.format(ventaProvider.totalBob)} BOB',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18.0,
                                            ),
                                          ),
                                          Text(
                                            '${_formatoNumero.format(ventaProvider.totalArs)} ARS',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Consumer<VentaProvider>(
        builder: (ctx, ventaProvider, child) {
          if (ventaProvider.carrito.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey
                      .withValues(red: 128, green: 128, blue: 128, alpha: 0.3),
                  blurRadius: 6.0,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _finalizarVenta,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: const Text(
                'FINALIZAR VENTA',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarrito() {
    return Consumer<VentaProvider>(
      builder: (context, ventaProvider, child) {
        final carrito = ventaProvider.carrito;
        if (carrito.isEmpty) {
          return const Center(child: Text('No hay productos en el carrito'));
        }

        return Column(
          children: carrito.map((item) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: Text(item.descripcion),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cantidad: ${item.cantidad}'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue:
                                item.precioUnitarioBob.toStringAsFixed(2),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 8.0,
                              ),
                              border: OutlineInputBorder(),
                              labelText: 'Precio BOB',
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                final nuevoPrecioBob = double.tryParse(value) ??
                                    item.precioUnitarioBob;
                                final nuevoPrecioArs =
                                    ventaProvider.calcularPrecioEquivalente(
                                  nuevoPrecioBob,
                                  'BOB',
                                );
                                ventaProvider.actualizarPrecioEnCarrito(
                                  carrito.indexOf(item),
                                  nuevoPrecioBob,
                                  nuevoPrecioArs,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue:
                                item.precioUnitarioArs.toStringAsFixed(2),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 8.0,
                              ),
                              border: OutlineInputBorder(),
                              labelText: 'Precio ARS',
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                final nuevoPrecioArs = double.tryParse(value) ??
                                    item.precioUnitarioArs;
                                final nuevoPrecioBob =
                                    ventaProvider.calcularPrecioEquivalente(
                                  nuevoPrecioArs,
                                  'ARS',
                                );
                                ventaProvider.actualizarPrecioEnCarrito(
                                  carrito.indexOf(item),
                                  nuevoPrecioBob,
                                  nuevoPrecioArs,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Subtotal: ${item.subtotalBob.toStringAsFixed(2)} BOB / ${item.subtotalArs.toStringAsFixed(2)} ARS',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => ventaProvider.eliminarDelCarrito(
                    carrito.indexOf(item),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _mostrarDialogoNuevoCliente() {
    final nombreController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Cliente', style: TextStyle(fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final nombre = nombreController.text.trim();
              if (nombre.isNotEmpty) {
                final clienteProvider = context.read<ClienteProvider>();
                final success = await clienteProvider.agregarCliente(nombre);
                if (success && mounted) {
                  final clientes = clienteProvider.clientes;
                  final nuevoCliente = clientes.lastWhere(
                    (c) => c.nombre == nombre,
                  );
                  context.read<VentaProvider>().setCliente(nuevoCliente);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cliente agregado y seleccionado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _finalizarVenta() async {
    final ventaProvider = context.read<VentaProvider>();

    if (ventaProvider.clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un cliente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (ventaProvider.carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agregue al menos un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cliente: ${ventaProvider.clienteSeleccionado!.nombre}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Total BOB: ${_formatoNumero.format(ventaProvider.totalBob)}',
            ),
            Text(
              'Total ARS: ${_formatoNumero.format(ventaProvider.totalArs)}',
            ),
            const SizedBox(height: 8),
            const Text('¿Desea finalizar la venta?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ventaProvider.guardarVenta();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Venta registrada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
                ventaProvider.setCliente(null);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
