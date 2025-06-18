import 'dart:convert';
import 'package:SkillLink/features/service_seeker/screens/search/provider_detail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../widgets/home/search_bar.dart';

class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;
  final String? category;
  final String? providerId;

  const SearchResultsScreen({
    Key? key,
    required this.searchQuery,
    this.category,
    this.providerId,
  }) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final SearchProvider _searchProvider = SearchProvider();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Filters
  String _selectedCategory = 'All';
  double _minRating = 0.0;
  String _sortBy = 'Rating';

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (widget.providerId != null) {
        // Load single provider
        final provider =
            await _searchProvider.getProviderById(widget.providerId!);
        if (provider != null) {
          setState(() {
            _searchResults = [provider];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Provider not found';
            _isLoading = false;
          });
        }
      } else if (widget.category != null && widget.category!.isNotEmpty) {
        // Search by category
        final results = await _searchProvider.searchProviders('',
            category: widget.category);
        setState(() {
          _searchResults = results;
          _isLoading = false;
          if (widget.category != null) {
            _selectedCategory = widget.category!;
          }
        });
      } else if (widget.searchQuery.isNotEmpty) {
        // Search by query
        final results =
            await _searchProvider.searchProviders(widget.searchQuery);
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      } else {
        // Load all providers (limited)
        final snapshot = await FirebaseFirestore.instance
            .collection('service_providers') // Updated collection name
            .orderBy('rating', descending: true)
            .limit(20)
            .get();

        final results = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['fullName'] ??
                data['name'] ??
                'Unknown', // Updated field name
            'category': data['category'] ??
                data['profession'] ??
                'General', // Added fallback
            'rating': data['rating'] ?? 0.0,
            'imageUrl': data['profileImageUrl'] ??
                data['imageUrl'] ??
                '', // Updated field name
            'services': data['services'] ?? [],
            'description': data['description'] ?? '',
          };
        }).toList();

        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading results: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      // Filter by category
      if (_selectedCategory != 'All') {
        _searchResults = _searchResults
            .where((provider) => provider['category'] == _selectedCategory)
            .toList();
      }

      // Filter by rating
      _searchResults = _searchResults
          .where((provider) => (provider['rating'] ?? 0.0) >= _minRating)
          .toList();

      // Sort results
      if (_sortBy == 'Rating') {
        _searchResults
            .sort((a, b) => (b['rating'] ?? 0.0).compareTo(a['rating'] ?? 0.0));
      } else if (_sortBy == 'Name') {
        _searchResults
            .sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Search Results';
    if (widget.providerId != null) {
      title = 'Provider Details';
    } else if (widget.category != null && widget.category!.isNotEmpty) {
      title = widget.category!;
    } else if (widget.searchQuery.isNotEmpty) {
      title = 'Results for "${widget.searchQuery}"';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (widget.providerId == null)
            IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: () {
                _showFilterDialog();
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _searchResults.isEmpty
                  ? Center(child: Text('No results found'))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final provider = _searchResults[index];
                        return ProviderListItem(provider: provider);
                      },
                    ),
    );
  }

  void _showFilterDialog() {
    // Get all unique categories from results
    final categories = ['All'];
    for (var provider in _searchResults) {
      final category = provider['category'] ?? 'General';
      if (!categories.contains(category)) {
        categories.add(category);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Filter Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category'),
              DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              Text('Minimum Rating'),
              Slider(
                value: _minRating,
                min: 0,
                max: 5,
                divisions: 10,
                label: _minRating.toString(),
                onChanged: (value) {
                  setState(() {
                    _minRating = value;
                  });
                },
              ),
              SizedBox(height: 16),
              Text('Sort By'),
              Row(
                children: [
                  Radio<String>(
                    value: 'Rating',
                    groupValue: _sortBy,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                      }
                    },
                  ),
                  Text('Rating'),
                  SizedBox(width: 16),
                  Radio<String>(
                    value: 'Name',
                    groupValue: _sortBy,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                      }
                    },
                  ),
                  Text('Name'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyFilters();
              },
              child: Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProviderListItem extends StatelessWidget {
  final Map<String, dynamic> provider;

  const ProviderListItem({
    Key? key,
    required this.provider,
  }) : super(key: key);

  // Helper method to check if a string is base64 encoded
  bool _isBase64(String str) {
    try {
      // Try to decode and check if it succeeds
      base64Decode(str);
      // Additional check: base64 strings are typically multiples of 4 in length
      // and contain only valid base64 characters
      final regex = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
      return regex.hasMatch(str) && str.length % 4 == 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider image - FIXED to handle both URL and base64
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: provider['imageUrl'] != null &&
                      provider['imageUrl'].isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImage(provider['imageUrl']),
                    )
                  : Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey[400],
                    ),
            ),
            SizedBox(width: 16),
            // Provider details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    provider['category'] ?? 'General',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${(provider['rating'] ?? 0.0).toStringAsFixed(1)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (provider['distance'] != null) ...[
                        SizedBox(width: 16),
                        Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${provider['distance'].toStringAsFixed(1)} km',
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    provider['description'] ?? 'No description available',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProviderDetailScreen(
                            providerId: provider['id'],
                            providerData: provider.cast<String, Object>(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: Size(120, 36),
                    ),
                    child: Text('View Profile'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the appropriate image widget based on the imageUrl format
  Widget _buildImage(String imageUrl) {
    // Check if the imageUrl is a valid URL
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.person,
          size: 40,
          color: Colors.grey[400],
        ),
      );
    }
    // Check if it's a base64 encoded image
    else if (_isBase64(imageUrl)) {
      try {
        return Image.memory(
          base64Decode(imageUrl),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.person,
            size: 40,
            color: Colors.grey[400],
          ),
        );
      } catch (e) {
        // Fallback to default icon if base64 decoding fails
        return Icon(
          Icons.person,
          size: 40,
          color: Colors.grey[400],
        );
      }
    }
    // For any other format, use a default icon
    else {
      return Icon(
        Icons.person,
        size: 40,
        color: Colors.grey[400],
      );
    }
  }
}
