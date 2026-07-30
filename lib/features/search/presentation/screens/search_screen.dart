import 'package:flutter/material.dart';
import '../../../admin/data/search_repository.dart';
import '../../../../core/routes/app_routes.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchRepository = SearchRepository();
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _searchRepository.searchTrackedPeople(
        query: query,
      );

      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Search error: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Search failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  int _lockCount(Map<String, dynamic> person) {
    final locks = person['locks'];
    if (locks is List) {
      final first = locks.isNotEmpty ? locks.first : null;
      if (first is Map) {
        final count = first['count'];
        if (count is int) return count;
        if (count is String) return int.tryParse(count) ?? 0;
      }
      return 0;
    }
    if (locks is Map) {
      final count = locks['count'];
      if (count is int) return count;
      if (count is String) return int.tryParse(count) ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    focusNode: _focusNode,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Phone, G Number, or Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _performSearch,
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'Search',
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (_errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (_results.isEmpty && _queryController.text.isNotEmpty) {
                  return const Center(
                    child: Text('No results found.'),
                  );
                }

                if (_results.isEmpty) {
                  return const Center(
                    child: Text(
                      'Enter a phone number, G Number, or name to search.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final person = _results[index];
                    final lockCount = _lockCount(person);

                    return _SearchResultCard(
                      fullName: person['full_name'] as String? ?? 'Unknown',
                      phoneNo: person['phone_no'] as String? ?? '',
                      lockCount: lockCount,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.recordDetail,
                          arguments: {'personId': person['id'] as String, 'person': person, 'lockCount': lockCount, 'phoneNo': person['phone_no'] as String? ?? '',},
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.fullName,
    required this.phoneNo,
    required this.lockCount,
    required this.onTap,
  });

  final String fullName;
  final String phoneNo;
  final int lockCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          fullName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('+91 $phoneNo'),
            if (lockCount > 0)
              Text(
                '$lockCount lock${lockCount == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}