import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  static const Color _bgTop = Color(0xFF09101D);
  static const Color _bgBottom = Color(0xFF181A33);
  static const Color _card = Color(0xCC121A2B);
  static const Color _cardBorder = Color(0xFF2A3450);
  static const Color _inputFill = Color(0xFF111A2A);
  static const Color _textPrimary = Color(0xFFF4F7FF);
  static const Color _textSecondary = Color(0xFFAFBCDE);
  static const Color _accent = Color(0xFF6688FF);
  static const Color _accentAlt = Color(0xFF8B5CF6);

  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final telefonoController = TextEditingController();
  final empresaController = TextEditingController();

  List<Map<String, dynamic>> clientes = [];
  bool isLoading = false;
  int? clienteEditandoId;
  String rol = 'usuario';
  String? currentUserId;

  String selectedCountryCode = '+502';
  String selectedCountryISO = 'GT';
  String estadoSeleccionado = 'Activo';

  static final RegExp _correoRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

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
      await obtenerClientes();
    } catch (e) {
      mostrarMensaje('Error al cargar clientes: $e');
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
    setState(() => isLoading = true);

    try {
      var query = supabase.from('clientes').select();

      if (rol != 'admin' && currentUserId != null) {
        query = query.eq('user_id', currentUserId!);
      }

      final response = await query.order('id', ascending: true);

      setState(() {
        clientes = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      mostrarMensaje('Error al cargar clientes: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> agregarCliente() async {
    final mensajeValidacion = validarFormulario();
    if (mensajeValidacion != null) {
      mostrarMensaje(mensajeValidacion);
      return;
    }

    try {
      await supabase.from('clientes').insert({
        'user_id': supabase.auth.currentUser!.id,
        'nombre': nombreController.text.trim(),
        'correo': correoController.text.trim(),
        'telefono': '$selectedCountryCode ${telefonoController.text.trim()}',
        'empresa': empresaController.text.trim(),
        'estado': estadoSeleccionado,
      });

      limpiarCampos();
      await obtenerClientes();
      mostrarMensaje('Cliente agregado correctamente');
    } catch (e) {
      mostrarMensaje('Error al agregar cliente: $e');
    }
  }

  Future<void> actualizarCliente() async {
    if (clienteEditandoId == null) return;

    final mensajeValidacion = validarFormulario();
    if (mensajeValidacion != null) {
      mostrarMensaje(mensajeValidacion);
      return;
    }

    try {
      await supabase.from('clientes').update({
        'nombre': nombreController.text.trim(),
        'correo': correoController.text.trim(),
        'telefono': '$selectedCountryCode ${telefonoController.text.trim()}',
        'empresa': empresaController.text.trim(),
        'estado': estadoSeleccionado,
      }).eq('id', clienteEditandoId!);

      limpiarCampos();
      await obtenerClientes();
      mostrarMensaje('Cliente actualizado correctamente');
    } catch (e) {
      mostrarMensaje('Error al actualizar cliente: $e');
    }
  }

  Future<void> eliminarCliente(int id) async {
    try {
      await supabase.from('clientes').delete().eq('id', id);
      await obtenerClientes();
      mostrarMensaje('Cliente eliminado correctamente');
    } catch (e) {
      mostrarMensaje('Error al eliminar cliente: $e');
    }
  }

  String? validarFormulario() {
    if (nombreController.text.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }

    final correo = correoController.text.trim();
    if (correo.isEmpty) {
      return 'El correo es obligatorio';
    }

    if (!_correoRegex.hasMatch(correo)) {
      return 'Ingresa un correo con formato válido';
    }

    if (telefonoController.text.trim().isEmpty) {
      return 'El teléfono es obligatorio';
    }

    if (empresaController.text.trim().isEmpty) {
      return 'La empresa es obligatoria';
    }

    if (estadoSeleccionado.trim().isEmpty) {
      return 'El estado es obligatorio';
    }

    return null;
  }

  void limpiarCampos() {
    nombreController.clear();
    correoController.clear();
    telefonoController.clear();
    empresaController.clear();
    clienteEditandoId = null;
    selectedCountryCode = '+502';
    selectedCountryISO = 'GT';
    estadoSeleccionado = 'Activo';
  }

  void cargarDatosCliente(Map<String, dynamic> cliente) {
    clienteEditandoId = cliente['id'];
    nombreController.text = cliente['nombre'] ?? '';
    correoController.text = cliente['correo'] ?? '';
    empresaController.text = cliente['empresa'] ?? '';
    estadoSeleccionado = (cliente['estado'] ?? 'Activo').toString();

    final telefonoCompleto = (cliente['telefono'] ?? '').toString().trim();

    if (telefonoCompleto.startsWith('+')) {
      final partes = telefonoCompleto.split(' ');
      if (partes.isNotEmpty) {
        selectedCountryCode = partes.first;
        telefonoController.text =
            partes.length > 1 ? partes.sublist(1).join(' ') : '';
      } else {
        telefonoController.clear();
      }
    } else {
      telefonoController.text = telefonoCompleto;
    }
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

  Widget estadoVisual(String estado) {
    final esActivo = estado.toLowerCase() == 'activo';
    final color = esActivo ? Colors.greenAccent : Colors.redAccent;

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

  Widget buildFormularioCliente() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nombreController,
            style: const TextStyle(color: _textPrimary),
            decoration: _inputDecoration('Nombre'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: correoController,
            style: const TextStyle(color: _textPrimary),
            decoration: _inputDecoration('Correo'),
          ),
          const SizedBox(height: 12),
          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
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
              ),
            ),
            child: IntlPhoneField(
              style: const TextStyle(color: _textPrimary),
              dropdownTextStyle: const TextStyle(color: _textPrimary),
              initialCountryCode: selectedCountryISO,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              initialValue: telefonoController.text,
              onChanged: (phone) {
                telefonoController.text = phone.number;
                selectedCountryCode = '+${phone.countryCode}';
                selectedCountryISO = phone.countryISOCode;
              },
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: empresaController,
            style: const TextStyle(color: _textPrimary),
            decoration: _inputDecoration('Empresa'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: estadoSeleccionado,
            dropdownColor: _inputFill,
            style: const TextStyle(color: _textPrimary),
            decoration: _inputDecoration('Estado'),
            items: const [
              DropdownMenuItem(
                value: 'Activo',
                child: Text('Activo', style: TextStyle(color: _textPrimary)),
              ),
              DropdownMenuItem(
                value: 'Inactivo',
                child: Text('Inactivo', style: TextStyle(color: _textPrimary)),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  estadoSeleccionado = value;
                });
              }
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
        gradient: const LinearGradient(
          colors: [_accent, _accentAlt],
        ),
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

  Future<void> mostrarDialogoAgregarCliente() async {
    limpiarCampos();

    await showDialog(
      context: context,
      builder: (context) {
        return _buildDialog(
          title: 'Agregar cliente',
          content: buildFormularioCliente(),
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
                await agregarCliente();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> mostrarDialogoEditarCliente(Map<String, dynamic> cliente) async {
    setState(() {
      cargarDatosCliente(cliente);
    });

    await showDialog(
      context: context,
      builder: (context) {
        return _buildDialog(
          title: 'Editar cliente',
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return buildFormularioCliente();
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
                await actualizarCliente();
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
          title: 'Eliminar cliente',
          content: Text(
            '¿Deseas eliminar a $nombre?',
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
                await eliminarCliente(id);
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildListaClientes() {
    if (clientes.isEmpty) {
      return const Center(
        child: Text(
          'No hay clientes registrados',
          style: TextStyle(fontSize: 18, color: _textPrimary),
        ),
      );
    }

    return ListView.builder(
      itemCount: clientes.length,
      itemBuilder: (context, index) {
        final cliente = clientes[index];
        final estado = (cliente['estado'] ?? 'Activo').toString();

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
                gradient: const LinearGradient(
                  colors: [_accent, _accentAlt],
                ),
              ),
              child: Center(
                child: Text(
                  '${cliente['id']}',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            title: Text(
              cliente['nombre'] ?? '',
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
                    'Código: ${cliente['id']}',
                    style: const TextStyle(color: _textSecondary),
                  ),
                  Text(
                    'Correo: ${cliente['correo'] ?? ''}',
                    style: const TextStyle(color: _textSecondary),
                  ),
                  Text(
                    'Teléfono: ${cliente['telefono'] ?? ''}',
                    style: const TextStyle(color: _textSecondary),
                  ),
                  Text(
                    'Empresa: ${cliente['empresa'] ?? ''}',
                    style: const TextStyle(color: _textSecondary),
                  ),
                  const SizedBox(height: 8),
                  estadoVisual(estado),
                ],
              ),
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit, color: _accent),
                  onPressed: () => mostrarDialogoEditarCliente(cliente),
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => confirmarEliminacion(
                    cliente['id'],
                    cliente['nombre'] ?? '',
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
    correoController.dispose();
    telefonoController.dispose();
    empresaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTop,
      appBar: AppBar(
        title: const Text('Clientes'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _textPrimary,
        actions: [
          IconButton(
            onPressed: obtenerClientes,
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
          onPressed: mostrarDialogoAgregarCliente,
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
              : buildListaClientes(),
        ),
      ),
    );
  }
}
