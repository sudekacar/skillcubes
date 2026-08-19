import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_ext.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_header.dart';
import 'emma_persona.dart';

class _ChatBubble {
  const _ChatBubble({required this.fromEmma, required this.text});

  final bool fromEmma;
  final String text;
}

/// Conversational screen with Emma, the cognitive coach.
class EmmaChatScreen extends StatefulWidget {
  const EmmaChatScreen({super.key});

  @override
  State<EmmaChatScreen> createState() => _EmmaChatScreenState();
}

class _EmmaChatScreenState extends State<EmmaChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_ChatBubble>[];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatBubble(fromEmma: true, text: context.trRead('emma_greeting')),
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    final api = context.read<ApiService>();
    final loginHint = context.trRead('emma_login_hint');
    final errorHint = context.trRead('emma_error');
    final connectionErrorHint = context.trRead('emma_connection_error');

    await AppHaptics.light();
    if (!mounted) return;

    setState(() {
      _messages.add(_ChatBubble(fromEmma: false, text: text));
      _sending = true;
      _controller.clear();
    });
    _jumpToEnd();

    String reply;
    if (!api.isAuthenticated) {
      reply = loginHint;
    } else {
      try {
        final history = _messages
            .sublist(0, _messages.length - 1)
            .map(
              (m) => {
                'role': m.fromEmma ? 'assistant' : 'user',
                'content': m.text,
              },
            )
            .toList();
        reply = await PremiumService(api).chatWithEmma(
          message: text,
          history: history,
        );
        if (reply.trim().isEmpty) {
          reply = EmmaPersona.greetingTr;
        }
      } on ApiException catch (e) {
        final isNetwork = e.statusCode == 0 ||
            e.message.contains('Connection') ||
            e.message.contains('Timeout') ||
            e.message.contains('fetch');
        reply = isNetwork
            ? connectionErrorHint
            : '${EmmaPersona.name}: ${e.message}';
      } catch (_) {
        reply = errorHint;
      }
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatBubble(fromEmma: true, text: reply));
      _sending = false;
    });
    _jumpToEnd();
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppHeader(title: context.tr('emma_chat_title')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        context.tr('emma_typing'),
                        style: TextStyle(
                          color: AppColors.muted(context),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }
                final msg = _messages[index];
                return Align(
                  alignment:
                      msg.fromEmma ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: msg.fromEmma
                          ? scheme.surfaceContainerHighest
                          : scheme.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(height: 1.4, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: context.tr('emma_input_hint'),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
