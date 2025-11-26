import 'package:flutter/material.dart';
import 'package:krishi_sakha/models/post_model.dart';
import 'package:krishi_sakha/providers/post_manage_provider.dart';
import 'package:krishi_sakha/providers/profile_provider.dart';
import 'package:krishi_sakha/screens/posts/comments_screen.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  @override
  void initState() {
    super.initState();
    // Load saved posts when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postProvider = Provider.of<PostManageProvider>(context, listen: false);
      postProvider.getSavedPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Posts'),
        elevation: 0,
      ),
      body: Consumer<PostManageProvider>(
        builder: (context, postProvider, child) {
          final savedPosts = postProvider.savedPosts;

          if (savedPosts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved posts yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save posts to view them later',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              postProvider.getSavedPosts();
            },
            child: ListView.builder(
              itemCount: savedPosts.length,
              itemBuilder: (context, index) {
                final post = savedPosts[index];
                return SavedPostCard(post: post);
              },
            ),
          );
        },
      ),
    );
  }
}

class SavedPostCard extends StatefulWidget {
  final PostModel post;

  const SavedPostCard({
    super.key,
    required this.post,
  });

  @override
  State<SavedPostCard> createState() => _SavedPostCardState();
}

class _SavedPostCardState extends State<SavedPostCard> {
  @override
  void initState() {
    super.initState();
  }

  void _removeSavedPost() {
    final provider = Provider.of<PostManageProvider>(context, listen: false);
    provider.removeSavedPost(widget.post.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Post removed from saved'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            provider.savePost(widget.post);
          },
        ),
      ),
    );
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
    final isApproved = widget.post.status == 'approved';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header with author and status badge
            Row(
              children: [
                // Author info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.authorName ?? 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (widget.post.authorRole != null)
                        Text(
                          widget.post.authorRole!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isApproved ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isApproved ? Icons.verified : Icons.hourglass_empty,
                        size: 14,
                        color: isApproved ? Colors.green[700] : Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isApproved ? 'Verified' : 'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isApproved ? Colors.green[700] : Colors.orange[700],
                        ),
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Image if available
            if (widget.post.imageBase64 != null && widget.post.imageBase64!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey[300],
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
                    color: widget.post.isEndorsed ? Colors.green : Colors.grey[700],
                  )
                else
                  _buildActionButton(
                    widget.post.isLiked ? Icons.favorite : Icons.favorite_outline,
                    '${widget.post.likeCount}',
                    _toggleLike,
                    color: widget.post.isLiked ? Colors.red : Colors.grey[700],
                  ),
                _buildActionButton(
                  Icons.chat_bubble_outline,
                  '${widget.post.commentCount}',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentsScreen(post: widget.post),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  Icons.bookmark,
                  '',
                  _removeSavedPost,
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color ?? Colors.grey[700]),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(label, style: TextStyle(color: color ?? Colors.grey[700], fontSize: 12)),
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
