import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sakha/apis/api_manager.dart';
import 'package:krishi_sakha/providers/profile_provider.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class CreateExpertPostScreen extends StatefulWidget {
  const CreateExpertPostScreen({super.key});

  @override
  State<CreateExpertPostScreen> createState() => _CreateExpertPostScreenState();
}

class _CreateExpertPostScreenState extends State<CreateExpertPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  String _selectedPostType = 'expert';
  File? _selectedImage;
  bool _isPosting = false;

  final List<Map<String, String>> _postTypes = [
    {'value': 'expert', 'label': 'Expert Advice', 'icon': '👨‍🌾'},
    {'value': 'success', 'label': 'Success Story', 'icon': '🎉'},
    {'value': 'bulletin', 'label': 'Bulletin/Notice', 'icon': '📢'},
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error picking image: $e');
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter post content');
      return;
    }

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final userProfile = profileProvider.userProfile;

    if (userProfile == null) {
      Fluttertoast.showToast(msg: 'User profile not found');
      return;
    }

    setState(() => _isPosting = true);

    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiManager.baseUrl}${ApiManager.createSpecialPostUrl}'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['type'] = _selectedPostType;
      request.fields['content'] = _contentController.text.trim();
      request.fields['place_id'] = userProfile.locationiqPlaceId ?? '';
      request.fields['city_name'] = userProfile.cityName ?? '';
      request.fields['state_name'] = userProfile.stateName ?? '';
      request.fields['latitude'] = userProfile.latitude?.toString() ?? '0';
      request.fields['longitude'] = userProfile.longitude?.toString() ?? '0';

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _selectedImage!.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        Fluttertoast.showToast(
          msg: responseData['message'] ?? 'Post created successfully!',
          backgroundColor: AppColors.primaryGreen,
        );
        Navigator.pop(context, true);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to create post');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Create Special Post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Type Selection
            const Text(
              'Post Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: _postTypes.map((type) {
                  final isSelected = _selectedPostType == type['value'];
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedPostType = type['value']!);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: type == _postTypes.last
                              ? BorderSide.none
                              : BorderSide(color: Colors.grey[200]!),
                        ),
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppColors.primaryGreen.withOpacity(0.1),
                                  AppColors.primaryGreen.withOpacity(0.05),
                                ],
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(
                            type['icon']!,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              type['label']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primaryGreen
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primaryGreen,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Content Input
            const Text(
              'Post Content',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText:
                      'Share your expertise, success story, or bulletin...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Image Picker
            const Text(
              'Add Image (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => setState(() => _selectedImage = null),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add image',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Post Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isPosting ? null : _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isPosting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Post',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
