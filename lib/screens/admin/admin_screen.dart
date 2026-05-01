import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const Color _bgTop = Color(0xFF09101D);
  static const Color _bgBottom = Color(0xFF181A33);
  static const Color _card = Color(0xCC121A2B);
  static const Color _cardBorder = Color(0xFF2A3450);
  static const Color _inputFill = Color(0xFF111A2A);
  static const Color _textPrimary = Color(0xFFF4F7FF);
  static const Color _textSecondary = Color(0xFFAFBCDE);
  static const Color _accent = Color(0xFF6688FF);
  static const Color _accentAlt = Color(0xFF8B5CF6);

  bool isLoading = true;
  final Set<String> updatingUserIds = <String>{};
  List<Map<String, dynamic>> profiles = [];
  List<Map<String, dynamic>> recentLogins = [];
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = supabase.auth.currentUser?.id;
    cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    setState(() => isLoading = true);

    try {
      final responses = await Future.wait([
        supabase
            .from('profiles')
            .select('id, email, rol, bloqueado')
            .order('email', ascending: true),
        supabase
            .from('profiles')
            .select('id, email, rol, bloqueado, last_login')
            .order('last_login', ascending: false)
            .limit(10),
      ]);

      if (!mounted) return;

      setState(() {
        profiles = List<Map<String, dynamic>>.from(responses[0] as List);
        recentLogins = List<Map<String, dynamic>>.from(responses[1] as List);
      });
    } catch (e) {
      if (!mounted) return;
      mostrarMensaje('Error al cargar usuarios: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> actualizarRol(String profileId, String nuevoRol) async {
    await _actualizarUsuario(
      profileId: profileId,
      values: {'rol': nuevoRol},
      successMessage: 'Rol actualizado correctamente',
    );
  }

  Future<void> cambiarBloqueo(String profileId, bool bloqueado) async {
    await _actualizarUsuario(
      profileId: profileId,
      values: {'bloqueado': bloqueado},
      successMessage: bloqueado
          ? 'Usuario bloqueado correctamente'
          : 'Usuario desbloqueado correctamente',
    );
  }

  Future<void> _actualizarUsuario({
    required String profileId,
    required Map<String, dynamic> values,
    required String successMessage,
  }) async {
    setState(() {
      updatingUserIds.add(profileId);
    });

    try {
      await supabase.from('profiles').update(values).eq('id', profileId);

      if (!mounted) return;

      await cargarUsuarios();
      mostrarMensaje(successMessage);
    } catch (e) {
      if (!mounted) return;
      mostrarMensaje('Error al actualizar usuario: $e');
    } finally {
      if (mounted) {
        setState(() {
          updatingUserIds.remove(profileId);
        });
      }
    }
  }

  void mostrarMensaje(String mensaje) {
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

  Widget _buildEstado(bool bloqueado) {
    final color = bloqueado ? Colors.redAccent : Colors.greenAccent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          bloqueado ? 'Bloqueado' : 'Activo',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  IconData _roleIcon(String rol) {
    return rol == 'admin' ? Icons.shield_rounded : Icons.person_rounded;
  }

  Color _roleColor(String rol) {
    return rol == 'admin' ? const Color(0xFFF59E0B) : _accent;
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return 'Sin ingreso registrado';

    final parsed = DateTime.tryParse((value ?? '').toString());
    if (parsed == null) return 'Sin ingreso registrado';

    return DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
  }

  Widget _buildRecentLoginsSection() {
    return Card(
      color: _card,
      margin: const EdgeInsets.only(top: 20, bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: _cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usuarios que ingresaron recientemente',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ultimos 10 accesos registrados en el sistema.',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            if (recentLogins.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No hay ingresos recientes para mostrar.',
                  style: TextStyle(color: _textSecondary),
                ),
              )
            else
              ...recentLogins.map((profile) {
                final email = (profile['email'] ?? 'Sin email').toString();
                final rol = (profile['rol'] ?? 'usuario').toString();
                final bloqueado = profile['bloqueado'] == true;
                final roleColor = _roleColor(rol);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _inputFill,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [_accent, _accentAlt],
                          ),
                        ),
                        child: Icon(
                          _roleIcon(rol),
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email,
                              style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: roleColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: roleColor.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Text(
                                    rol == 'admin' ? 'Administrador' : 'Usuario',
                                    style: TextStyle(
                                      color: roleColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: _buildEstado(bloqueado),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ultimo ingreso: ${_formatDateTime(profile['last_login'])}',
                              style: const TextStyle(color: _textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> profile) {
    final profileId = (profile['id'] ?? '').toString();
    final email = (profile['email'] ?? 'Sin email').toString();
    final rolActual = (profile['rol'] ?? 'usuario').toString();
    final bloqueado = profile['bloqueado'] == true;
    final isUpdating = updatingUserIds.contains(profileId);
    final isCurrentUser = profileId == currentUserId;
    final roleColor = _roleColor(rolActual);

    return Card(
      color: _card,
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: _cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _roleIcon(rolActual),
                    color: roleColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: roleColor.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _roleIcon(rolActual),
                                  size: 16,
                                  color: roleColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  rolActual == 'admin'
                                      ? 'Administrador'
                                      : 'Usuario',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: roleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: _buildEstado(bloqueado),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    initialValue: rolActual,
                    dropdownColor: _inputFill,
                    style: const TextStyle(color: _textPrimary),
                    decoration: _inputDecoration('Rol'),
                    items: const [
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text(
                          'admin',
                          style: TextStyle(color: _textPrimary),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'usuario',
                        child: Text(
                          'usuario',
                          style: TextStyle(color: _textPrimary),
                        ),
                      ),
                    ],
                    onChanged: isUpdating || isCurrentUser
                        ? null
                        : (value) {
                            if (value != null && value != rolActual) {
                              actualizarRol(profileId, value);
                            }
                          },
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 230),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _inputFill,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        unselectedWidgetColor: Colors.white38,
                      ),
                      child: SwitchListTile(
                        activeThumbColor: _accentAlt,
                        activeTrackColor: _accent.withValues(alpha: 0.45),
                        value: bloqueado,
                        onChanged: isUpdating || isCurrentUser
                            ? null
                            : (value) {
                                cambiarBloqueo(profileId, value);
                              },
                        title: Text(
                          bloqueado ? 'Desbloquear usuario' : 'Bloquear usuario',
                          style: const TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          bloqueado
                              ? 'Actualmente no puede acceder al sistema'
                              : 'Actualmente tiene acceso permitido',
                          style: const TextStyle(color: _textSecondary),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (isCurrentUser) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x26F59E0B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x55F59E0B)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_person_rounded,
                      color: Color(0xFFFBBF24),
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'No puedes modificar tu propio usuario',
                        style: TextStyle(
                          color: Color(0xFFFCD34D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isUpdating) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(
                  minHeight: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(_accent),
                  backgroundColor: Colors.white12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTop,
      appBar: AppBar(
        title: const Text('Panel de Administracion'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _textPrimary,
        actions: [
          IconButton(
            onPressed: isLoading ? null : cargarUsuarios,
            icon: const Icon(Icons.refresh),
          ),
        ],
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
              : profiles.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay usuarios registrados en profiles',
                        style: TextStyle(fontSize: 16, color: _textPrimary),
                      ),
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: ListView(
                          children: [
                            ...profiles.map(_buildUserCard),
                            const SizedBox(height: 12),
                            _buildRecentLoginsSection(),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}
