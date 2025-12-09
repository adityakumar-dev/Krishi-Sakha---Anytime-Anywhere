import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krishi_sakha/l10n/app_localizations.dart';
import 'package:krishi_sakha/models/mandi_price_model.dart';
import 'package:krishi_sakha/providers/agri_chat_provider.dart';
import 'package:krishi_sakha/providers/profile_provider.dart';
import 'package:krishi_sakha/providers/unified_translation_provider.dart';
import 'package:krishi_sakha/utils/ui/markdown_helper.dart';
import 'package:krishi_sakha/widgets/translater_widgets.dart';
import 'package:krishi_sakha/widgets/url_modal.dart';
import 'package:krishi_sakha/widgets/youtube_widget.dart';
import 'package:provider/provider.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';

class ChatServerScreen extends StatefulWidget {
  const ChatServerScreen({super.key});

  @override
  State<ChatServerScreen> createState() => _ChatServerScreenState();
}

class _ChatServerScreenState extends State<ChatServerScreen> {
  int? _lastLoadedConversationId;
  Timer? _scrollIdleTimer;
  final Map<String, GlobalKey> _messageKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
      _setupScrollListener();
    });
  }

  void _setupScrollListener() {
    final provider = Provider.of<AgriChatProvider>(context, listen: false);
    provider.scrollController.addListener(_onScroll);

    // Listen for new messages to trigger auto-translation
    provider.addListener(_onProviderUpdate);
  }

  void _onProviderUpdate() {
    final chatProvider = Provider.of<AgriChatProvider>(context, listen: false);

    // Check if a new assistant message was just added
    if (chatProvider.autoTranslateEnabled &&
        chatProvider.messages.isNotEmpty &&
        !chatProvider.isSending) {
      final lastMessage = chatProvider.messages.last;

      // If it's an assistant message and not yet translated, translate it
      if (lastMessage.sender == 'assistant' &&
          chatProvider.getTranslatedMessage(lastMessage.id) == null &&
          !chatProvider.isTranslating(lastMessage.id)) {
        _translateMessage(lastMessage.id, lastMessage.message);
      }
    }
  }

  void _onScroll() {
    // Reset timer on every scroll
    _scrollIdleTimer?.cancel();

    // Start timer to detect when scrolling stops
    _scrollIdleTimer = Timer(const Duration(milliseconds: 500), () {
      _onScrollStopped();
    });
  }

  void _onScrollStopped() {
    // Check if auto-translation is enabled
    final chatProvider = Provider.of<AgriChatProvider>(context, listen: false);
    if (!chatProvider.autoTranslateEnabled) return;

    // Find visible assistant messages and translate them
    _translateVisibleMessages();
  }

  Future<void> _translateMessage(String messageId, String messageText) async {
    final chatProvider = Provider.of<AgriChatProvider>(context, listen: false);
    final translationProvider = Provider.of<UnifiedTranslationProvider>(
      context,
      listen: false,
    );

    chatProvider.markAsTranslating(messageId);

    try {
      final result = await translationProvider.translateText(
        messageText,
        targetLanguage: chatProvider.autoTranslateLanguage,
        addDelay: false, // No delay for immediate translation
      );

      if (result.success && mounted) {
        chatProvider.setTranslatedMessage(messageId, result.translation);
      } else {
        // Clear translating state if translation failed
        chatProvider.setTranslatedMessage(messageId, messageText);
      }
    } catch (e) {
      print('Translation error: $e');
      // Clear translating state on error
      if (mounted) {
        chatProvider.setTranslatedMessage(messageId, messageText);
      }
    }
  }

  void _translateVisibleMessages() async {
    final chatProvider = Provider.of<AgriChatProvider>(context, listen: false);
    final translationProvider = Provider.of<UnifiedTranslationProvider>(
      context,
      listen: false,
    );

    if (!chatProvider.scrollController.hasClients) return;

    // Get visible messages
    for (final message in chatProvider.messages) {
      if (message.sender != 'assistant') continue;
      if (chatProvider.getTranslatedMessage(message.id) != null) continue;
      if (chatProvider.isTranslating(message.id)) continue;

      // Check if message is visible
      final key = _messageKeys[message.id];
      if (key != null && _isWidgetVisible(key)) {
        // Translate this message
        chatProvider.markAsTranslating(message.id);

        try {
          final result = await translationProvider.translateText(
            message.message,
            targetLanguage: chatProvider.autoTranslateLanguage,
            addDelay: true,
          );

          if (result.success && mounted) {
            chatProvider.setTranslatedMessage(message.id, result.translation);
          } else {
            // Clear translating state if translation failed
            chatProvider.setTranslatedMessage(message.id, message.message);
          }
        } catch (e) {
          print('Translation error: $e');
          // Clear translating state on error
          if (mounted) {
            chatProvider.setTranslatedMessage(message.id, message.message);
          }
        }
      }
    }
  }

  bool _isWidgetVisible(GlobalKey key) {
    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;

    // Check if widget is in viewport
    return position.dy + size.height > 0 && position.dy < screenHeight;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if conversation ID changed and reload messages if needed
    final provider = Provider.of<AgriChatProvider>(context, listen: false);
    if (provider.actualConversationId != _lastLoadedConversationId &&
        provider.actualConversationId != -1) {
      _lastLoadedConversationId = provider.actualConversationId;
      provider.fetchMessages(context);
    }
  }

  void _initializeChat() {
    final provider = Provider.of<AgriChatProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    // Set user preferences from profile for chat context
    final stateName = profileProvider.userProfile?.preferedStateName;
    final stationId = profileProvider.userProfile?.preferredWeatherStationId;

    if (stateName != null || stationId != null) {
      // Match state name with market price model state list
      final matchedState = stateName != null
          ? _findMatchingState(stateName)
          : null;
      provider.setUserPreferences(state: matchedState, stationId: stationId);
    }

    // Fetch messages if we have a conversation ID
    if (provider.actualConversationId != -1) {
      _lastLoadedConversationId = provider.actualConversationId;
      provider.fetchMessages(context);
    }

    provider.messageController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  String? _findMatchingState(String stateName) {
    // Normalize the state name from profile
    final normalizedInput = stateName.toUpperCase().trim();

    // Try exact match first
    for (final state in MandiPriceModel.allStatesMandiPrice) {
      if (state.toUpperCase() == normalizedInput) {
        return state;
      }
    }

    // Try partial match (contains)
    for (final state in MandiPriceModel.allStatesMandiPrice) {
      if (state.toUpperCase().contains(normalizedInput) ||
          normalizedInput.contains(state.toUpperCase())) {
        return state;
      }
    }

    // Try matching without "AND" or special characters
    final simplifiedInput = normalizedInput
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll('AND', '')
        .trim();
    for (final state in MandiPriceModel.allStatesMandiPrice) {
      final simplifiedState = state
          .toUpperCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll('AND', '')
          .trim();
      if (simplifiedState.contains(simplifiedInput) ||
          simplifiedInput.contains(simplifiedState)) {
        return state;
      }
    }

    return null;
  }

  @override
  void dispose() {
    _scrollIdleTimer?.cancel();
    final provider = Provider.of<AgriChatProvider>(context, listen: false);
    provider.scrollController.removeListener(_onScroll);
    provider.removeListener(_onProviderUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5E8),
        foregroundColor: AppColors.primaryBlack,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<AgriChatProvider>(
              builder: (context, provider, child) {
                return Text(
                  provider.actualConversationTitle.isNotEmpty
                      ? provider.actualConversationTitle
                      : 'Agricultural Chat',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                );
              },
            ),
            Consumer<AgriChatProvider>(
              builder: (context, provider, child) {
                String status = 'Ready';
                if (provider.isLoading) {
                  status = 'Loading...';
                } else if (provider.isSending) {
                  status = provider.status.isNotEmpty
                      ? provider.status
                      : 'Generating response...';
                } else if (provider.error != null) {
                  status = 'Error occurred';
                }

                return Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryBlack.withOpacity(0.6),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          // Auto-translate toggle
          Consumer<AgriChatProvider>(
            builder: (context, chatProvider, child) {
              return IconButton(
                icon: Icon(
                  chatProvider.autoTranslateEnabled
                      ? Icons.translate
                      : Icons.translate_outlined,
                  color: chatProvider.autoTranslateEnabled
                      ? AppColors.primaryGreen
                      : AppColors.primaryBlack,
                ),
                tooltip: 'Auto Translate',
                onPressed: () => _showTranslationSettings(context),
              );
            },
          ),
          IconButton(
            onPressed: () async {
              // Use FilePicker for desktop (Linux/Windows/macOS) compatibility.
              // image_picker is not supported on Linux; FilePicker works across desktop and mobile.
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                allowMultiple: false,
              );

              if (!mounted) return;

              if (result != null && result.files.single.path != null) {
                final path = result.files.single.path!;
                // Convert to XFile for provider compatibility
                final xFile = XFile(path);
                context.read<AgriChatProvider>().setImage(xFile);

                ScaffoldMessenger.of(context).showMaterialBanner(
                  MaterialBanner(
                    content: const Text("Image Selected"),
                    actions: [
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentMaterialBanner();
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                );
              } else {
                // Optional: give feedback when user cancels or selection fails
                Fluttertoast.showToast(msg: 'No image selected');
              }
            },
            icon: Icon(Icons.attach_file_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer<AgriChatProvider>(
            builder: (context, provider, child) {
              if (provider.error != null) {
                return _buildErrorBanner(provider);
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(child: _buildMessageList()),
          _buildInputArea(),
        ],
      ),
      floatingActionButton: Consumer<AgriChatProvider>(
        builder: (context, provider, child) {
          if (provider.showScrollToBottom) {
            return FloatingActionButton.small(
              onPressed: provider.scrollToBottomManually,
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.primaryBlack,
              child: const Icon(Icons.keyboard_arrow_down),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showTranslationSettings(BuildContext context) {
    final chatProvider = Provider.of<AgriChatProvider>(context, listen: false);
    final translationProvider = Provider.of<UnifiedTranslationProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.translate, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Auto Translation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text('Enable Auto Translation'),
              subtitle: Text('Automatically translate assistant messages'),
              value: chatProvider.autoTranslateEnabled,
              activeColor: AppColors.primaryGreen,
              onChanged: (value) {
                chatProvider.toggleAutoTranslate(value);
                if (value) {
                  Fluttertoast.showToast(msg: 'Auto translation enabled');
                }
              },
            ),
            SizedBox(height: 16),
            Text(
              'Target Language',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: chatProvider.autoTranslateLanguage,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                DropdownMenuItem(value: 'hi', child: Text('हिंदी (Hindi)')),
                DropdownMenuItem(
                  value: 'ml',
                  child: Text('മലയാളം (Malayalam)'),
                ),
                DropdownMenuItem(value: 'bn', child: Text('বাংলা (Bengali)')),
                DropdownMenuItem(value: 'ta', child: Text('தமிழ் (Tamil)')),
                DropdownMenuItem(value: 'te', child: Text('తెలుగు (Telugu)')),
                DropdownMenuItem(value: 'mr', child: Text('मराठी (Marathi)')),
                DropdownMenuItem(
                  value: 'gu',
                  child: Text('ગુજરાતી (Gujarati)'),
                ),
                DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ (Kannada)')),
                DropdownMenuItem(value: 'pa', child: Text('ਪੰਜਾਬੀ (Punjabi)')),
                DropdownMenuItem(value: 'ur', child: Text('اردو (Urdu)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  chatProvider.setAutoTranslateLanguage(value);
                  translationProvider.setSelectedLanguage(value);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Done',
              style: TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(AgriChatProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.error!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () => provider.clearError(),
            child: const Text('Dismiss', style: TextStyle(color: Colors.red)),
          ),
          if (provider.messages.isNotEmpty)
            TextButton(
              onPressed: () => provider.retryLastMessage(),
              child: const Text('Retry', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Consumer<AgriChatProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        final hasMessages = provider.messages.isNotEmpty;
        if (!hasMessages && !provider.isSending) {
          return _buildEmptyState();
        }

        final itemCount =
            provider.messages.length + (provider.isSending ? 1 : 0);
        return ListView.builder(
          controller: provider.scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == provider.messages.length && provider.isSending) {
              return _buildStreamingMessage(
                provider.lastStreamingResponse,
                provider.currentMetadata,
              );
            }

            final message = provider.messages[index];
            return _buildMessageBubble(message);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              // color: AppColors.primaryBlack,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 48,
                  color: Colors.grey.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.startConversation,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.askAnything,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingMessage(
    String streamingText,
    Map<String, dynamic> metadata,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  border: Border.all(color: AppColors.primaryGreen, width: 1.5),
                ),
                child: Icon(
                  Icons.smart_toy,
                  size: 18,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (streamingText.isEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Thinking…',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        )
                      else
                        buildMarkdownText(streamingText),
                      if (metadata.isNotEmpty)
                        ..._buildMetadataWidgets(metadata),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.sender == 'user';

    // Store message key for visibility detection
    if (!isUser && !_messageKeys.containsKey(message.id)) {
      _messageKeys[message.id] = GlobalKey();
    }

    return Consumer<AgriChatProvider>(
      builder: (context, chatProvider, child) {
        final translatedText = !isUser
            ? chatProvider.getTranslatedMessage(message.id)
            : null;
        final isTranslating = !isUser
            ? chatProvider.isTranslating(message.id)
            : false;
        final showTranslation =
            !isUser &&
            chatProvider.autoTranslateEnabled &&
            translatedText != null;

        return Container(
          key: !isUser ? _messageKeys[message.id] : null,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUser ? AppColors.primaryGreen : Colors.white,
                      border: isUser
                          ? null
                          : Border.all(
                              color: AppColors.primaryGreen,
                              width: 1.5,
                            ),
                    ),
                    child: Icon(
                      isUser ? Icons.person : Icons.smart_toy,
                      size: 18,
                      color: isUser
                          ? AppColors.primaryBlack
                          : AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.primaryGreen : Colors.white,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        border: isUser
                            ? null
                            : Border.all(
                                color: Colors.grey.withOpacity(0.2),
                                width: 1,
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: isUser
                                ? AppColors.primaryGreen.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Show translation indicator
                          if (showTranslation)
                            Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.translate,
                                    size: 14,
                                    color: AppColors.primaryGreen,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Translated',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Show translated text or original text
                          if (isTranslating)
                            Row(
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Translating...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          if (showTranslation)
                            Text(
                              translatedText,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            )
                          else if (!isTranslating)
                            buildMarkdownText(message.message),
                          if (!isUser && !showTranslation)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                left: 8.0,
                              ),
                              child: buildTranslationButton(message.message),
                            ),
                          if (!isUser && message.metadata.isNotEmpty)
                            ..._buildMetadataWidgets(message.metadata),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildMetadataWidgets(Map<String, dynamic> metadata) {
    List<Widget> widgets = [];

    // Handle URLs
    if (metadata.containsKey('urls') && metadata['urls'] is List) {
      final urls = metadata['urls'] as List;
      if (urls.isNotEmpty) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(
          UrlDropDown(urls: urls.map((url) => url.toString()).toList()),
        );
      }
    }

    // Handle YouTube videos
    if (metadata.containsKey('youtube') && metadata['youtube'] is List) {
      final videos = metadata['youtube'] as List;
      if (videos.isNotEmpty) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.play_circle_fill,
                      size: 16,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'YouTube Videos',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...videos
                    .take(3)
                    .map((video) => youTubeVideoWidget(context, video)),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildInputArea() {
    return Consumer<AgriChatProvider>(
      builder: (context, provider, child) {
        final canSend = _canSendMessage(provider);
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.primaryWhite,
            border: const Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: provider.messageController,
                  style: const TextStyle(color: Colors.black),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Ask about farming, crops, weather...',
                    hintStyle: const TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: canSend
                      ? (_) => provider.sendMessage(context)
                      : null,
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: canSend ? AppColors.primaryGreen : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: canSend
                      ? () => provider.sendMessage(context)
                      : null,
                  icon: const Icon(Icons.send),
                  color: AppColors.primaryBlack,
                  tooltip: 'Send message',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _canSendMessage(AgriChatProvider provider) {
    return provider.canSend;
  }
}
