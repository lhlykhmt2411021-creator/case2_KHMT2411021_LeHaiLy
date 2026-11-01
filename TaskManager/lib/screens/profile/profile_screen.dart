import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'change_password_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authService,
    required this.user,
  });

  final AuthService authService;
  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _user = widget.user;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final String? token = await widget.authService.readToken();
    if (token == null) {
      if (mounted) {
        _goToLogin();
      }
      return;
    }

    try {
      final User user = await widget.authService.fetchCurrentUser(token);
      if (!mounted) {
        return;
      }
      setState(() => _user = user);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.statusCode == 401) {
        await widget.authService.logout();
        if (!mounted) {
          return;
        }
        _goToLogin();
        return;
      }
      _showMessage(error.message);
    }
  }

  Future<void> _openEditProfile() async {
    final User? updated = await Navigator.of(context).push<User>(
      MaterialPageRoute<User>(
        builder: (_) => ProfileEditScreen(
          authService: widget.authService,
          user: _user,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _user = updated);
      _showMessage('Đã cập nhật hồ sơ');
    }
  }

  Future<void> _openChangePassword() async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ChangePasswordScreen(authService: widget.authService),
      ),
    );

    if (changed == true && mounted) {
      _showMessage('Đã đổi mật khẩu');
    }
  }

  Future<void> _logout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc muốn đăng xuất khỏi ứng dụng?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await widget.authService.logout();
    if (!mounted) {
      return;
    }
    _goToLogin();
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(authService: widget.authService),
      ),
      (Route<dynamic> route) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _initial {
    final String name = _user.fullName.trim();
    return name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: <Widget>[
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: _user.avatarUrl.isNotEmpty
                    ? NetworkImage(_user.avatarUrl)
                    : null,
                onBackgroundImageError: _user.avatarUrl.isNotEmpty
                    ? (Object error, StackTrace? stackTrace) {}
                    : null,
                child: _user.avatarUrl.isNotEmpty
                    ? null
                    : Text(
                        _initial,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _user.fullName,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                _user.email,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Cập nhật hồ sơ'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openEditProfile,
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Đổi mật khẩu'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openChangePassword,
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}
