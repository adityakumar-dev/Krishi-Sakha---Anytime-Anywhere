import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sakha/apis/api_manager.dart';
import 'package:krishi_sakha/models/post_model.dart';
import 'package:krishi_sakha/providers/profile_provider.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class VerifyPostScreen extends StatefulWidget {
  const VerifyPostScreen({super.key});

  @override
  State<VerifyPostScreen> createState() => _VerifyPostScreenState();
}

class _VerifyPostScreenState extends State<VerifyPostScreen> {
  List<PostModel> _pendingPosts = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _fetchPendingPosts();
  }

  Future<void> _fetchPendingPosts({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      setState(() {
        _currentPage = 1;
        _pendingPosts.clear();
      });
    }

    setState(() => _isLoading = true);

    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final userPlaceId = profileProvider.userProfile?.locationiqPlaceId;

      final response = await http.get(
        Uri.parse(
          '${ApiManager.baseUrl}${ApiManager.pendingPostsUrl}?page=$_currentPage&limit=20',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        final List<dynamic> postsJson = responseData['posts'] ?? [];

        // Convert all posts to PostModel
        List<PostModel> fetchedPosts = postsJson
            .map((json) => PostModel.fromJson(json))
            .toList();

        // Prioritize posts from user's location (place_id match) at the top
        if (userPlaceId != null && userPlaceId.isNotEmpty) {
          fetchedPosts.sort((a, b) {
            final aIsLocal = a.placeId == userPlaceId;
            final bIsLocal = b.placeId == userPlaceId;

            if (aIsLocal && !bIsLocal) return -1;
            if (!aIsLocal && bIsLocal) return 1;
            return 0; // Keep original order for posts of same priority
          });
        }

        final pagination = responseData['pagination'];

        setState(() {
          if (refresh) {
            _pendingPosts = fetchedPosts;
          } else {
            _pendingPosts.addAll(fetchedPosts);
          }
          _hasMore = pagination['has_next'] ?? false;
        });
      } else {
        throw Exception(responseData['message'] ?? 'Failed to fetch posts');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyPost(String postId) async {
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${ApiManager.baseUrl}${ApiManager.verifyPostUrl(postId)}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        Fluttertoast.showToast(
          msg: 'Post approved successfully!',
          backgroundColor: AppColors.primaryGreen,
        );
        setState(() {
          _pendingPosts.removeWhere((post) => post.id == postId);
        });
      } else {
        throw Exception(responseData['message'] ?? 'Failed to approve post');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _rejectPost(String postId) async {
    // Show rejection reason dialog
    String? reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectReasonDialog(),
    );

    if (reason == null) return; // User cancelled

    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${ApiManager.baseUrl}${ApiManager.rejectPostUrl(postId)}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'reason': reason},
      );

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        Fluttertoast.showToast(
          msg: 'Post rejected',
          backgroundColor: Colors.orange,
        );
        setState(() {
          _pendingPosts.removeWhere((post) => post.id == postId);
        });
      } else {
        throw Exception(responseData['message'] ?? 'Failed to reject post');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Verify Posts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchPendingPosts(refresh: true),
          ),
        ],
      ),
      body: _isLoading && _pendingPosts.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : _pendingPosts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending posts',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All posts have been reviewed',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _fetchPendingPosts(refresh: true),
              color: AppColors.primaryGreen,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pendingPosts.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _pendingPosts.length) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: () {
                            _currentPage++;
                            _fetchPendingPosts();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                          ),
                          child: const Text('Load More'),
                        ),
                      ),
                    );
                  }

                  final post = _pendingPosts[index];
                  return _PostCard(
                    post: post,
                    onApprove: () => _verifyPost(post.id),
                    onReject: () => _rejectPost(post.id),
                  );
                },
              ),
            ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PostCard({
    required this.post,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final userPlaceId = profileProvider.userProfile?.locationiqPlaceId;
    final isLocalPost =
        userPlaceId != null &&
        userPlaceId.isNotEmpty &&
        post.placeId == userPlaceId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLocalPost
              ? AppColors.primaryGreen.withOpacity(0.5)
              : Colors.grey[200]!,
          width: isLocalPost ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Local Post Badge
          if (isLocalPost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryGreen.withOpacity(0.2),
                    AppColors.primaryGreen.withOpacity(0.1),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.my_location,
                    size: 14,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Your Area',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          // Post Content with Image on Left
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image on Left
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post.imageUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey[500],
                          ),
                        );
                      },
                    ),
                  ),

                if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                  const SizedBox(width: 12),

                // Content on Right
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author Info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryGreen.withOpacity(
                              0.2,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 18,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.authorName ?? 'Anonymous',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (post.authorRole != null)
                                  Text(
                                    post.authorRole!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Post Content
                      Text(
                        post.content,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),

                      const SizedBox(height: 8),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${post.cityName}, ${post.stateName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.cancel, size: 20),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rejection Reason'),
      content: TextField(
        controller: _reasonController,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Enter reason for rejection (optional)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _reasonController.text.trim());
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
