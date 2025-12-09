import 'package:flutter/material.dart';
import 'package:krishi_sakha/l10n/app_localizations.dart';
import 'package:krishi_sakha/models/post_model.dart';
import 'package:krishi_sakha/providers/post_manage_provider.dart';
import 'package:krishi_sakha/screens/posts/comments_screen.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';
import 'package:krishi_sakha/widgets/translater_widgets.dart';
import 'package:provider/provider.dart';

class ExpertPostsScreen extends StatefulWidget {
  const ExpertPostsScreen({super.key});

  @override
  State<ExpertPostsScreen> createState() => _ExpertPostsScreenState();
}

class _ExpertPostsScreenState extends State<ExpertPostsScreen> {
  String _selectedType = 'expert'; // Default to expert
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPosts();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _fetchMorePosts();
    }
  }

  void _fetchPosts() {
    final postProvider = Provider.of<PostManageProvider>(
      context,
      listen: false,
    );

    // Fetch special posts with type filter, approved status only
    postProvider.fetchPosts(_selectedType, 'approved', null);
  }

  Future<void> _fetchMorePosts() async {
    if (_isLoadingMore) return;

    final postProvider = Provider.of<PostManageProvider>(
      context,
      listen: false,
    );
    if (postProvider.allPosts.isEmpty) return;

    setState(() => _isLoadingMore = true);

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _isLoadingMore = false);
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
        title: Text(
          AppLocalizations.of(context)!.expertPosts,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryGreen,
      ),
      body: Column(
        children: [
          // Type filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    AppLocalizations.of(context)!.expertAdvice,
                    'expert',
                    Icons.lightbulb_outline,
                  ),
                  _buildFilterChip(
                    AppLocalizations.of(context)!.successStories,
                    'success',
                    Icons.celebration_outlined,
                  ),
                  _buildFilterChip(
                    AppLocalizations.of(context)!.bulletins,
                    'bulletin',
                    Icons.campaign_outlined,
                  ),
                ],
              ),
            ),
          ),
          // Posts list
          Expanded(
            child: Consumer<PostManageProvider>(
              builder: (context, postProvider, child) {
                if (postProvider.status == "Fetching posts...") {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  );
                }

                if (postProvider.error != null &&
                    postProvider.error!.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${AppLocalizations.of(context)!.error}: ${postProvider.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchPosts,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                          ),
                          child: Text(AppLocalizations.of(context)!.retry),
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
                        Icon(
                          Icons.article_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noPostsFound,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${AppLocalizations.of(context)!.no} ${_getTypeLabel(context, _selectedType).toLowerCase()} ${AppLocalizations.of(context)!.posts.toLowerCase()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchPosts,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                          ),
                          child: Text(AppLocalizations.of(context)!.refresh),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _fetchPosts();
                  },
                  color: AppColors.primaryGreen,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: posts.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == posts.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        );
                      }
                      final post = posts[index];
                      return _ExpertPostCard(post: post);
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

  Widget _buildFilterChip(String label, String type, IconData icon) {
    final isSelected = _selectedType == type;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.primaryGreen,
            ),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedType = type;
          });
          _fetchPosts();
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.primaryGreen,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.primaryGreen,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: isSelected
              ? AppColors.primaryGreen
              : AppColors.primaryGreen.withOpacity(0.3),
        ),
      ),
    );
  }

  String _getTypeLabel(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'expert':
        return l10n.expertAdvice;
      case 'success':
        return l10n.successStories;
      case 'bulletin':
        return l10n.bulletins;
      default:
        return type;
    }
  }
}

class _ExpertPostCard extends StatefulWidget {
  final PostModel post;

  const _ExpertPostCard({required this.post});

  @override
  State<_ExpertPostCard> createState() => _ExpertPostCardState();
}

class _ExpertPostCardState extends State<_ExpertPostCard> {
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isSaved = Provider.of<PostManageProvider>(
      context,
      listen: false,
    ).isPostSaved(widget.post.id);
  }

  void _toggleLike() {
    final provider = Provider.of<PostManageProvider>(context, listen: false);
    provider.togglePostLike(widget.post.id);
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

  String _getPostTypeIcon() {
    switch (widget.post.type) {
      case 'expert':
        return '👨‍🌾';
      case 'success':
        return '🎉';
      case 'bulletin':
        return '📢';
      default:
        return '📝';
    }
  }

  String _getPostTypeLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.post.type) {
      case 'expert':
        return l10n.expertAdvice;
      case 'success':
        return l10n.successStory;
      case 'bulletin':
        return l10n.bulletin;
      default:
        return widget.post.type;
    }
  }

  Color _getPostTypeColor() {
    switch (widget.post.type) {
      case 'expert':
        return Colors.blue;
      case 'success':
        return Colors.green;
      case 'bulletin':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getPostTypeColor().withOpacity(0.2),
                  _getPostTypeColor().withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(_getPostTypeIcon(), style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  _getPostTypeLabel(context),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _getPostTypeColor(),
                  ),
                ),
                const Spacer(),
                Icon(Icons.verified, size: 18, color: AppColors.primaryGreen),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.verified,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.authorName ?? 'Anonymous',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (widget.post.authorRole != null)
                            Text(
                              widget.post.authorRole!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
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
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Image if available
                if (widget.post.imageUrl != null &&
                    widget.post.imageUrl!.isNotEmpty)
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
                      child: Image.network(
                        widget.post.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey[400],
                              size: 40,
                            ),
                          );
                        },
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
                    _buildActionButton(
                      widget.post.isLiked
                          ? Icons.favorite
                          : Icons.favorite_outline,
                      '${widget.post.likeCount}',
                      _toggleLike,
                      color: widget.post.isLiked
                          ? Colors.red
                          : Colors.grey[700],
                    ),
                    _buildActionButton(
                      Icons.chat_bubble_outline,
                      '${widget.post.commentCount}',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CommentsScreen(post: widget.post),
                          ),
                        );
                      },
                    ),
                    _buildActionButton(
                      _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                      '',
                      _toggleSavePost,
                      color: _isSaved ? Colors.blue : Colors.grey[700],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Translate button
                Align(
                  alignment: Alignment.centerRight,
                  child: buildTranslationButton(widget.post.content),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color ?? Colors.grey[600]),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color ?? Colors.grey[600],
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
