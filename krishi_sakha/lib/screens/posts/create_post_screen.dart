import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krishi_sakha/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:krishi_sakha/providers/post_manage_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  final TextEditingController _descController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600);
    if (picked != null) {
      setState(() {
        _image = picked;
      });
    }
  }

  Future<void> _submit() async {
    final content = _descController.text.trim();
    if (content.isEmpty && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a description or an image')));
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = Provider.of<PostManageProvider>(context, listen: false);
    await provider.createPost(context, content, _image, type: 'normal');

    setState(() => _isSubmitting = false);

    if (provider.error != null && provider.error!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error!)));
      return;
    }

    // Success
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post submitted for verification')));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 240,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.3), style: BorderStyle.solid, width: 2),
                        ),
                        child: _image == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, size: 48, color: Colors.green[700]),
                                  const SizedBox(height: 12),
                                  Text('Tap to add a photo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                 ElevatedButton(
                                    onPressed: _pickImage,
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.green[800], elevation: 0, side: BorderSide(color: Colors.green.shade100)),
                                    child: const Text('Add Photo'),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(_image!.path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: TextField(
                        controller: _descController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText: 'Describe your observation or ask a question...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        'Your post will be reviewed by government staff before being published.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green[700]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Post your thought...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
