import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cliente_provider.dart';
import '../models/cliente.dart';

class ClienteScreen extends StatefulWidget {
  const ClienteScreen({super.key});

  @override
  State<ClienteScreen> createState() => _ClienteScreenState();
}

class _ClienteScreenState extends State<ClienteScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Asegurar que los clientes estén cargados
    _cargarClientes();
  }

  // Método seguro para cargar clientes
  void _cargarClientes() {
    Future.microtask(() {
      if (mounted) {
        context.read<ClienteProvider>().cargarClientes();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  void _showAddClienteDialog() {
    _nombreController.clear();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Nuevo Cliente'),
            content: TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              onSubmitted: (_) => _agregarCliente(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _agregarCliente,
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _agregarCliente() async {
    if (_nombreController.text.trim().isNotEmpty) {
      await context.read<ClienteProvider>().agregarCliente(
        _nombreController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente agregado correctamente')),
        );
      }
    }
  }

  void _mostrarDialogoEditarCliente(Cliente cliente) {
    _nombreController.text = cliente.nombre;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Editar Cliente'),
            content: TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_nombreController.text.trim().isNotEmpty) {
                    final clienteActualizado = Cliente(
                      id: cliente.id,
                      nombre: _nombreController.text.trim(),
                    );

                    final resultado = await context
                        .read<ClienteProvider>()
                        .actualizarCliente(clienteActualizado);

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            resultado
                                ? 'Cliente actualizado correctamente'
                                : 'No se pudo actualizar el cliente',
                          ),
                          backgroundColor:
                              resultado ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _mostrarDialogoEliminarCliente(Cliente cliente) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar Cliente'),
            content: Text(
              '¿Está seguro que desea eliminar al cliente "${cliente.nombre}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final resultado = await context
                      .read<ClienteProvider>()
                      .eliminarCliente(cliente.id!);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          resultado
                              ? 'Cliente eliminado correctamente'
                              : 'No se puede eliminar el cliente porque tiene ventas asociadas',
                        ),
                        backgroundColor: resultado ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clientes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar cliente',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Lista de clientes
          Expanded(
            child: Consumer<ClienteProvider>(
              builder: (ctx, clienteProvider, child) {
                if (clienteProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final clientes =
                    _searchQuery.isEmpty
                        ? clienteProvider.clientes
                        : clienteProvider.buscarClientesPorNombre(_searchQuery);

                if (clientes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 70,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No hay clientes registrados'
                              : 'No se encontraron clientes',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: clientes.length,
                  itemBuilder: (ctx, index) {
                    final cliente = clientes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            cliente.nombre.isNotEmpty
                                ? cliente.nombre[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          cliente.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed:
                                  () => _mostrarDialogoEditarCliente(cliente),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed:
                                  () => _mostrarDialogoEliminarCliente(cliente),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Navegar a detalles del cliente o seleccionarlo
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClienteDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
