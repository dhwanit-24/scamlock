import 'package:flutter/material.dart';
import '../../../admin/data/search_repository.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

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
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        title: const Text('Search', style: AppTypography.cardTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    focusNode: _focusNode,
                    autofocus: true,
                    style: AppTypography.body,
                    decoration: const InputDecoration(
                      labelText: 'Phone, G Number, or Name',
                      prefixIcon: Icon(Icons.search, color: AppColors.ink),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _performSearch,
                    icon: const Icon(Icons.arrow_forward, color: AppColors.canvas),
                    tooltip: 'Search',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.ink),
                  );
                }

                if (_errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          color: AppColors.signalRed,
                        ),
                      ),
                    ),
                  );
                }

                if (_results.isEmpty && _queryController.text.isNotEmpty) {
                  return const Center(
                    child: Text(
                      'No results found.',
                      style: AppTypography.body,
                    ),
                  );
                }

                if (_results.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Enter a phone number, G Number, or name to search.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
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
                          arguments: {'personId': person['id'] as String, 'person': person},                        );
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
    final isFlagged = lockCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '+91 $phoneNo',
                        style: AppTypography.body,
                      ),
                      if (isFlagged)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blockBlush,
                              borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              '$lockCount lock${lockCount == 1 ? '' : 's'}',
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.signalRed,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}