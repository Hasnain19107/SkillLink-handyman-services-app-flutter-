import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../widgets/home/category_provider.dart';
import 'home_header.dart';
import 'search_bar_widget.dart';
import 'categories_section.dart';
import 'top_rated_section.dart';
import 'search_results_overlay.dart';
import '../../search/search_result.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  State<HomeContent> createState() => HomeContentState();
}

class HomeContentState extends State<HomeContent> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _imageUrl = '';
  String _name = '';
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _showSearchResults = false;
  bool _isSearching = false;
  int _unreadNotificationCount = 0;

  final GlobalKey _topRatedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _searchController.addListener(_onSearchChanged);
    _listenToNotifications();
  }

  void _listenToNotifications() {
    final user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _unreadNotificationCount = snapshot.docs.length;
          });
        }
      });
    }
  }

  Future<void> refresh() async {
    await _refreshData();
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      HapticFeedback.lightImpact();
      await _loadUserData();

      if (_showSearchResults && _searchController.text.trim().isNotEmpty) {
        await _performSearch(_searchController.text.trim());
      }

      setState(() {
        _topRatedKey;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Content refreshed'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error refreshing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Failed to refresh'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.length >= 2) {
      setState(() {
        _isSearching = true;
        _showSearchResults = true;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (_searchController.text.trim() == query) {
          _performSearch(query);
        }
      });
    } else {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    try {
      final providersSnapshot = await _firestore
          .collection('service_providers')
          .where('searchKeywords', arrayContains: query.toLowerCase())
          .limit(5)
          .get();

      List<QueryDocumentSnapshot> providers = providersSnapshot.docs;
      if (providers.isEmpty) {
        final nameSnapshot = await _firestore
            .collection('service_providers')
            .orderBy('fullName')
            .startAt([query])
            .endAt([query + '\uf8ff'])
            .limit(5)
            .get();
        providers = nameSnapshot.docs;

        if (providers.isEmpty) {
          final categorySnapshot = await _firestore
              .collection('service_providers')
              .where('profession', isEqualTo: query.toLowerCase())
              .limit(5)
              .get();
          providers = categorySnapshot.docs;
        }
      }

      final categorySnapshot = await _firestore
          .collection('service_providers')
          .where('category', isEqualTo: query.toLowerCase())
          .limit(5)
          .get();

      final Set<String> addedIds = {};
      final List<Map<String, dynamic>> results = [];

      for (var doc in providers) {
        if (!addedIds.contains(doc.id)) {
          addedIds.add(doc.id);
          final data = doc.data() as Map<String, dynamic>;
          results.add({
            'id': doc.id,
            'name': data['fullName'] ?? data['name'] ?? 'Unknown',
            'category': data['category'] ?? data['profession'] ?? 'General',
            'rating': data['rating'] ?? 0.0,
            'imageUrl': data['profileImageUrl'] ?? data['imageUrl'] ?? '',
            'type': 'provider',
            'review': data['review'] ?? 0,
          });
        }
      }

      for (var doc in categorySnapshot.docs) {
        if (!addedIds.contains(doc.id)) {
          addedIds.add(doc.id);
          final data = doc.data();
          results.add({
            'id': doc.id,
            'name': data['fullName'] ?? data['name'] ?? 'Unknown',
            'category': data['category'] ?? data['profession'] ?? 'General',
            'rating': data['rating'] ?? 0.0,
            'imageUrl': data['profileImageUrl'] ?? data['imageUrl'] ?? '',
            'type': 'provider',
            'review': data['review'] ?? 0,
          });
        }
      }

      final categories = [
        'Electrical',
        'Plumbing',
        'Cleaning',
        'Painting',
        'Carpentry',
        'Gardening',
        'Moving',
        'Appliance Repair',
        'Computer Repair',
        'Other'
      ];
      for (var category in categories) {
        if (category.toLowerCase().contains(query.toLowerCase())) {
          results.add({
            'id': category.toLowerCase(),
            'name': category,
            'type': 'category',
          });
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _showSearchResults = true;
        });
      }
    } catch (e) {
      print('Error searching providers: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
          _showSearchResults = true;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final userData =
            await _firestore.collection('service_seekers').doc(user.uid).get();

        if (userData.exists) {
          final data = userData.data();
          if (mounted) {
            setState(() {
              _imageUrl = data?['imageUrl'] ?? '';
              _name = data?['fullName'] ?? 'User';
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _name = 'User';
          _isLoading = false;
        });
      }
    }
  }

  void _handleSearch() {
    if (_searchController.text.trim().isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(
            searchQuery: _searchController.text.trim(),
          ),
        ),
      );
    }
  }

  void _handleCategoryTap(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryProvidersList(
          category: category,
        ),
      ),
    );
  }

  void _handleSearchResultTap(Map<String, dynamic> result) {
    setState(() {
      _showSearchResults = false;
    });

    if (result['type'] == 'category') {
      _handleCategoryTap(result['name']);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(
            searchQuery: '',
            providerId: result['id'],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: _refreshData,
          color: Colors.blue,
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          displacement: 40,
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeHeader(
                      name: _name,
                      imageUrl: _imageUrl,
                      isLoading: _isLoading,
                      isRefreshing: _isRefreshing,
                      unreadNotificationCount: _unreadNotificationCount,
                    ),
                    SearchBarWidget(
                      controller: _searchController,
                      onSubmitted: _handleSearch,
                      onClear: () {
                        _searchController.clear();
                        setState(() {
                          _showSearchResults = false;
                        });
                      },
                      isDarkMode: isDarkMode,
                    ),
                    if (!_showSearchResults) ...[
                      CategoriesSection(
                        onCategoryTap: _handleCategoryTap,
                      ),
                      TopRatedSection(
                        topRatedKey: _topRatedKey,
                      ),
                    ],
                  ],
                ),
              ),
              if (_showSearchResults)
                SearchResultsOverlay(
                  isSearching: _isSearching,
                  searchResults: _searchResults,
                  onRefreshSearch: () {
                    if (_searchController.text.trim().isNotEmpty) {
                      _performSearch(_searchController.text.trim());
                    }
                  },
                  onClose: () {
                    setState(() {
                      _showSearchResults = false;
                    });
                  },
                  onResultTap: _handleSearchResultTap,
                  isDarkMode: isDarkMode,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
