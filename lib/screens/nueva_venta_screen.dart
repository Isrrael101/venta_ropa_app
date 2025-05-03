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

  static const _totalBoxDecoration = BoxDecoration(
    color: Color(0xFFE3F2FD), // Colors.blue.shade50
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
    border: Border(
      left: BorderSide(color: Color(0xFF90CAF9)), // Colors.blue.shade200
      top: BorderSide(color: Color(0xFF90CAF9)),
      right: BorderSide(color: Color(0xFF90CAF9)),
      bottom: BorderSide(color: Color(0xFF90CAF9)),
    ),
  );

  static const _bottomBarDecoration = BoxDecoration(
    color: Colors.white,
    boxShadow: [
      BoxShadow(
        color: Color.fromRGBO(128, 128, 128, 0.3),
        blurRadius: 6.0,
        offset: Offset(0, -3),
      ),
    ],
  );

  static const _clienteSelectorDecoration = BoxDecoration(
    border: Border(
      left: BorderSide(color: Colors.grey),
      top: BorderSide(color: Colors.grey),
      right: BorderSide(color: Colors.grey),
      bottom: BorderSide(color: Colors.grey),
    ),
    borderRadius: BorderRadius.all(Radius.circular(4.0)),
  );

  String _monedaPrecio = 'BOB'; // Moneda en que se ingresa el precio
  double _precioEquivalente = 0.0;

  @override
  void initState() {
    super.initState();
    // Cargar clientes y última cotización
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
    super.dispose();
  }

  // Formatear números con 2 decimales
  final _formatoNumero = NumberFormat.currency(
    locale: 'es_BO',
    symbol: '',
    decimalDigits: 2,
  );

  // Calcular el precio equivalente
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
        // Convertir de BOB a ARS
        _precioEquivalente = precio / cotizacion;
      } else {
        // Convertir de ARS a BOB
        _precioEquivalente = precio * cotizacion;
      }
    });
  }

  // Mostrar diálogo para seleccionar cliente
  void _mostrarDialogoSeleccionCliente() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Seleccionar Cliente',
          style: TextStyle(fontSize: 20),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              // Barra de búsqueda
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar cliente',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // Implementar búsqueda si es necesario
                },
              ),
              const SizedBox(height: 16),
              // Lista de clientes
              Expanded(
                child: Consumer<ClienteProvider>(
                  builder: (ctx, clienteProvider, child) {
                    final clientes = clienteProvider.clientes;

                    if (clientes.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay clientes registrados',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: clientes.length,
                      itemBuilder: (ctx, index) {
                        final cliente = clientes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                cliente.nombre.isNotEmpty
                                    ? cliente.nombre[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              cliente.nombre,
                              style: const TextStyle(fontSize: 16),
                            ),
                            onTap: () {
                              context.read<VentaProvider>().setCliente(
                                    cliente,
                                  );
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _mostrarDialogoNuevoCliente();
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Nuevo Cliente'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  // Mostrar diálogo para agregar nuevo cliente
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
            onPressed: () {
              Navigator.pop(context);
              _mostrarDialogoSeleccionCliente();
            },
            child: const Text('Volver'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final nombre = nombreController.text.trim();
              if (nombre.isNotEmpty) {
                final clienteProvider = context.read<ClienteProvider>();
                final success = await clienteProvider.agregarCliente(
                  nombre,
                );
                if (success && mounted) {
                  // Get the newly created client
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

  // Agregar producto al carrito
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

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto agregado al carrito'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // Finalizar la venta
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

    // Confirmar la venta
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

              // Guardar la venta
              final success = await ventaProvider.guardarVenta();

              if (success && mounted) {
                // Mostrar mensaje de éxito
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Venta registrada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Limpiar selección de cliente
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
            onPressed: _mostrarDialogoSeleccionCliente,
          ),
        ],
      ),
      body: Consumer<VentaProvider>(
        builder: (ctx, ventaProvider, child) {
          return Column(
            children: [
              // Sección de selección de cliente y cotización
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.blue.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selección de cliente
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _mostrarDialogoSeleccionCliente,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 12.0,
                              ),
                              decoration: _clienteSelectorDecoration,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    ventaProvider.clienteSeleccionado != null
                                        ? ventaProvider
                                            .clienteSeleccionado!.nombre
                                        : 'Seleccionar Cliente',
                                    style: TextStyle(
                                      color:
                                          ventaProvider.clienteSeleccionado !=
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
                        // Título
                        const Text(
                          'Agregar Producto',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16.0),

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

                        // Cantidad
                        TextFormField(
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
                        const SizedBox(height: 12.0),

                        // Precio unitario
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Campo de precio
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _precioController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Precio Unitario',
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
                            const SizedBox(width: 8.0),

                            // Selector de moneda
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
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
                            ),
                          ],
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

                        if (ventaProvider.carrito.isEmpty)
                          const Padding(
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
                          )
                        else
                          Container(
                            constraints: const BoxConstraints(
                              maxHeight: 400.0,
                            ),
                            child: SingleChildScrollView(
                              child: _buildCarrito(),
                            ),
                          ),

                        // Totales
                        if (ventaProvider.carrito.isNotEmpty) ...[
                          const SizedBox(height: 16.0),
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: _totalBoxDecoration,
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
            decoration: _bottomBarDecoration,
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
                subtitle: Text(
                  'Cantidad: ${item.cantidad}\n'
                  'Precio: ${item.precioUnitarioBob.toStringAsFixed(2)} BOB\n'
                  'Subtotal: ${item.subtotalBob.toStringAsFixed(2)} BOB',
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
}
