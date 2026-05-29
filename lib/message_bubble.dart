import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bubbleColor = isUser
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;

    final textColor = isUser
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const .symmetric(vertical: 6, horizontal: 8),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const .symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const .circular(20),
                      topRight: const .circular(20),
                      bottomLeft: .circular(isUser ? 20 : 0),
                      bottomRight: .circular(isUser ? 0 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    gradient: isUser
                        ? LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withAlpha(200),
                            ],
                            begin: .topLeft,
                            end: .bottomRight,
                          )
                        : null,
                  ),
                  child: Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
