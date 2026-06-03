import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:genui_task_list_app/main.dart';
import 'package:genui_task_list_app/message_bubble.dart';
import 'package:genui/genui.dart' hide TextPart;
import 'package:genui/genui.dart' as genui;
import 'task_display.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

sealed class ConversationItem {}

class TextItem extends ConversationItem {
  final String text;
  final bool isUser;
  TextItem({required this.text, this.isUser = false});
}

class SurfaceItem extends ConversationItem {
  final String surfaceId;
  SurfaceItem({required this.surfaceId});
}

class _MyHomePageState extends State<MyHomePage> {
  final List<ConversationItem> _items = [];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatSession _chatSession;

  //? GenUI controllers
  late final SurfaceController _controller;
  late final A2uiTransportAdapter _transport;
  late final Conversation _conversation;
  late final Catalog catalog;

  @override
  void initState() {
    super.initState();
    final model = FirebaseAI.googleAI().generativeModel(
      // model: 'gemini-3.5-flash',
      model: 'gemini-2.5-flash',
    );
    _chatSession = model.startChat();
    //* for text ui
    // _chatSession.sendMessage(Content.text(systemInstruction));

    //* Initialize the GenUI Catalog.
    // The genui package provides a default set of primitive widgets (like text
    // and basic buttons) out of the box using this class.
    // catalog = BasicCatalogItems.asCatalog();

    // The Catalog is immutable, so use copyWith to create a new version
    // that includes our custom catalog item along with the basics.
    catalog = BasicCatalogItems.asCatalog().copyWith(newItems: [taskDisplay]);

    // Create a SurfaceController to manage the state of generated surfaces.
    _controller = SurfaceController(catalogs: [catalog]);

    // Create a transport adapter that will process messages to and from the
    // agent, looking for A2UI messages.
    _transport = A2uiTransportAdapter(onSend: _sendAndReceive);

    // Link the transport and SurfaceController together in a Conversation,
    // which provides your app a unified API for interacting with the agent.
    _conversation = Conversation(
      controller: _controller,
      transport: _transport,
    );

    //* Listen to GenUI stream events to update the UI
    _conversation.events.listen((event) {
      setState(() {
        switch (event) {
          case ConversationSurfaceAdded added:
            if (added.surfaceId != taskDisplaySurfaceId) {
              _items.add(SurfaceItem(surfaceId: added.surfaceId));
              _scrollToBottom();
            }
          case ConversationSurfaceRemoved removed:
            _items.removeWhere(
              (item) =>
                  item is SurfaceItem && item.surfaceId == removed.surfaceId,
            );
          case ConversationContentReceived content:
            _items.add(TextItem(text: content.text, isUser: false));
            _scrollToBottom();
          case ConversationError error:
            debugPrint('GenUI Error: ${error.error}');
          default:
        }
      });
    });

    // Create the system prompt for the agent, which will include this app's
    // system instruction as well as the schema for the catalog.
    final promptBuilder = PromptBuilder.chat(
      catalog: catalog,
      systemPromptFragments: [systemInstruction],
    );

    // Send the prompt into the Conversation, which will subsequently route it
    // to Firebase using the transport mechanism.
    _conversation.sendRequest(
      ChatMessage.system(promptBuilder.systemPromptJoined()),
    );
  }

