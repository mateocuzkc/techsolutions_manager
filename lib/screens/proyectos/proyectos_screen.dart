import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tareas/tareas_screen.dart';

final supabase = Supabase.instance.client;

class ProyectosScreen extends StatefulWidget {
  const ProyectosScreen({super.key});

  @override
  State<ProyectosScreen> createState() => _ProyectosScreenState();
}

class _ProyectosScreenState extends State<ProyectosScreen> {
  static const Color _bgTop = Color(0xFF09101D);
  static const Color _bgBottom = Color(0xFF181A33);
  static const Color _card = Color(0xCC121A2B);
  static const Color _cardBorder = Color(0xFF2A3450);
  static const Color _inputFill = Color(0xFF111A2A);
  static const Color _textPrimary = Color(0xFFF4F7FF);
  static const Color _textSecondary = Color(0xFFAFBCDE);
  static const Color _accent = Color(0xFF6688FF);
  static const Color _accentAlt = Color(0xFF8B5CF6);

  static const List<String> estadosDisponibles = [
    'Pendiente',
    'En Proceso',
    'Finalizado',
    'Cancelado',
  ];

  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final DateFormat storageDateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat displayDateFormat = DateFormat('dd/MM/yyyy');

  List<Map<String, dynamic>> proyectos = [];
  List<Map<String, dynamic>> clientes = [];

