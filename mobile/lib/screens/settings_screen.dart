import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../core/auth_service.dart';
import '../core/theme.dart';
import '../providers/demo_provider.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isTesting = false;
  String? _testResult;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUrl();
    _loadUser();
  }

  Future<void> _loadUrl() async {
    _urlController.text = await ApiService.getBaseUrl();
  }

  Future<void> _loadUser() async {
    final name = await AuthService.getCurrentUserName();
    if (mounted) setState(() => _userName = name);
  }

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    await ApiService.setBaseUrl(url);
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Backend URL saved'),
          backgroundColor: AppTheme.success));
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _isTesting = true;
      _testResult = null;
    });
    final success = await ApiService.testConnection(url);
    if (mounted)
      setState(() {
        _isTesting = false;
        _testResult = success ? 'connected' : 'unreachable';
      });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted)
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(demoModeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            if (_userName != null) ...[
              _sectionCard(
                icon: Icons.person_outline,
                title: 'Account',
                child: Row(children: [
                  CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.12),
                      radius: 22,
                      child: Text(_userName![0].toUpperCase(),
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18))),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_userName!,
                            style: TextStyle(
                                color: context.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        const Text('Logged in',
                            style: TextStyle(
                                color: AppTheme.success, fontSize: 12)),
                      ])),
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout,
                        size: 16, color: AppTheme.danger),
                    label: const Text('Logout',
                        style: TextStyle(color: AppTheme.danger, fontSize: 13)),
                  ),
                ]),
              ),
              const SizedBox(height: AppTheme.spacingMd),
            ],

            // Theme
            _sectionCard(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              child: Column(children: [
                _themeTile(context, ref, 'System', ThemeMode.system, themeMode,
                    Icons.brightness_auto_outlined),
                _themeTile(context, ref, 'Light', ThemeMode.light, themeMode,
                    Icons.light_mode_outlined),
                _themeTile(context, ref, 'Dark', ThemeMode.dark, themeMode,
                    Icons.dark_mode_outlined),
              ]),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Backend config
            _sectionCard(
              icon: Icons.dns_outlined,
              title: 'Backend Configuration',
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _urlController,
                      style: TextStyle(color: context.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Backend URL',
                        hintText: 'http://10.0.2.2:8000',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 10),
                          child: Icon(Icons.link,
                              size: 18, color: context.onSurfaceVariant),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton.icon(
                        onPressed: _saveUrl,
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: const Text('Save'),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: ElevatedButton.icon(
                        onPressed: _isTesting ? null : _testConnection,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.wifi_find, size: 16),
                        label: const Text('Test'),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                      )),
                    ]),
                    if (_testResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (_testResult == 'connected'
                                  ? AppTheme.success
                                  : AppTheme.danger)
                              .withOpacity(0.08),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(
                              color: (_testResult == 'connected'
                                      ? AppTheme.success
                                      : AppTheme.danger)
                                  .withOpacity(0.3)),
                        ),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  _testResult == 'connected'
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: _testResult == 'connected'
                                      ? AppTheme.success
                                      : AppTheme.danger,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(
                                  _testResult == 'connected'
                                      ? 'Connected'
                                      : 'Unreachable',
                                  style: TextStyle(
                                      color: _testResult == 'connected'
                                          ? AppTheme.success
                                          : AppTheme.danger,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ]),
                      ),
                    ],
                  ]),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Demo mode
            _sectionCard(
              icon: Icons.science_outlined,
              title: 'Demo Mode',
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('When enabled, all data is mocked locally.',
                        style: TextStyle(
                            color: context.onSurfaceVariant, fontSize: 12)),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Demo Mode',
                          style: TextStyle(
                              color: context.onSurface, fontSize: 14)),
                      subtitle: Text(
                          isDemoMode
                              ? 'ON — Using offline data'
                              : 'OFF — Using live backend',
                          style: TextStyle(
                              color: isDemoMode
                                  ? AppTheme.success
                                  : context.onSurfaceVariant,
                              fontSize: 12)),
                      value: isDemoMode,
                      activeColor: AppTheme.primary,
                      onChanged: (val) =>
                          ref.read(demoModeProvider.notifier).state = val,
                    ),
                  ]),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // About
            _sectionCard(
              icon: Icons.info_outline,
              title: 'About',
              child: Column(children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.shield, color: const Color(0xFF00E5FF).withOpacity(0.15), size: 48),
                    const Icon(Icons.shield_outlined, color: const Color(0xFF00E5FF), size: 48),
                    const Icon(Icons.ac_unit, color: const Color(0xFF00E5FF), size: 22),
                  ],
                ),
                const SizedBox(height: 10),
                Text('ColdGuard',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.onSurface)),
                const SizedBox(height: 3),
                Text('AI-Powered Cold Chain Protection',
                    style: TextStyle(
                        color: context.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 14),
                _aboutRow('Version', '1.0.0'),
                _aboutRow('Built with', 'Flutter, Gemini API'),
                const SizedBox(height: 10),
                Text('© 2026 ColdGuard Team',
                    style: TextStyle(
                        color: context.onSurfaceVariant, fontSize: 10)),
              ]),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
      {required IconData icon, required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: context.outline.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.onSurface)),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  Widget _themeTile(BuildContext context, WidgetRef ref, String label,
      ThemeMode mode, ThemeMode current, IconData icon) {
    final isSelected = current == mode;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      dense: true,
      leading: Icon(icon,
          size: 18,
          color: isSelected ? AppTheme.primary : context.onSurfaceVariant),
      title:
          Text(label, style: TextStyle(color: context.onSurface, fontSize: 14)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 18)
          : null,
      onTap: () => ref.read(themeModeProvider.notifier).setMode(mode),
    );
  }

  Widget _aboutRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: TextStyle(
                      color: context.onSurfaceVariant, fontSize: 12))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      color: context.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600))),
        ]),
      );
}
