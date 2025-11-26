import 'package:flutter/material.dart';
import 'package:krishi_sakha/providers/void_provider.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';
import 'package:provider/provider.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  @override
  void dispose() {
    super.dispose();
    try {
      // Provider.of<VoiceProvider>(context, listen: false).cancelSpeaking();
      Provider.of<VoiceProvider>(context, listen: false).dispose();

    } catch (e) {
      debugPrint('Error canceling speaking on dispose: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F5E8),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
              onPressed: () {
                if (provider.isListening || provider.isSpeaking || provider.isStreaming) {
                  // Show confirmation dialog if operation is in progress
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Stop voice chat?'),
                      content: const Text('This will cancel the current operation.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.cancelSpeaking();
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          child: const Text('Stop', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            title: const Text("Voice Chat", style: TextStyle(color: AppColors.primaryBlack)),
            elevation: 0,
          ),
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status bar at top
                _buildStatusBar(provider),
                
                // Main content area
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Error state
                            if (provider.hasError)
                              _buildErrorWidget(provider)
                            // Initialization state
                            else if (!provider.isInitialized)
                              _buildInitializingWidget()
                            // Main content based on state
                            else
                              _buildStateWidget(provider),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Mic button and controls at bottom
                _buildControlsSection(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  // Status bar showing current operation
  Widget _buildStatusBar(VoiceProvider provider) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info_outline;

    switch (provider.currentState) {
      case VoiceState.idle:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case VoiceState.listening:
        statusColor = Colors.orange;
        statusIcon = Icons.mic;
        break;
      case VoiceState.processing:
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_empty;
        break;
      case VoiceState.streaming:
        statusColor = Colors.blue;
        statusIcon = Icons.cloud_download;
        break;
      case VoiceState.speaking:
        statusColor = Colors.green;
        statusIcon = Icons.volume_up;
        break;
      case VoiceState.error:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: statusColor, width: 2)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStateLabel(provider.currentState),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.statusMessage,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStateLabel(VoiceState state) {
    switch (state) {
      case VoiceState.idle:
        return "READY";
      case VoiceState.listening:
        return "LISTENING";
      case VoiceState.processing:
        return "PROCESSING";
      case VoiceState.streaming:
        return "STREAMING";
      case VoiceState.speaking:
        return "SPEAKING";
      case VoiceState.error:
        return "ERROR";
    }
  }

  // Error widget
  Widget _buildErrorWidget(VoiceProvider provider) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            border: Border.all(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                "Oops! Something went wrong",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      provider.clearError();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Try Again"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Initializing widget
  Widget _buildInitializingWidget() {
    return const Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            color: Colors.black,
            strokeWidth: 3,
          ),
        ),
        SizedBox(height: 24),
        Text(
          "Initializing speech recognition...",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          "Please wait",
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Main state widget
  Widget _buildStateWidget(VoiceProvider provider) {
    return Column(
      children: [
        // Large status indicator
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStateColor(provider.currentState).withValues(alpha: 0.1),
            border: Border.all(
              color: _getStateColor(provider.currentState),
              width: 3,
            ),
          ),
          child: Center(
            child: Icon(
              _getStateIcon(provider.currentState),
              size: 56,
              color: _getStateColor(provider.currentState),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Recognized text or response
        if (provider.isListening)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              border: Border.all(color: Colors.orange, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  "Recognized:",
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.recognizedWord.isEmpty
                      ? "Listening... (speak now)"
                      : provider.recognizedWord,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (provider.isStreaming || provider.isSpeaking)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              border: Border.all(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  "Response:",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (provider.lastResponse.isEmpty)
                  const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.green),
                    ),
                  )
                else
                  Text(
                    provider.lastResponse,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          )
        else
          Text(
            "Hold and speak to start",
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Color _getStateColor(VoiceState state) {
    switch (state) {
      case VoiceState.idle:
        return Colors.green;
      case VoiceState.listening:
        return Colors.orange;
      case VoiceState.processing:
        return Colors.blue;
      case VoiceState.streaming:
        return Colors.blue;
      case VoiceState.speaking:
        return Colors.green;
      case VoiceState.error:
        return Colors.red;
    }
  }

  IconData _getStateIcon(VoiceState state) {
    switch (state) {
      case VoiceState.idle:
        return Icons.check_circle;
      case VoiceState.listening:
        return Icons.mic;
      case VoiceState.processing:
        return Icons.hourglass_empty;
      case VoiceState.streaming:
        return Icons.cloud_download;
      case VoiceState.speaking:
        return Icons.volume_up;
      case VoiceState.error:
        return Icons.error;
    }
  }

  // Controls section with mic button
  Widget _buildControlsSection(VoiceProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          // Help text
          if (provider.isInitialized && !provider.hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                provider.currentState == VoiceState.idle
                    ? "👇 Press and hold the button to start listening"
                    : provider.currentState == VoiceState.listening
                        ? "🎤 Speak clearly and release to send"
                        : "⏳ Processing your request...",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          // Mic button
          if (provider.isInitialized && !provider.hasError)
            MicButton()
          else if (provider.hasError)
            ElevatedButton.icon(
              onPressed: () {
                provider.clearError();
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          // Cancel button if operation in progress
          if (provider.isListening || provider.isStreaming || provider.isSpeaking)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton.icon(
                onPressed: provider.cancelSpeaking,
                icon: const Icon(Icons.stop_circle, color: Colors.red),
                label: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MicButton extends StatefulWidget {
  const MicButton({super.key});

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onLongPress: provider.isInitialized && !provider.hasError && !provider.isListening
              ? () => provider.startListening()
              : null,
          onLongPressEnd: provider.isInitialized && !provider.hasError
              ? (details) => provider.stopListening()
              : null,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              double baseSize = 80;

              double size = provider.isListening
                  ? baseSize * _pulseAnimation.value + 40
                  : baseSize * _pulseAnimation.value;

              List<BoxShadow> shadow = provider.isListening
                  ? [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.6),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ]
                  : [];

              return AnimatedContainer(
                width: size,
                height: size,
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: provider.hasError
                      ? Colors.grey
                      : provider.isListening
                          ? Colors.redAccent
                          : provider.isInitialized
                              ? Colors.greenAccent
                              : Colors.grey,
                  shape: BoxShape.circle,
                  boxShadow: shadow,
                ),
                child: Center(
                  child: Icon(
                    Icons.mic,
                    color: Colors.black,
                    size: provider.isListening ? 44 : 32,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