  //* for GenUI
  Future<void> _sendAndReceive(ChatMessage msg) async {
    final buffer = StringBuffer();

    // Reconstruct the message part fragments
    for (final part in msg.parts) {
      if (part.isUiInteractionPart) {
        buffer.write(part.asUiInteractionPart!.interaction);
      } else if (part is genui.TextPart) {
        buffer.write(part.text);
      }
    }
    if (buffer.isEmpty) return;
    final text = buffer.toString();

    // Send the string to Firebase AI Logic.
    final response = await _chatSession.sendMessage(Content.text(text));

    if (response.text?.isNotEmpty ?? false) {
      // Feed the response back into GenUI's transportation layer
      _transport.addChunk(response.text!);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _addMessage() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();

    setState(() {
      _items.add(TextItem(text: text, isUser: true));
    });

    _scrollToBottom();

    //* text based UI
    // final response = await _chatSession.sendMessage(Content.text(text));

    // if (response.text?.isNotEmpty ?? false) {
    //   setState(() {
    //     _items.add(TextItem(text: response.text!, isUser: false));
    //   });
    //   _scrollToBottom();
    // }

    //* GenUI
    // Send the user's input through GenUI instead of directly to Firebase.
    await _conversation.sendRequest(ChatMessage.user(text));
  }

  void _toggleTheme() {
    final current = themeModeNotifier.value;
    if (current == ThemeMode.dark) {
      themeModeNotifier.value = ThemeMode.light;
    } else {
      themeModeNotifier.value = ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == .dark;

    return Scaffold(
      body: Column(
        children: [
          // ── Custom Header ──────────────────────────────────────
          _AppHeader(isDark: isDark, onToggleTheme: _toggleTheme, cs: cs),

          // ── Loading bar ────────────────────────────────────────
          ValueListenableBuilder(
            valueListenable: _conversation.state,
            builder: (context, state, _) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: state.isWaiting ? 3 : 0,
                child: state.isWaiting
                    ? LinearProgressIndicator(
                        backgroundColor: cs.primaryContainer,
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),

          // ── Task surface panel ────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            child: _TaskPanel(controller: _controller, cs: cs, isDark: isDark),
          ),

          // ── Divider ───────────────────────────────────────────
          Divider(height: 1, color: cs.outlineVariant.withAlpha(80)),

          // ── Chat messages ─────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const .symmetric(vertical: 12, horizontal: 8),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return switch (item) {
                  TextItem() => MessageBubble(
                    text: item.text,
                    isUser: item.isUser,
                  ),
                  SurfaceItem() => Padding(
                    padding: const .symmetric(vertical: 6),
                    child: Surface(
                      surfaceContext: _controller.contextFor(item.surfaceId),
                    ),
                  ),
                };
              },
            ),
          ),

          // ── Input bar ─────────────────────────────────────────
          _InputBar(
            controller: _textController,
            conversation: _conversation,
            onSend: _addMessage,
            cs: cs,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Header
// ─────────────────────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  const _AppHeader({
    required this.isDark,
    required this.onToggleTheme,
    required this.cs,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: cs.surface,
        padding: const .fromLTRB(20, 12, 12, 12),
        child: Row(
          children: [
            // Logo / icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.tertiary],
                  begin: .topLeft,
                  end: .bottomRight,
                ),
                borderRadius: .circular(10),
              ),
              child: Icon(Icons.check_rounded, color: cs.onPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Text(
                    'Just Today',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: .w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'AI Task Planner',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            // Theme toggle button
            IconButton(
              onPressed: onToggleTheme,
              tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
              style: IconButton.styleFrom(
                backgroundColor: cs.primaryContainer.withAlpha(120),
                foregroundColor: cs.primary,
              ),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  key: ValueKey(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task Panel
// ─────────────────────────────────────────────────────────────────────────────

class _TaskPanel extends StatelessWidget {
  const _TaskPanel({
    required this.controller,
    required this.cs,
    required this.isDark,
  });

  final SurfaceController controller;
  final ColorScheme cs;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerLow
            : cs.primaryContainer.withAlpha(60),
      ),
      child: SingleChildScrollView(
        padding: const .symmetric(horizontal: 16, vertical: 8),
        child: Surface(
          surfaceContext: controller.contextFor(taskDisplaySurfaceId),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input Bar
// ─────────────────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.conversation,
    required this.onSend,
    required this.cs,
    required this.isDark,
  });

  final TextEditingController controller;
  final Conversation conversation;
  final VoidCallback onSend;
  final ColorScheme cs;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: cs.surface,
        padding: const .fromLTRB(12, 8, 12, 12),
        child: ValueListenableBuilder(
          valueListenable: conversation.state,
          builder: (context, state, _) {
            final waiting = state.isWaiting;
            return Row(
              crossAxisAlignment: .end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: waiting ? null : (_) => onSend(),
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: .send,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: waiting
                          ? 'AI is thinking…'
                          : 'Tell me about today\'s tasks…',
                      filled: true,
                      fillColor: isDark
                          ? cs.surfaceContainerHighest.withAlpha(100)
                          : cs.surfaceContainerHighest.withAlpha(140),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: waiting ? 0.5 : 1.0,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: FilledButton(
                      onPressed: waiting ? null : onSend,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: .zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: .circular(16),
                        ),
                      ),
                      child: waiting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 22),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// System Instruction
// ─────────────────────────────────────────────────────────────────────────────

const systemInstruction =
    '''
  ## PERSONA
  You are an expert task planner.

  ## GOAL
  Work with me to produce a list of tasks that I should do today, and then track
  the completion status of each one.

  ## RULES
  Talk with me only about tasks that I should do today.
  Do not engage in conversation about any other topic.
  Do not offer suggestions unless I ask for them.
  Do not offer encouragement unless I ask for it.
  Do not offer advice unless I ask for it.
  Do not offer opinions unless I ask for them.

  ## PROCESS
  ### Planning
  *   Ask me for information about tasks that I should do today.
  *   Synthesize a list of tasks from that information.
  *   Ask clarifying questions if you need to.
  *   When you have a list of tasks that you think I should do today, present it
    to me for review.
  *   Respond to my suggestions for changes, if I have any, until I accept the
    list.

  ### Tracking
  *   Once the list is accepted, ask me to let you know when individual tasks are
    complete.
  *   If I tell you a task is complete, mark it as complete.
  *   Once all tasks are complete, send a message acknowledging that, and then
    end the conversation.

  ## USER INTERFACE
    *   To display the list of tasks create one and only one instance of the
    TaskDisplay catalog item. Use "$taskDisplaySurfaceId" as its surface ID.
  *   Update $taskDisplaySurfaceId as necessary when the list changes.
  *   $taskDisplaySurfaceId must include a button for each task that I can use
    to mark it complete. When I use that button to mark a task complete, it
    should send you a message indicating what I've done.
  *   Avoid repeating the same information in a single message.
  *   When responding with text, rather than A2UI messages, be brief.
''';
