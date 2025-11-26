import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krishi_sakha/apis/api_manager.dart';
import 'package:krishi_sakha/models/comment_model.dart';
import 'package:krishi_sakha/models/post_model.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sakha/providers/profile_provider.dart';
import 'package:krishi_sakha/services/app_logger.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class PostManageProvider extends ChangeNotifier{
  final String boxName = 'saved_posts';
  late Box<PostModel> savedPostsBox;
  List<PostModel> _allPosts = [];
  List<PostModel> get allPosts => _allPosts;
  
  List<PostModel> _userPosts = [];
  List<PostModel> get userPosts => _userPosts;
  
  Map<String, dynamic>? _pagination;
  Map<String, dynamic>? get pagination => _pagination;

  List<PostModel> _savedPosts = [];
  List<PostModel> get savedPosts => _savedPosts;

  String? error;
  String? status = "";
  final String accessToken = Supabase.instance.client.auth.currentSession?.accessToken ?? "";

  PostManageProvider() {
    _initSavedPostsBox();
  }

  Future<void> _initSavedPostsBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      savedPostsBox = await Hive.openBox<PostModel>(boxName);
      _loadSavedPosts();
    } else {
      savedPostsBox = Hive.box<PostModel>(boxName);
      _loadSavedPosts();
    }
  }

  void _loadSavedPosts() {
    _savedPosts = savedPostsBox.values.toList();
    notifyListeners();
  }

  // Check if a post is saved by id
  bool isPostSaved(String postId) {
    return _savedPosts.any((post) => post.id == postId);
  }

  Future<void> fetchPosts(String? typeFilter, String? statusFilter,String? placeId, { int limit = 20, int offset = 0}) async {
    status = "Fetching posts...";
    notifyListeners();

    try {
      // Call Supabase RPC function directly
      // Handle "your_city" special case - use user's place_id
      String? finalPlaceId = placeId;
      if (placeId == 'user_city') {
        
        // TODO: Get user's city place_id from profile
        finalPlaceId = null; // For now, fetch all
      }

      final response = await Supabase.instance.client.rpc(
        'get_posts_with_data',
        params: {
          'place_arg': finalPlaceId,
          'type_arg': typeFilter,
          'status_arg': statusFilter,
          'limit_arg': limit,
          'offset_arg': offset,
        },
      );

      if (response != null && response is List) {
        AppLogger.debug('Fetched ${response.length} posts from Supabase RPC get_posts');
    AppLogger.debug('Fetching posts with type: $typeFilter, status: $statusFilter, placeId: $placeId, limit: $limit, offset: $offset');
        _allPosts = response
            .map((json) {
              try {
                return PostModel.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                AppLogger.error('Error parsing post: $e');
                return null;
              }
            })
            .whereType<PostModel>()
            .toList();
        // Don't process images here - only convert to base64 when saving
        status = "Posts fetched successfully";
        error = null;
      } else {
        error = "No posts found";
        status = "";
      }
    } catch (e) {
      error = "Error fetching posts: $e";
      status = "";
      AppLogger.error("Error fetching posts: $e");
    }
    notifyListeners();
  }

  // Convert image URL to base64 for a specific post (used when saving)
  Future<String?> _downloadAndConvertImageToBase64(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      }
    } catch (e) {
      AppLogger.error('Error downloading image for base64 conversion: $e');
    }
    return null;
  }

  // Save a specific post to cache (user preference)
  Future<void> savePost(PostModel post) async {
    try {
      if (!Hive.isBoxOpen(boxName)) {
        savedPostsBox = await Hive.openBox<PostModel>(boxName);
      }
      
      // Convert image to base64 ONLY when saving
      PostModel postToSave = post;
      if (post.imageUrl != null && post.imageUrl!.isNotEmpty && (post.imageBase64 == null || post.imageBase64!.isEmpty)) {
        AppLogger.debug('Converting image to base64 for offline storage: ${post.id}');
        final base64Image = await _downloadAndConvertImageToBase64(post.imageUrl!);
        if (base64Image != null) {
          postToSave = post.copyWith(imageBase64: base64Image);
        }
      }
      
      await savedPostsBox.put(postToSave.id, postToSave);
      _loadSavedPosts(); // Reload and notify
      AppLogger.debug('Post saved: ${postToSave.id}');
    } catch (e) {
      AppLogger.error('Error saving post: $e');
      error = 'Failed to save post: $e';
      notifyListeners();
    }
  }

  // Remove a saved post
  Future<void> removeSavedPost(String postId) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await savedPostsBox.delete(postId);
        _loadSavedPosts(); // Reload and notify
        AppLogger.debug('Post removed from saved: $postId');
      }
    } catch (e) {
      AppLogger.error('Error removing saved post: $e');
      error = 'Failed to remove saved post: $e';
      notifyListeners();
    }
  }

  // Get saved posts
  List<PostModel> getSavedPosts() {
    if (Hive.isBoxOpen(boxName)) {
      _loadSavedPosts();
    }
    return _savedPosts;
  }

  Future<void> createPost(BuildContext context, String content,  XFile? image, {String type = 'normal'})async{
    final accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
    if(accessToken == null || accessToken.isEmpty){
      error = "User not authenticated";
      notifyListeners();
      return;
    }
    final provider = Provider.of<ProfileProvider>(context, listen: false);
   
    final request = http.MultipartRequest('POST', Uri.parse('${ApiManager.baseUrl}/post'));
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.fields['content'] = content;
    request.fields['type'] = type;
    request.fields['place_id'] = provider.userProfile?.locationiqPlaceId ?? '';

request.fields['latitude'] = provider.userProfile?.latitude?.toString() ?? '';
    request.fields['longitude'] = provider.userProfile?.longitude?.toString() ?? '';
    request.fields['city_name'] = provider.userProfile?.cityName ?? '';
    request.fields['state_name'] = provider.userProfile?.stateName ?? '';

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }
AppLogger.debug('Creating post with content: $content, type: $type, place_id: ${provider.postalCode}');
    final response = await request.send();
    if (response.statusCode == 200) {
      final data = jsonDecode(await response.stream.bytesToString());
      if (data['success'] == true) {
        status = "Post created successfully";
        error = null;
      } else {
AppLogger.error('Failed to create post: ${data['message'] ?? "Unknown error"}');
        error = data['message'] ?? "Failed to create post";
        status = "";
      }
    } else {
AppLogger.error('HTTP error ${response.statusCode}: ${response.reasonPhrase}');
      error = "HTTP ${response.statusCode}: ${response.reasonPhrase}";
      status = "";
    }
    notifyListeners();
  }

  Future<void> fetchUserPosts(BuildContext context, {int limit = 10, int offset = 0}) async{
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if(userId == null){
      error = "User not authenticated";
      notifyListeners();
      return;
    }

    status = "Fetching user posts...";
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('posts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      _userPosts = (response as List)
          .map((json) {
            try {
              return PostModel.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              AppLogger.error('Error parsing user post: $e');
              return null;
            }
          })
          .whereType<PostModel>()
          .toList();
      // Don't process images here - only convert to base64 when saving
      status = "User posts fetched successfully";
      error = null;
    } catch (e) {
      error = "Error fetching user posts: $e";
      status = "";
      AppLogger.error("Error fetching user posts: $e");
    }
    notifyListeners();
  }



  // Toggle like for a post
  Future<void> togglePostLike(String postId) async {
    final accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      error = "User not authenticated";
      notifyListeners();
      return;
    }

    final uri = Uri.parse('${ApiManager.baseUrl}/post/$postId/like');

    try {
      final response = await http.post(uri, headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final isLiked = data['liked'] as bool;
          // Update like count in local posts
          _updatePostLikeCount(postId, isLiked);
          error = null;
        } else {
          error = data['message'] ?? "Failed to toggle like";
        }
      } else {
        error = "HTTP ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      error = "Error toggling like: $e";
    }
    notifyListeners();
  }

  void _updatePostLikeCount(String postId, bool isLiked) {
    // Update in _allPosts
    final index = _allPosts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final currentLikes = _allPosts[index].likeCount;
      _allPosts[index] = PostModel(
        id: _allPosts[index].id,
        userId: _allPosts[index].userId,
        type: _allPosts[index].type,
        content: _allPosts[index].content,
        imageUrl: _allPosts[index].imageUrl,
        imageBase64: _allPosts[index].imageBase64,
        status: _allPosts[index].status,
        placeId: _allPosts[index].placeId,
        cityName: _allPosts[index].cityName,
        stateName: _allPosts[index].stateName,
        latitude: _allPosts[index].latitude,
        longitude: _allPosts[index].longitude,
        createdAt: _allPosts[index].createdAt,
        likeCount: isLiked ? currentLikes + 1 : currentLikes - 1,
        endorsementCount: _allPosts[index].endorsementCount,
        commentCount: _allPosts[index].commentCount,
        authorName: _allPosts[index].authorName,
        authorRole: _allPosts[index].authorRole,
        isLiked: isLiked,
        isEndorsed: _allPosts[index].isEndorsed,
        // authorName: _allPosts[index].authorName,
        // authorRole: _allPosts[index].authorRole,
        // isLiked: isLiked,
        // isEndorsed: _allPosts[index].isEndorsed,
      );
    }

    // Update in _userPosts
    final userIndex = _userPosts.indexWhere((post) => post.id == postId);
    if (userIndex != -1) {
      final currentLikes = _userPosts[userIndex].likeCount;
      _userPosts[userIndex] = PostModel(
        id: _userPosts[userIndex].id,
        userId: _userPosts[userIndex].userId,
        type: _userPosts[userIndex].type,
        content: _userPosts[userIndex].content,
        imageUrl: _userPosts[userIndex].imageUrl,
        imageBase64: _userPosts[userIndex].imageBase64,
        status: _userPosts[userIndex].status,
        placeId: _userPosts[userIndex].placeId,
        cityName: _userPosts[userIndex].cityName,
        stateName: _userPosts[userIndex].stateName,
        latitude: _userPosts[userIndex].latitude,
        longitude: _userPosts[userIndex].longitude,
        createdAt: _userPosts[userIndex].createdAt,
        likeCount: isLiked ? currentLikes + 1 : currentLikes - 1,
        endorsementCount: _userPosts[userIndex].endorsementCount,
        commentCount: _userPosts[userIndex].commentCount,
        authorName: _userPosts[userIndex].authorName,
        authorRole: _userPosts[userIndex].authorRole,
        isLiked: isLiked,
        isEndorsed: _userPosts[userIndex].isEndorsed,
      );
    }
  }

  List<CommentModel> _comments = [];
  List<CommentModel> get comments => _comments;

  // Fetch comments for a specific post
  Future<void> fetchComments(String postId, {int limit = 50, int offset = 0}) async {
    status = "Fetching comments...";
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('comments')
          .select('''
            id,
            post_id,
            user_id,
            content,
            created_at,
            users!inner(name, role)
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1);

      _comments = (response as List)
          .map((json) {
            try {
              // Merge user data into comment
              final commentJson = Map<String, dynamic>.from(json);
              commentJson['author_name'] = json['users']['name'];
              commentJson['author_role'] = json['users']['role'];
              return CommentModel.fromJson(commentJson);
            } catch (e) {
              AppLogger.error('Error parsing comment: $e');
              return null;
            }
          })
          .whereType<CommentModel>()
          .toList();

      status = "Comments fetched successfully";
      error = null;
    } catch (e) {
      error = "Error fetching comments: $e";
      status = "";
      AppLogger.error("Error fetching comments: $e");
    }
    notifyListeners();
  }

  // Add a comment to a post
  Future<void> addComment(String postId, String content) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      error = "User not authenticated";
      notifyListeners();
      return;
    }

    try {
      await Supabase.instance.client
          .from('comments')
          .insert({
            'post_id': postId,
            'user_id': userId,
            'content': content,
          });

      // Update comment count in posts
      _updatePostCommentCount(postId, true);
      // Refresh comments
      await fetchComments(postId);
      error = null;
    } catch (e) {
      error = "Error adding comment: $e";
      AppLogger.error("Error adding comment: $e");
    }
    notifyListeners();
  }

  // Toggle endorsement for a post
  Future<void> togglePostEndorsement(String postId) async {
    final accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      error = "User not authenticated";
      notifyListeners();
      return;
    }

    final uri = Uri.parse('${ApiManager.baseUrl}/post/$postId/endorse');

    try {
      final response = await http.post(uri, headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final isEndorsed = data['endorsed'] as bool;
          // Update endorsement count in local posts
          _updatePostEndorsementCount(postId, isEndorsed);
          error = null;
        } else {
          error = data['message'] ?? "Failed to toggle endorsement";
        }
      } else {
        error = "HTTP ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      error = "Error toggling endorsement: $e";
    }
    notifyListeners();
  }

  void _updatePostCommentCount(String postId, bool isAdded) {
    // Update in _allPosts
    final index = _allPosts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final currentComments = _allPosts[index].commentCount;
      _allPosts[index] = PostModel(
        id: _allPosts[index].id,
        userId: _allPosts[index].userId,
        type: _allPosts[index].type,
        content: _allPosts[index].content,
        imageUrl: _allPosts[index].imageUrl,
        imageBase64: _allPosts[index].imageBase64,
        status: _allPosts[index].status,
        placeId: _allPosts[index].placeId,
        cityName: _allPosts[index].cityName,
        stateName: _allPosts[index].stateName,
        latitude: _allPosts[index].latitude,
        longitude: _allPosts[index].longitude,
        createdAt: _allPosts[index].createdAt,
        likeCount: _allPosts[index].likeCount,
        endorsementCount: _allPosts[index].endorsementCount,
        commentCount: isAdded ? currentComments + 1 : currentComments - 1,
        authorName: _allPosts[index].authorName,
        authorRole: _allPosts[index].authorRole,
        isLiked: _allPosts[index].isLiked,
        isEndorsed: _allPosts[index].isEndorsed,
      );
    }

    // Update in _userPosts
    final userIndex = _userPosts.indexWhere((post) => post.id == postId);
    if (userIndex != -1) {
      final currentComments = _userPosts[userIndex].commentCount;
      _userPosts[userIndex] = PostModel(
        id: _userPosts[userIndex].id,
        userId: _userPosts[userIndex].userId,
        type: _userPosts[userIndex].type,
        content: _userPosts[userIndex].content,
        imageUrl: _userPosts[userIndex].imageUrl,
        imageBase64: _userPosts[userIndex].imageBase64,
        status: _userPosts[userIndex].status,
        placeId: _userPosts[userIndex].placeId,
        cityName: _userPosts[userIndex].cityName,
        stateName: _userPosts[userIndex].stateName,
        latitude: _userPosts[userIndex].latitude,
        longitude: _userPosts[userIndex].longitude,
        createdAt: _userPosts[userIndex].createdAt,
        likeCount: _userPosts[userIndex].likeCount,
        endorsementCount: _userPosts[userIndex].endorsementCount,
        commentCount: isAdded ? currentComments + 1 : currentComments - 1,
        authorName: _userPosts[userIndex].authorName,
        authorRole: _userPosts[userIndex].authorRole,
        isLiked: _userPosts[userIndex].isLiked,
        isEndorsed: _userPosts[userIndex].isEndorsed,
      );
    }
  }

  void _updatePostEndorsementCount(String postId, bool isEndorsed) {
    // Update in _allPosts
    final index = _allPosts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final currentEndorsements = _allPosts[index].endorsementCount;
      _allPosts[index] = PostModel(
        id: _allPosts[index].id,
        userId: _allPosts[index].userId,
        type: _allPosts[index].type,
        content: _allPosts[index].content,
        imageUrl: _allPosts[index].imageUrl,
        imageBase64: _allPosts[index].imageBase64,
        status: _allPosts[index].status,
        placeId: _allPosts[index].placeId,
        cityName: _allPosts[index].cityName,
        stateName: _allPosts[index].stateName,
        latitude: _allPosts[index].latitude,
        longitude: _allPosts[index].longitude,
        createdAt: _allPosts[index].createdAt,
        likeCount: _allPosts[index].likeCount,
        endorsementCount: isEndorsed ? currentEndorsements + 1 : currentEndorsements - 1,
        commentCount: _allPosts[index].commentCount,
        authorName: _allPosts[index].authorName,
        authorRole: _allPosts[index].authorRole,
        isLiked: _allPosts[index].isLiked,
        isEndorsed: isEndorsed,
      );
    }

    // Update in _userPosts
    final userIndex = _userPosts.indexWhere((post) => post.id == postId);
    if (userIndex != -1) {
      final currentEndorsements = _userPosts[userIndex].endorsementCount;
      _userPosts[userIndex] = PostModel(
        id: _userPosts[userIndex].id,
        userId: _userPosts[userIndex].userId,
        type: _userPosts[userIndex].type,
        content: _userPosts[userIndex].content,
        imageUrl: _userPosts[userIndex].imageUrl,
        imageBase64: _userPosts[userIndex].imageBase64,
        status: _userPosts[userIndex].status,
        placeId: _userPosts[userIndex].placeId,
        cityName: _userPosts[userIndex].cityName,
        stateName: _userPosts[userIndex].stateName,
        latitude: _userPosts[userIndex].latitude,
        longitude: _userPosts[userIndex].longitude,
        createdAt: _userPosts[userIndex].createdAt,
        likeCount: _userPosts[userIndex].likeCount,
        endorsementCount: isEndorsed ? currentEndorsements + 1 : currentEndorsements - 1,
        commentCount: _userPosts[userIndex].commentCount,
        authorName: _userPosts[userIndex].authorName,
        authorRole: _userPosts[userIndex].authorRole,
        isLiked: _userPosts[userIndex].isLiked,
        isEndorsed: isEndorsed,
      );
    }
  }
}