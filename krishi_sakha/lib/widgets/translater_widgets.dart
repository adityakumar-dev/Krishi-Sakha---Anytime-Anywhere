// import 'package:flutter/widgets.dart';

// class TranslatorWidgets {
//   GestureDetector buildTranslationPopup
// }


  import 'package:flutter/material.dart';
import 'package:krishi_sakha/providers/translation_provider.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';
import 'package:provider/provider.dart';

Widget buildTranslationButton(String messageContent) {
    return Consumer<TranslationProvider>(
      builder: (context, translationProvider, child) {
        return SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: translationProvider.isTranslating
                ? null
                : () {
                    _handleTranslation(messageContent, translationProvider);
                  },
            icon: translationProvider.isTranslating
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        Colors.grey[600],
                      ),
                    ),
                  )
                : const Icon(Icons.translate, size: 16),
            label: Text(
              translationProvider.isTranslating ? 'Translating...' : 'Translate',
              style: const TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryWhite,
              foregroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(
                color: AppColors.primaryGreen.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTranslation(String content, TranslationProvider provider) {


    // Translate and show dialog
    provider.translateAndShowDialog(
      content,
      targetLanguage: 'hi',
    );
  }

