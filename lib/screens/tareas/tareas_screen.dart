import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class TareasScreen extends StatefulWidget {
  const TareasScreen({
    super.key,
    this.proyectoId,
    this.proyectoNombre,
  });

  final int? proyectoId;
  final String? proyectoNombre;

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  static const Color _bgTop = Color(0xFF09101D);
  static const Color _bgBottom = Color(0xFF181A33);
  static const Color _card = Color(0xCC121A2B);
  static const Color _cardBorder = Color(0xFF2A3450);
  static const Color _inputFill = Color(0xFF111A2A);
  static const Color _textPrimary = Color(0xFFF4F7FF);
  static const Color _textSecondary = Color(0xFFAFBCDE);
  static const Color _accent = Color(0xFF6688FF);
  static const Color _accentAlt = Color(0xFF8B5CF6);

  static const List<String> prioridadesDisponibles = [
    'Baja',
    'Media',
    'Alta',
    'Urgente',
  ];

  static const List<String> estadosDisponibles = [
    'Pendiente',
    'En Proceso',
    'Finalizada',
    'Cancelada',
  ];

  final tituloController = TextEditingController();
  final descripcionController = TextEditingController();
  final responsableController = TextEditingController();

  List<Map<String, dynamic>> tareas = [];
  List<Map<String, dynamic>> proyectos = [];

  bool isLoading = false;
  int? tareaEditandoId;
  int? proyectoSeleccionadoId;
  String prioridadSeleccionada = prioridadesDisponibles[1];
  String estadoSeleccionado = estadosDisponibles.first;
  double avanceSeleccionado = 0;
  String rol = 'usuario';
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = supabase.auth.currentUser?.id;
    proyectoSeleccionadoId = widget.proyectoId;
    cargarDatosIniciales();
  }

  Future<void> cargarDatosIniciales() async {
    setState(() => isLoading = true);

    try {
      await cargarRol();
      await Future.wait([
        obtenerProyectos(),
        obtenerTareas(),
      ]);
    } catch (e) {
      mostrarMensaje('Error al cargar tareas: $e');
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

  Future<void> obtenerProyectos() async {
    var query = supabase.from('proyectos').select('id, nombre');

    if (rol != 'admin' && currentUserId != null) {
      query = query.eq('user_id', currentUserId!);
    }

    final response = await query.order('nombre', ascending: true);

    proyectos = List<Map<String, dynamic>>.from(response);
  }

  Future<void> obtenerTareas() async {
    dynamic query = supabase.from('tareas').select(
      'id, proyecto_id, responsable, titulo, descripcion, prioridad, estado, avance, created_at, proyectos(nombre)',
    );

    if (rol != 'admin' && currentUserId != null) {
      query = query.eq('user_id', currentUserId!);
    }

    if (widget.proyectoId != null) {
      query = query.eq('proyecto_id', widget.proyectoId!);
    }

    final response = await query.order('id', ascending: true);
    tareas = List<Map<String, dynamic>>.from(response);
  }

  Future<void> refrescarDatos() async {
    setState(() => isLoading = true);

    try {
      await Future.wait([
        obtenerProyectos(),
        obtenerTareas(),
      ]);
    } catch (e) {
      mostrarMensaje('Error al actualizar tareas: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String? validarFormulario() {
    if (proyectoSeleccionadoId == null) {
      return 'Debes seleccionar un proyecto';
    }

    if (tituloController.text.trim().isEmpty) {
      return 'El título es obligatorio';
    }

    if (descripcionController.text.trim().isEmpty) {
      return 'La descripción es obligatoria';
    }

    if (responsableController.text.trim().isEmpty) {
      return 'El responsable es obligatorio';
    }

    if (prioridadSeleccionada.trim().isEmpty) {
      return 'La prioridad es obligatoria';
    }

    if (estadoSeleccionado.trim().isEmpty) {
      return 'El estado es obligatorio';
    }

    if (avanceSeleccionado < 0 || avanceSeleccionado > 100) {
      return 'El avance debe estar entre 0 y 100';
    }

    return null;
  }

  Future<void> agregarTarea() async {
    final mensajeValidacion = validarFormulario();
    if (mensajeValidacion != null) {
      mostrarMensaje(mensajeValidacion);
      return;
    }

    try {
      await supabase.from('tareas').insert({
        'user_id': supabase.auth.currentUser!.id,
        'proyecto_id': proyectoSeleccionadoId,
        'responsable': responsableController.text.trim(),
        'titulo': tituloController.text.trim(),
        'descripcion': descripcionController.text.trim(),
        'prioridad': prioridadSeleccionada,
        'estado': estadoSeleccionado,
        'avance': avanceSeleccionado.round(),
      });

      limpiarCampos();
      await refrescarDatos();
      mostrarMensaje('Tarea agregada correctamente');
    } catch (e) {
      mostrarMensaje('Error al agregar tarea: $e');
    }
  }

  Future<void> actualizarTarea() async {
    if (tareaEditandoId == null) return;

    final mensajeValidacion = validarFormulario();
    if (mensajeValidacion != null) {
      mostrarMensaje(mensajeValidacion);
      return;
    }

    try {
      await supabase.from('tareas').update({
        'proyecto_id': proyectoSeleccionadoId,
        'responsable': responsableController.text.trim(),
        'titulo': tituloController.text.trim(),
        'descripcion': descripcionController.text.trim(),
        'prioridad': prioridadSeleccionada,
        'estado': estadoSeleccionado,
        'avance': avanceSeleccionado.round(),
      }).eq('id', tareaEditandoId!);

      limpiarCampos();
      await refrescarDatos();
      mostrarMensaje('Tarea actualizada correctamente');
    } catch (e) {
      mostrarMensaje('Error al actualizar tarea: $e');
    }
  }

  Future<void> eliminarTarea(int id) async {
    try {
      await supabase.from('tareas').delete().eq('id', id);
      await refrescarDatos();
      mostrarMensaje('Tarea eliminada correctamente');
    } catch (e) {
      mostrarMensaje('Error al eliminar tarea: $e');
    }
  }

  void limpiarCampos() {
    tituloController.clear();
    descripcionController.clear();
    responsableController.clear();
    tareaEditandoId = null;
    proyectoSeleccionadoId = widget.proyectoId;
    prioridadSeleccionada = prioridadesDisponibles[1];
    estadoSeleccionado = estadosDisponibles.first;
    avanceSeleccionado = 0;
  }

  void cargarDatosTarea(Map<String, dynamic> tarea) {
    tareaEditandoId = tarea['id'] as int?;
    proyectoSeleccionadoId = tarea['proyecto_id'] as int?;
    responsableController.text = (tarea['responsable'] ?? '').toString();
    tituloController.text = (tarea['titulo'] ?? '').toString();
    descripcionController.text = (tarea['descripcion'] ?? '').toString();
    prioridadSeleccionada =
        (tarea['prioridad'] ?? prioridadesDisponibles[1]).toString();
    estadoSeleccionado =
        (tarea['estado'] ?? estadosDisponibles.first).toString();
    avanceSeleccionado = ((tarea['avance'] ?? 0) as num).toDouble().clamp(
      0,
      100,
    );
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

  Color colorPrioridad(String prioridad) {
    switch (prioridad) {
      case 'Baja':
        return Colors.greenAccent;
      case 'Media':
        return Colors.orangeAccent;
      case 'Alta':
        return Colors.deepOrangeAccent;
      case 'Urgente':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Color colorEstado(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.orangeAccent;
      case 'En Proceso':
        return Colors.lightBlueAccent;
      case 'Finalizada':
        return Colors.greenAccent;
      case 'Cancelada':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Widget prioridadVisual(String prioridad) {
    final color = colorPrioridad(prioridad);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        prioridad,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String obtenerNombreProyecto(Map<String, dynamic> tarea) {
    final proyecto = tarea['proyectos'];

    if (proyecto is Map<String, dynamic>) {
      return (proyecto['nombre'] ?? 'Sin proyecto').toString();
    }

    if (proyecto is List && proyecto.isNotEmpty) {
      final primerProyecto = proyecto.first;
      if (primerProyecto is Map<String, dynamic>) {
        return (primerProyecto['nombre'] ?? 'Sin proyecto').toString();
      }
    }

    return 'Sin proyecto';
  }

  Widget buildFormularioTarea(
    void Function(void Function()) setDialogState,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            initialValue: proyectoSeleccionadoId,
            dropdownColor: _inputFill,
            style: const TextStyle(color: _textPrimary),
            decoration: _inputDecoration('Proyecto'),
            items: proyectos
                .map(
                  (proyecto) => DropdownMenuItem<int>(
                    value: proyecto['id'] as int,
                    child: Text(
                      (proyecto['nombre'] ?? '').toString(),
                      style: const TextStyle(color: _textPrimary),
                    ),
                  ),
                )
                .toList(),
            onChanged: widget.proyectoId != null
                ? null
                : (value) {
                    setState(() {
                      proyectoSeleccionadoId = value;
                    });
                    setDialogState(() {});
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: tituloController,
            style: const TextStyle(color: _textPrimary),
            decoration: _inputDecoration('Título'),
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
          TextField(
            controller: responsableController,
            style: const TextStyle(color: _textPrimary),
            decoration: _inputDecoration('Responsable'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: prioridadSeleccionada,
            dropdownColor: _inputFill,
            style: const TextStyle(color: _textPrimary),
            decoration: _inputDecoration('Prioridad'),
            items: prioridadesDisponibles
                .map(
                  (prioridad) => DropdownMenuItem<String>(
                    value: prioridad,
                    child: Text(
                      prioridad,
                      style: const TextStyle(color: _textPrimary),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                prioridadSeleccionada = value;
              });
              setDialogState(() {});
            },
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
          const SizedBox(height: 16),
          Text(
            'Avance: ${avanceSeleccionado.round()}%',
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accent,
              inactiveTrackColor: Colors.white24,
              thumbColor: _accentAlt,
              overlayColor: _accent.withValues(alpha: 0.2),
              valueIndicatorColor: _accentAlt,
            ),
            child: Slider(
              value: avanceSeleccionado,
              min: 0,
              max: 100,
              divisions: 100,
              label: '${avanceSeleccionado.round()}%',
              onChanged: (value) {
                setState(() {
                  avanceSeleccionado = value;
                });
                setDialogState(() {});
              },
            ),
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

  Future<void> mostrarDialogoAgregarTarea() async {
    limpiarCampos();

    await showDialog(
      context: context,
      builder: (context) {
        return _buildDialog(
          title: 'Agregar tarea',
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return buildFormularioTarea(setDialogState);
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
                await agregarTarea();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> mostrarDialogoEditarTarea(Map<String, dynamic> tarea) async {
    setState(() {
      cargarDatosTarea(tarea);
    });

    await showDialog(
      context: context,
      builder: (context) {
        return _buildDialog(
          title: 'Editar tarea',
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return buildFormularioTarea(setDialogState);
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
                await actualizarTarea();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> confirmarEliminacion(int id, String titulo) async {
    await showDialog(
      context: context,
      builder: (context) {
        return _buildDialog(
          title: 'Eliminar tarea',
          content: Text(
            '¿Deseas eliminar la tarea $titulo?',
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
                await eliminarTarea(id);
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildListaTareas() {
    if (tareas.isEmpty) {
      return const Center(
        child: Text(
          'No hay tareas registradas',
          style: TextStyle(fontSize: 18, color: _textPrimary),
        ),
      );
    }

    return ListView.builder(
      itemCount: tareas.length,
      itemBuilder: (context, index) {
        final tarea = tareas[index];
        final prioridad =
            (tarea['prioridad'] ?? prioridadesDisponibles[1]).toString();
        final estado =
            (tarea['estado'] ?? estadosDisponibles.first).toString();
        final avance = ((tarea['avance'] ?? 0) as num).toInt().clamp(0, 100);
        final nombreProyecto = obtenerNombreProyecto(tarea);

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
                  '${tarea['id']}',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            title: Text(
              (tarea['titulo'] ?? '').toString(),
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
                    'Código: ${tarea['id']}',
                    style: const TextStyle(color: _textSecondary),
                  ),
                  Text(
                    'Proyecto: $nombreProyecto',
                    style: const TextStyle(color: _textSecondary),
                  ),
                  Text(
                    'Responsable: ${tarea['responsable'] ?? ''}',
                    style: const TextStyle(color: _textSecondary),
                  ),
                  if ((tarea['descripcion'] ?? '').toString().trim().isNotEmpty)
                    Text(
                      'Descripción: ${tarea['descripcion']}',
                      style: const TextStyle(color: _textSecondary),
                    ),
                  const SizedBox(height: 8),
                  prioridadVisual(prioridad),
                  const SizedBox(height: 8),
                  estadoVisual(estado),
                  const SizedBox(height: 10),
                  Text(
                    'Avance: $avance%',
                    style: const TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: avance / 100,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit, color: _accent),
                  onPressed: () => mostrarDialogoEditarTarea(tarea),
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => confirmarEliminacion(
                    tarea['id'] as int,
                    (tarea['titulo'] ?? '').toString(),
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
    tituloController.dispose();
    descripcionController.dispose();
    responsableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tituloAppBar = widget.proyectoId == null
        ? 'Tareas'
        : 'Tareas - ${widget.proyectoNombre ?? "Proyecto"}';

    return Scaffold(
      backgroundColor: _bgTop,
      appBar: AppBar(
        title: Text(tituloAppBar),
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
          onPressed: mostrarDialogoAgregarTarea,
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
              : buildListaTareas(),
        ),
      ),
    );
  }
}
