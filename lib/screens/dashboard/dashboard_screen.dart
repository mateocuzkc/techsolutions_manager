import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin/admin_screen.dart';
import '../auth/login_screen.dart';
import '../clientes/clientes_screen.dart';
import '../proyectos/proyectos_screen.dart';
import '../tareas/tareas_screen.dart';

final supabase = Supabase.instance.client;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color _bgTop = Color(0xFF0A0F1F);
  static const Color _bgBottom = Color(0xFF161B33);
  static const Color _panel = Color(0xCC11182B);
  static const Color _panelBorder = Color(0xFF2C3552);
  static const Color _textPrimary = Color(0xFFF4F7FF);
  static const Color _textSecondary = Color(0xFFB5C0E0);
  static const Color _accent = Color(0xFF6C7BFF);
  static const Color _accentAlt = Color(0xFF8B5CF6);

  bool isLoadingProfile = true;
  String rol = 'usuario';
  bool bloqueado = false;

  @override
  void initState() {
    super.initState();
    cargarPerfil();
  }

  Future<void> cargarPerfil() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      await logout();
      return;
    }

    try {
      final response = await supabase
          .from('profiles')
          .select('rol, bloqueado')
          .eq('id', user.id)
          .single();

      final profileRole = (response['rol'] ?? 'usuario').toString();
      final isBlocked = response['bloqueado'] == true;

      if (!mounted) return;

      if (isBlocked) {
        await logout();
        return;
      }

      setState(() {
        rol = profileRole;
        bloqueado = isBlocked;
        isLoadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar el perfil: $e')),
      );

      setState(() {
        rol = 'usuario';
        bloqueado = false;
        isLoadingProfile = false;
      });
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  ButtonStyle _moduleButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: _textPrimary,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }

  Widget _buildModuleButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [_accent, _accentAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x664837A8),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: _moduleButtonStyle(),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFE3E8FF),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final showAdminButton = kIsWeb && rol == 'admin' && !bloqueado;

    return Scaffold(
      backgroundColor: _bgTop,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _textPrimary,
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgTop, _bgBottom, Color(0xFF22103F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: isLoadingProfile
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _panel,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: _panelBorder),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55050813),
                              blurRadius: 34,
                              offset: Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.08),
                                    Colors.white.withValues(alpha: 0.03),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bienvenido, ${user?.email ?? "Usuario"}',
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Rol actual: $rol',
                                    style: const TextStyle(
                                      color: _textSecondary,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Módulos',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildModuleButton(
                              icon: Icons.people,
                              title: 'Módulo de Clientes',
                              subtitle: 'Gestiona tus clientes y su información.',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ClientesScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            _buildModuleButton(
                              icon: Icons.work,
                              title: 'Módulo de Proyectos',
                              subtitle: 'Organiza proyectos, fechas y estados.',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProyectosScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            _buildModuleButton(
                              icon: Icons.task,
                              title: 'Módulo de Tareas',
                              subtitle: 'Da seguimiento al trabajo y al avance.',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TareasScreen(),
                                  ),
                                );
                              },
                            ),
                            if (showAdminButton) ...[
                              const SizedBox(height: 14),
                              _buildModuleButton(
                                icon: Icons.admin_panel_settings,
                                title: 'Panel de Administración',
                                subtitle:
                                    'Administra roles, accesos y bloqueo de usuarios.',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AdminScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