  bool isLoading = false;
  int? proyectoEditandoId;
  int? clienteSeleccionadoId;
  DateTime? fechaInicioSeleccionada;
  DateTime? fechaFinSeleccionada;
  String estadoSeleccionado = estadosDisponibles.first;
  String rol = 'usuario';
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = supabase.auth.currentUser?.id;
    cargarDatosIniciales();
  }

  Future<void> cargarDatosIniciales() async {
    setState(() => isLoading = true);

    try {
      await cargarRol();
      await Future.wait([
        obtenerClientes(),
        obtenerProyectos(),
      ]);
    } catch (e) {
      mostrarMensaje('Error al cargar proyectos: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> cargarRol() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    currentUserId = user.id;

    final response = await supabase
        .from('profiles')
        .select('rol')
        .eq('id', user.id)
        .single();

    rol = (response['rol'] ?? 'usuario').toString();
  }

  Future<void> obtenerClientes() async {
    var query = supabase.from('clientes').select('id, nombre');

    if (rol != 'admin' && currentUserId != null) {
      query = query.eq('user_id', currentUserId!);
    }

    final response = await query.order('nombre', ascending: true);

    clientes = List<Map<String, dynamic>>.from(response);
  }

  Future<void> obtenerProyectos() async {
    var query = supabase.from('proyectos').select(
      'id, cliente_id, nombre, descripcion, fecha_inicio, fecha_fin, estado, created_at, clientes(nombre)',
    );

    if (rol != 'admin' && currentUserId != null) {
      query = query.eq('user_id', currentUserId!);
    }

    final response = await query.order('id', ascending: true);

    proyectos = List<Map<String, dynamic>>.from(response);
  }

  Future<void> refrescarDatos() async {
    setState(() => isLoading = true);

    try {
      await Future.wait([
        obtenerClientes(),
        obtenerProyectos(),
      ]);
    } catch (e) {
      mostrarMensaje('Error al actualizar proyectos: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> agregarProyecto() async {
    final mensajeValidacion = validarFormulario();
    if (mensajeValidacion != null) {
      mostrarMensaje(mensajeValidacion);
      return;
    }

    try {
      await supabase.from('proyectos').insert({
        'user_id': supabase.auth.currentUser!.id,
        'cliente_id': clienteSeleccionadoId,
        'nombre': nombreController.text.trim(),
        'descripcion': descripcionController.text.trim(),
        'fecha_inicio': storageDateFormat.format(fechaInicioSeleccionada!),
        'fecha_fin': storageDateFormat.format(fechaFinSeleccionada!),
        'estado': estadoSeleccionado,
      });

      limpiarCampos();
      await refrescarDatos();
      mostrarMensaje('Proyecto agregado correctamente');
    } catch (e) {
      mostrarMensaje('Error al agregar proyecto: $e');
    }
  }

  Future<void> actualizarProyecto() async {
    if (proyectoEditandoId == null) return;

    final mensajeValidacion = validarFormulario();
    if (mensajeValidacion != null) {
      mostrarMensaje(mensajeValidacion);
      return;
    }

    try {
      await supabase.from('proyectos').update({
        'cliente_id': clienteSeleccionadoId,
        'nombre': nombreController.text.trim(),
        'descripcion': descripcionController.text.trim(),
        'fecha_inicio': storageDateFormat.format(fechaInicioSeleccionada!),
        'fecha_fin': storageDateFormat.format(fechaFinSeleccionada!),
        'estado': estadoSeleccionado,
      }).eq('id', proyectoEditandoId!);

      limpiarCampos();
      await refrescarDatos();
      mostrarMensaje('Proyecto actualizado correctamente');
    } catch (e) {
      mostrarMensaje('Error al actualizar proyecto: $e');
    }
  }

  Future<void> eliminarProyecto(int id) async {
    try {
      await supabase.from('proyectos').delete().eq('id', id);
      await refrescarDatos();
      mostrarMensaje('Proyecto eliminado correctamente');
    } catch (e) {
      mostrarMensaje('Error al eliminar proyecto: $e');
    }
  }

  String? validarFormulario() {
    if (clienteSeleccionadoId == null) {
      return 'Debes seleccionar un cliente';
    }

    if (nombreController.text.trim().isEmpty) {
      return 'El nombre del proyecto es obligatorio';
    }

    if (descripcionController.text.trim().isEmpty) {
      return 'La descripción del proyecto es obligatoria';
    }

    if (fechaInicioSeleccionada == null) {
      return 'Debes seleccionar la fecha de inicio';
    }

    if (fechaFinSeleccionada == null) {
      return 'Debes seleccionar la fecha de fin';
    }

    if (fechaFinSeleccionada!.isBefore(fechaInicioSeleccionada!)) {
      return 'La fecha de fin no puede ser anterior a la fecha de inicio';
    }

    if (estadoSeleccionado.trim().isEmpty) {
      return 'El estado del proyecto es obligatorio';
    }

    return null;
  }

  void limpiarCampos() {
    nombreController.clear();
    descripcionController.clear();
    proyectoEditandoId = null;
    clienteSeleccionadoId = null;
    fechaInicioSeleccionada = null;
    fechaFinSeleccionada = null;
    estadoSeleccionado = estadosDisponibles.first;
  }

  void cargarDatosProyecto(Map<String, dynamic> proyecto) {
    proyectoEditandoId = proyecto['id'] as int?;
    clienteSeleccionadoId = proyecto['cliente_id'] as int?;
    nombreController.text = (proyecto['nombre'] ?? '').toString();
    descripcionController.text = (proyecto['descripcion'] ?? '').toString();
    estadoSeleccionado =
        (proyecto['estado'] ?? estadosDisponibles.first).toString();
    fechaInicioSeleccionada = parsearFecha(proyecto['fecha_inicio']);
    fechaFinSeleccionada = parsearFecha(proyecto['fecha_fin']);
  }

  DateTime? parsearFecha(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }

  String formatearFecha(dynamic valor) {
    final fecha = parsearFecha(valor);
    if (fecha == null) return 'Sin fecha';
    return displayDateFormat.format(fecha);
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textSecondary),
      filled: true,
      fillColor: _inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
    );
  }

  Future<void> seleccionarFecha({
    required bool esFechaInicio,
    required void Function(void Function()) setDialogState,
  }) async {
    final fechaActual =
        esFechaInicio ? fechaInicioSeleccionada : fechaFinSeleccionada;
    final ahora = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaActual ?? ahora,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accent,
              surface: Color(0xFF131C2F),
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha == null) return;

    setState(() {
      if (esFechaInicio) {
        fechaInicioSeleccionada = fecha;
      } else {
        fechaFinSeleccionada = fecha;
      }
    });

    setDialogState(() {});
  }

  void mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF161F33),
        content: Text(mensaje),
      ),
    );
  }

  Color colorEstado(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.orangeAccent;
      case 'En Proceso':
        return Colors.lightBlueAccent;
      case 'Finalizado':
        return Colors.greenAccent;
      case 'Cancelado':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Widget estadoVisual(String estado) {
    final color = colorEstado(estado);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          estado,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String obtenerNombreCliente(Map<String, dynamic> proyecto) {
    final cliente = proyecto['clientes'];

    if (cliente is Map<String, dynamic>) {
      return (cliente['nombre'] ?? 'Sin cliente').toString();
    }

    if (cliente is List && cliente.isNotEmpty) {
      final primerCliente = cliente.first;
      if (primerCliente is Map<String, dynamic>) {
        return (primerCliente['nombre'] ?? 'Sin cliente').toString();
      }
    }

    return 'Sin cliente';
  }

  Widget buildFormularioProyecto(
    void Function(void Function()) setDialogState,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: clienteSeleccionadoId,
            dropdownColor: _inputFill,
            style: const TextStyle(color: _textPrimary),
            decoration: _inputDecoration('Cliente'),
            items: clientes
                .map(
                  (cliente) => DropdownMenuItem<int>(
                    value: cliente['id'] as int,
                    child: Text(
                      (cliente['nombre'] ?? '').toString(),
                      style: const TextStyle(color: _textPrimary),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                clienteSeleccionadoId = value;
              });
              setDialogState(() {});
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nombreController,
            style: const TextStyle(color: _textPrimary),
            decoration: _inputDecoration('Nombre del proyecto'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descripcionController,
            style: const TextStyle(color: _textPrimary),
            maxLines: 3,
            decoration: _inputDecoration('Descripción').copyWith(
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => seleccionarFecha(
              esFechaInicio: true,
              setDialogState: setDialogState,
            ),
            child: InputDecorator(
              decoration: _inputDecoration('Fecha de inicio').copyWith(
                suffixIcon: const Icon(Icons.calendar_today, color: _textSecondary),
              ),
              child: Text(
                fechaInicioSeleccionada == null
                    ? 'Seleccionar fecha'
                    : displayDateFormat.format(fechaInicioSeleccionada!),
                style: const TextStyle(color: _textPrimary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => seleccionarFecha(
              esFechaInicio: false,
              setDialogState: setDialogState,
            ),
            child: InputDecorator(
              decoration: _inputDecoration('Fecha de fin').copyWith(
                suffixIcon: const Icon(Icons.calendar_today, color: _textSecondary),
              ),
              child: Text(
                fechaFinSeleccionada == null
                    ? 'Seleccionar fecha'
                    : displayDateFormat.format(fechaFinSeleccionada!),
                style: const TextStyle(color: _textPrimary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: estadoSeleccionado,
            dropdownColor: _inputFill,
            style: const TextStyle(color: _textPrimary),
            decoration: _inputDecoration('Estado'),
            items: estadosDisponibles
                .map(
                  (estado) => DropdownMenuItem<String>(
                    value: estado,
                    child: Text(
                      estado,
                      style: const TextStyle(color: _textPrimary),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                estadoSeleccionado = value;
              });
              setDialogState(() {});
            },
          ),
        ],
      ),
    );
  }

  AlertDialog _buildDialog({
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: const Color(0xFF131C2F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        title,
        style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w700),
      ),
      content: content,
      actions: actions,
    );
  }

  Widget _dialogAction({
    required String label,
    required VoidCallback onPressed,
    bool filled = false,
  }) {
    if (!filled) {
      return TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(color: _textSecondary),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [_accent, _accentAlt]),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: _textPrimary,
          shadowColor: Colors.transparent,
        ),
        child: Text(label),
      ),
    );
  }

  Future<void> mostrarDialogoAgregarProyecto() async {
    limpiarCampos();

    await showDialog(
      context: context,
      builder: (context) {
        return _buildDialog(
          title: 'Agregar proyecto',
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return buildFormularioProyecto(setDialogState);
            },
          ),
          actions: [
            _dialogAction(
              label: 'Cancelar',
              onPressed: () => Navigator.pop(context),
            ),
            _dialogAction(
              label: 'Guardar',
              filled: true,
              onPressed: () async {
                Navigator.pop(context);
                await agregarProyecto();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> mostrarDialogoEditarProyecto(
    Map<String, dynamic> proyecto,
  ) async {
    setState(() {
      cargarDatosProyecto(proyecto);
    });

    await showDialog(
      context: context,
      builder: (context) {
        return _buildDialog(
          title: 'Editar proyecto',
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return buildFormularioProyecto(setDialogState);
            },
          ),
          actions: [
            _dialogAction(
              label: 'Cancelar',
              onPressed: () => Navigator.pop(context),
            ),
            _dialogAction(
              label: 'Actualizar',
              filled: true,
              onPressed: () async {
                Navigator.pop(context);
                await actualizarProyecto();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> confirmarEliminacion(int id, String nombre) async {
    await showDialog(
      context: context,
      builder: (context) {
        return _buildDialog(
          title: 'Eliminar proyecto',
          content: Text(
            '¿Deseas eliminar el proyecto $nombre?',
            style: const TextStyle(color: _textPrimary),
          ),
          actions: [
            _dialogAction(
              label: 'Cancelar',
              onPressed: () => Navigator.pop(context),
            ),
            _dialogAction(
              label: 'Eliminar',
              filled: true,
              onPressed: () async {
                Navigator.pop(context);
                await eliminarProyecto(id);
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildListaProyectos() {
    if (proyectos.isEmpty) {
      return const Center(
        child: Text(
          'No hay proyectos registrados',
          style: TextStyle(fontSize: 18, color: _textPrimary),
        ),
      );
    }

    return ListView.builder(
      itemCount: proyectos.length,
      itemBuilder: (context, index) {
        final proyecto = proyectos[index];
        final estado =
            (proyecto['estado'] ?? estadosDisponibles.first).toString();
        final nombreCliente = obtenerNombreCliente(proyecto);

        return Card(
          color: _card,
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: const BorderSide(color: _cardBorder),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [_accent, _accentAlt]),
              ),
              child: Center(
                child: Text(
                  '${proyecto['id']}',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            title: Text(
              (proyecto['nombre'] ?? '').toString(),
              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Código: ${proyecto['id']}',
                    style: const TextStyle(color: _textSecondary),
                  ),
                  Text(
                    'Cliente: $nombreCliente',
                    style: const TextStyle(color: _textSecondary),
                  ),
                  Text(
                    'Inicio: ${formatearFecha(proyecto['fecha_inicio'])}',
                    style: const TextStyle(color: _textSecondary),
                  ),
                  Text(
                    'Fin: ${formatearFecha(proyecto['fecha_fin'])}',
                    style: const TextStyle(color: _textSecondary),
                  ),
                  if ((proyecto['descripcion'] ?? '').toString().trim().isNotEmpty)
                    Text(
                      'Descripción: ${proyecto['descripcion']}',
                      style: const TextStyle(color: _textSecondary),
                    ),
                  const SizedBox(height: 8),
                  estadoVisual(estado),
                ],
              ),
            ),
            trailing: Wrap(
              spacing: 6,
              children: [
                IconButton(
                  tooltip: 'Ver tareas',
                  icon: const Icon(Icons.task, color: Color(0xFFA78BFA)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TareasScreen(
                          proyectoId: proyecto['id'] as int,
                          proyectoNombre: (proyecto['nombre'] ?? '').toString(),
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit, color: _accent),
                  onPressed: () => mostrarDialogoEditarProyecto(proyecto),
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => confirmarEliminacion(
                    proyecto['id'] as int,
                    (proyecto['nombre'] ?? '').toString(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTop,
      appBar: AppBar(
        title: const Text('Proyectos'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _textPrimary,
        actions: [
          IconButton(
            onPressed: refrescarDatos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_accent, _accentAlt]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x664837A8),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: mostrarDialogoAgregarProyecto,
          child: const Icon(Icons.add, color: _textPrimary),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgTop, _bgBottom, Color(0xFF21113E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : buildListaProyectos(),
        ),
      ),
    );
  }
}
