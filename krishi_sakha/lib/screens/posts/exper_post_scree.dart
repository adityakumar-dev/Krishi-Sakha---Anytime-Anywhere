import 'package:flutter/material.dart';
import 'package:krishi_sakha/models/post_model.dart';
import 'package:krishi_sakha/providers/post_manage_provider.dart';
import 'package:krishi_sakha/providers/profile_provider.dart';
import 'package:krishi_sakha/screens/posts/comments_modal.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class ExpertPostsScreen extends StatefulWidget {
  const ExpertPostsScreen({super.key});

  @override
  State<ExpertPostsScreen> createState() => _ExpertPostsScreenState();
}

class _ExpertPostsScreenState extends State<ExpertPostsScreen> {
  String? _selectedStatus; // null = all statuses
  String? _selectedPlaceId; // For city filter
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    // Fetch expert posts when screen loads (only 'expert' type, approved by default)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPosts();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _fetchMorePosts();
    }
  }

  void _fetchPosts() {
    final postProvider = Provider.of<PostManageProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    // Determine place_id based on filter selection
    String? placeIdParam;
    if (_selectedPlaceId != null) {
      // Your City filter is selected - use actual place_id from profile
      placeIdParam = profileProvider.userProfile?.locationiqPlaceId;
    } else {
      // All filter - send null to get all posts
      placeIdParam = null;
    }
    
    postProvider.fetchPosts('expert', _selectedStatus, placeIdParam);
  }

  Future<void> _fetchMorePosts() async {
    if (_isLoadingMore) return;
    
    final postProvider = Provider.of<PostManageProvider>(context, listen: false);
    if (postProvider.allPosts.isEmpty) return; // Don't load more if no posts
    
    setState(() => _isLoadingMore = true);
    
    // Simulate loading - in production, you would fetch next page from API
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() => _isLoadingMore = false);
    // Note: Actual pagination would require API support with offset/limit parameters
    // For now, we just show loading indicator when scrolling to bottom
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Expert Advice', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[800],
      ),
      body: Column(
        children: [
          // Status filter tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _buildFilterTab('All', null),
                  _buildFilterTab('Your City', 'your_city'),
                ],
              ),
            ),
          ),
          // Posts list
          Expanded(
            child: Consumer<PostManageProvider>(
              builder: (context, postProvider, child) {
                if (postProvider.status == "Fetching posts...") {
                  return const Center(child: CircularProgressIndicator());
                }

                if (postProvider.error != null && postProvider.error!.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${postProvider.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchPosts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final posts = postProvider.allPosts;

                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No expert posts found'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchPosts,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _fetchPosts();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: posts.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == posts.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final post = posts[index];
                      return ExpertPostCard(post: post);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String? placeFilter) {
    final bool isSelected;
    if (placeFilter == 'your_city') {
      isSelected = _selectedPlaceId != null;
    } else {
      isSelected = _selectedPlaceId == null;
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (placeFilter == 'your_city') {
            _selectedPlaceId = _selectedPlaceId == null ? 'user_city' : null;
          } else {
            _selectedPlaceId = null;
          }
          _selectedStatus = null; // Always null for expert posts (no approval concept)
        });
        _fetchPosts();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class ExpertPostCard extends StatefulWidget {
  final PostModel post;

  const ExpertPostCard({
    super.key,
    required this.post,
  });

  @override
  State<ExpertPostCard> createState() => _ExpertPostCardState();
}

class _ExpertPostCardState extends State<ExpertPostCard> {
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isSaved = Provider.of<PostManageProvider>(context, listen: false).isPostSaved(widget.post.id);
  }

  void _toggleSavePost() {
    final provider = Provider.of<PostManageProvider>(context, listen: false);

    if (_isSaved) {
      provider.removeSavedPost(widget.post.id);
      setState(() => _isSaved = false);
    } else {
      provider.savePost(widget.post);
      setState(() => _isSaved = true);
    }
  }

  void _showComments() {
    CommentsModal.show(context, widget.post);
  }

  void _toggleLike() {
    final provider = Provider.of<PostManageProvider>(context, listen: false);
    provider.togglePostLike(widget.post.id);
  }

  void _toggleEndorsement() {
    final provider = Provider.of<PostManageProvider>(context, listen: false);
    provider.togglePostEndorsement(widget.post.id);
  }

  bool _canEndorse() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final userRole = profileProvider.userProfile?.role ?? 'normal';
    return ['asha', 'panchayat', 'gov'].contains(userRole);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue[100]!, width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post header with expert badge and author info
              Row(
                children: [
                  // Expert badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[700]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        const Text(
                          'Expert',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // Author info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.post.authorName ?? 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        textAlign: TextAlign.right,
                      ),
                      if (widget.post.authorRole != null)
                        Text(
                          widget.post.authorRole!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          textAlign: TextAlign.right,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Post content
            Text(
              widget.post.content,
              style: const TextStyle(fontSize: 14, height: 1.5),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Image if available
            if (widget.post.imageBase64 != null && widget.post.imageBase64!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.memory(
                    base64Decode(widget.post.imageBase64!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Location and time
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${widget.post.cityName}, ${widget.post.stateName}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(widget.post.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                // Show like button for normal users, endorse button for privileged users
                if (_canEndorse())
                  _buildActionButton(
                    widget.post.isEndorsed ? Icons.thumb_up : Icons.thumb_up_outlined,
                    '${widget.post.endorsementCount}',
                    _toggleEndorsement,
                    color: widget.post.isEndorsed ? Colors.green : Colors.blue[700],
                  )
                else
                  _buildActionButton(
                    widget.post.isLiked ? Icons.favorite : Icons.favorite_outline,
                    '${widget.post.likeCount}',
                    _toggleLike,
                    color: widget.post.isLiked ? Colors.red : Colors.blue[700],
                  ),
                _buildActionButton(
                  Icons.chat_bubble_outline,
                  '${widget.post.commentCount}',
                  _showComments,
                ),
                _buildActionButton(
                  _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  '',
                  _toggleSavePost,
                  color: _isSaved ? Colors.blue : Colors.blue[700],
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color ?? Colors.blue[600]),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color ?? Colors.blue[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
