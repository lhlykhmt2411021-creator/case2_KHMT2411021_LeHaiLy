import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/user_service.dart';
import '../../widgets/loading_view.dart';

class UserPickerScreen extends StatefulWidget {
  const UserPickerScreen({
    super.key,
    required this.userService,
    this.title = 'Chọn người dùng',
    this.excludedIds = const <String>{},
  });

  final UserService userService;
  final String title;
  final Set<String> excludedIds;

  @override
  State<UserPickerScreen> createState() => _UserPickerScreenState();
}

class _UserPickerScreenState extends State<UserPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, User> _selected = <String, User>{};

  bool _searching = false;
  bool _searched = false;
  String? _error;
  List<User> _results = const <User>[];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final String keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      setState(() => _error = 'Vui lòng nhập từ khóa tìm kiếm');
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final List<User> users = await widget.userService.searchUsers(keyword);
      if (!mounted) {
        return;
      }
      setState(() {
        _results = users
            .where((User user) => !widget.excludedIds.contains(user.id))
            .toList();
        _searched = true;
        _searching = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _searching = false;
      });
    }
  }

  void _toggle(User user) {
    setState(() {
      if (_selected.containsKey(user.id)) {
        _selected.remove(user.id);
      } else {
        _selected[user.id] = user;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(
                        labelText: 'Tìm theo họ tên hoặc email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _searching ? null : _search,
                    child: const Text('Tìm'),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(child: _buildResults(context)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_selected.values.toList()),
                  child: Text('Chọn (${_selected.length})'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_searching) {
      return const LoadingView(message: 'Đang tìm người dùng...');
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(_searched ? 'Không tìm thấy người dùng phù hợp' : 'Nhập từ khóa để tìm người dùng'),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (BuildContext context, int index) {
        final User user = _results[index];
        return CheckboxListTile(
          value: _selected.containsKey(user.id),
          onChanged: (_) => _toggle(user),
          title: Text(user.fullName),
          subtitle: Text(user.email),
        );
      },
    );
  }
}
