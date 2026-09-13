import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/storage/session_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/ai_chat_message.dart';
import '../../data/services/ai_chat_service.dart';
import '../../data/storage/ai_chat_storage.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> with WidgetsBindingObserver {
  final _sessionManager = SessionManager();
  final _chatService = AiChatService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  List<AiChatMessage> _messages = [];
  bool _isLoading = false;
  String _sessionId = '';
  Timer? _processingTimer;
  bool _showProcessingBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _processingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSessionExpiration();
    }
  }

  Future<void> _checkSessionExpiration() async {
    final user = _sessionManager.getUser();
    final nim = user?.nim ?? 'guest';
    final expired = await AiChatStorage.isSessionExpired(nim);
    if (expired && mounted) {
      debugPrint('[AiChatPage] Session expired (>24h since last chat), resetting chat.');
      _initializeChat();
    }
  }

  Future<void> _initializeChat() async {
    final user = _sessionManager.getUser();
    final nim = user?.nim ?? 'guest';

    // Clean up expired sessions in background
    AiChatStorage.cleanExpiredSessions();

    // Get active session ID (persists if within 24h of last chat, otherwise fresh)
    _sessionId = await AiChatStorage.getOrInitActiveSessionId(nim);

    // Load saved messages
    final savedMessages = await AiChatStorage.loadMessages(_sessionId);

    if (mounted) {
      setState(() {
        _messages = savedMessages;
      });

      // If empty, create initial greeting
      if (_messages.isEmpty) {
        _createInitialGreeting();
      } else {
        _scrollToBottom();
      }
    }
  }

  void _createInitialGreeting() {
    final user = _sessionManager.getUser();
    final firstName = _firstWord(user?.nama);
    final l10n = AppLocalizations.of(context);

    final greetingText = l10n != null
        ? l10n.aiChatGreeting(firstName)
        : 'Halo $firstName 👋, ada yang bisa saya bantu?';

    final greetingMessage = AiChatMessage(
      id: 'greeting_${DateTime.now().millisecondsSinceEpoch}',
      text: greetingText,
      isUser: false,
      timestamp: DateTime.now(),
      sessionId: _sessionId,
    );

    setState(() {
      _messages.add(greetingMessage);
    });

    AiChatStorage.saveMessages(_sessionId, _messages);
  }

  String _firstWord(String? text) {
    if (text == null || text.trim().isEmpty) return 'Mahasiswa';
    final parts = text.trim().split(' ');
    if (parts.isEmpty) return 'Mahasiswa';
    final word = parts.first.toLowerCase();
    return word[0].toUpperCase() + word.substring(1);
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

  Future<void> _sendMessage(String question) async {
    final cleanQuestion = question.trim();
    if (cleanQuestion.isEmpty || _isLoading) return;

    _textController.clear();
    FocusScope.of(context).unfocus();

    final user = _sessionManager.getUser();
    final nim = user?.nim ?? '';
    final nama = user?.nama ?? '';
    final kodeFakultas = user?.kodeFakultas ?? '';
    final namaFakultas = user?.fakultas ?? '';
    final kodeProdi = user?.kodePst ?? '';
    final namaProdi = user?.programStudi ?? '';

    // Verify session validity (must be within 24h of last chat)
    // If expired, clear messages and adopt new session ID with current date
    final activeSessionId = await AiChatStorage.getOrInitActiveSessionId(nim);
    if (activeSessionId != _sessionId) {
      setState(() {
        _sessionId = activeSessionId;
        _messages.clear();
      });
    }

    final userMessage = AiChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: cleanQuestion,
      isUser: true,
      timestamp: DateTime.now(),
      sessionId: _sessionId,
    );

    final loadingMessageId = 'loading_${DateTime.now().millisecondsSinceEpoch}';
    final loadingMessage = AiChatMessage(
      id: loadingMessageId,
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      sessionId: _sessionId,
      isLoading: true,
    );

    setState(() {
      _messages.add(userMessage);
      _messages.add(loadingMessage);
      _isLoading = true;
      _showProcessingBanner = false;
    });

    _scrollToBottom();
    await AiChatStorage.saveMessages(_sessionId, _messages);

    // 30 seconds background timer per requirement (no visible countdown digits)
    _processingTimer?.cancel();
    _processingTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && _isLoading) {
        setState(() {
          _showProcessingBanner = true;
        });
      }
    });

    try {
      final response = await _chatService.sendMessage(
        question: cleanQuestion,
        sessionId: _sessionId,
        nim: nim,
        nama: nama,
        kodeFakultas: kodeFakultas,
        namaFakultas: namaFakultas,
        kodeProdi: kodeProdi,
        namaProdi: namaProdi,
      );

      _processingTimer?.cancel();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _showProcessingBanner = false;
          // Replace loading message with AI response
          final index = _messages.indexWhere((m) => m.id == loadingMessageId);
          if (index != -1) {
            _messages[index] = AiChatMessage(
              id: 'ai_${response.messageId ?? DateTime.now().millisecondsSinceEpoch}',
              messageId: response.messageId,
              text: response.answer,
              isUser: false,
              timestamp: DateTime.now(),
              isFallback: response.isFallback,
              whatsappLink: response.whatsappLink,
              csContact: response.csContact,
              sessionId: response.sessionId ?? _sessionId,
            );
          }
        });

        _scrollToBottom();
        await AiChatStorage.saveMessages(_sessionId, _messages);
      }
    } catch (e) {
      _processingTimer?.cancel();

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _isLoading = false;
          _showProcessingBanner = false;
          // Replace loading message with error message
          final index = _messages.indexWhere((m) => m.id == loadingMessageId);
          if (index != -1) {
            _messages[index] = AiChatMessage(
              id: 'err_${DateTime.now().millisecondsSinceEpoch}',
              text: e.toString().replaceFirst('Exception: ', ''),
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
              sessionId: _sessionId,
            );
          }
        });

        _scrollToBottom();
        await AiChatStorage.saveMessages(_sessionId, _messages);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.aiChatError ?? 'Gagal mengirim pesan. Silakan coba lagi.',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _retryLastMessage() {
    // Find the last user message and resend it
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        final text = _messages[i].text;
        // Remove subsequent error message if exists
        setState(() {
          _messages.removeRange(i + 1, _messages.length);
        });
        _sendMessage(text);
        break;
      }
    }
  }

  Future<void> _launchUrlSafe(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('[AiChatPage] Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka link: $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFeedbackModal(AiChatMessage message, bool isHelpful) {
    if (message.messageId == null) return;
    final l10n = AppLocalizations.of(context);

    final positiveOptions = [
      l10n?.aiChatFeedbackAccurate ?? 'Jawaban akurat dan lengkap',
      l10n?.aiChatFeedbackEasyToUnderstand ?? 'Mudah dipahami',
      l10n?.aiChatFeedbackVeryHelpful ?? 'Sangat membantu',
    ];

    final negativeOptions = [
      l10n?.aiChatFeedbackNotRelevant ?? 'Jawaban tidak sesuai pertanyaan',
      l10n?.aiChatFeedbackIncomplete ?? 'Informasi kurang lengkap',
      l10n?.aiChatFeedbackTooSlow ?? 'Respon terlalu lama',
      l10n?.aiChatFeedbackHardToUnderstand ?? 'Jawaban sulit dipahami',
    ];

    final options = isHelpful ? positiveOptions : negativeOptions;
    String? selectedReason;
    final customCommentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        isHelpful
                            ? Icons.thumb_up_alt_rounded
                            : Icons.thumb_down_alt_rounded,
                        color: isHelpful
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isHelpful
                              ? (l10n?.aiChatFeedbackPositive ??
                                  'Apa yang membuat jawaban ini membantu?')
                              : (l10n?.aiChatFeedbackNegative ??
                                  'Apa kendala pada jawaban ini?'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Preset options chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((option) {
                      final isSelected = selectedReason == option;
                      return ChoiceChip(
                        label: Text(option),
                        selected: isSelected,
                        selectedColor: isHelpful
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFFEE2E2),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? (isHelpful
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF991B1B))
                              : const Color(0xFF475569),
                        ),
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide(
                          color: isSelected
                              ? (isHelpful
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                              : Colors.transparent,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            selectedReason = selected ? option : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Optional custom comment with MAX 50 CHARACTERS per requirement
                  TextField(
                    controller: customCommentController,
                    maxLength: 50, // per user requirement: input opsional maksimal 50 karakter
                    decoration: InputDecoration(
                      hintText: l10n?.aiChatFeedbackCustomPlaceholder ??
                          'Tulis komentar lainnya (opsional, maks 50 karakter)...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      counterStyle: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isHelpful
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        _submitFeedback(
                          message: message,
                          isHelpful: isHelpful,
                          presetReason: selectedReason,
                          customComment: customCommentController.text,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isHelpful
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n?.aiChatFeedbackSubmit ?? 'Kirim Penilaian',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitFeedback({
    required AiChatMessage message,
    required bool isHelpful,
    String? presetReason,
    String? customComment,
  }) async {
    if (message.messageId == null) return;

    final comments = <String>[];
    if (presetReason != null && presetReason.isNotEmpty) {
      comments.add(presetReason);
    }
    if (customComment != null && customComment.trim().isNotEmpty) {
      comments.add(customComment.trim());
    }
    final combinedComment = comments.isEmpty ? null : comments.join(' - ');

    // Optimistically update UI
    setState(() {
      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        _messages[index] = message.copyWith(
          feedbackGiven: isHelpful,
          feedbackComment: combinedComment,
        );
      }
    });

    await AiChatStorage.saveMessages(_sessionId, _messages);

    final response = await _chatService.sendFeedback(
      messageId: message.messageId!,
      isHelpful: isHelpful,
      comment: combinedComment,
    );

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty
                ? response.message
                : (l10n?.aiChatFeedbackThankYou ??
                    'Terima kasih atas penilaian dan masukan Anda!'),
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = _sessionManager.getUser();
    final firstName = _firstWord(user?.nama);

    // Quick suggested questions per user requirement
    final quickQuestions = [
      l10n?.aiChatQuickQuestion1 ?? 'Bagaimana cara reset password SIAKAD?',
      l10n?.aiChatQuickQuestion2 ?? 'Saya lupa melakukan input penawaran mata kuliah?',
      l10n?.aiChatQuickQuestion3 ?? 'Saya lupa melakukan input KRS?',
      l10n?.aiChatQuickQuestion4 ?? 'Berapa jumlah SKS yang bisa saya ambil?',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppConstants.aiAssistantName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n?.aiChatOnlineStatus ?? 'Online',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Subtle Banner for 30s delay (No numeric countdown timer displayed per user instruction)
          if (_showProcessingBanner)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFEF3C7),
              child: Row(
                children: [
                  const SpinKitThreeBounce(
                    color: Color(0xFFD97706),
                    size: 14.0,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n?.aiChatWaitLonger ??
                          'Asisten AI sedang memproses, mohon tunggu sebentar...',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageItem(
                  message: message,
                  isInitialGreeting: index == 0 && !message.isUser,
                  quickQuestions: quickQuestions,
                  firstName: firstName,
                  l10n: l10n,
                );
              },
            ),
          ),

          // Bottom Input Area
          _buildInputArea(l10n),
        ],
      ),
    );
  }

  Widget _buildMessageItem({
    required AiChatMessage message,
    required bool isInitialGreeting,
    required List<String> quickQuestions,
    required String firstName,
    required AppLocalizations? l10n,
  }) {
    if (message.isUser) {
      return _buildUserBubble(message);
    } else if (message.isLoading) {
      return _buildLoadingBubble();
    } else if (message.isError) {
      return _buildErrorBubble(message, l10n);
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAiBubble(message, l10n),
          // Suggested Quick Questions under greeting per requirement
          if (isInitialGreeting) ...[
            const SizedBox(height: 12),
            _buildQuickQuestionsSection(quickQuestions, l10n),
          ],
        ],
      );
    }
  }

  Widget _buildUserBubble(AiChatMessage message) {
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiBubble(AiChatMessage message, AppLocalizations? l10n) {
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 36),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar AI
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF59E0B),
                  Color(0xFFD97706),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),

          // Bubble Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Markdown body
                  MarkdownBody(
                    data: message.text,
                    selectable: true,
                    onTapLink: (text, href, title) {
                      if (href != null && href.isNotEmpty) {
                        _launchUrlSafe(href);
                      }
                    },
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      Theme.of(context),
                    ).copyWith(
                      p: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF1E293B),
                      ),
                      h1: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      h2: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      h3: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      strong: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      blockquote: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        fontStyle: FontStyle.italic,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: const Border(
                          left: BorderSide(color: Color(0xFF94A3B8), width: 3),
                        ),
                      ),
                      code: const TextStyle(
                        backgroundColor: Color(0xFFF1F5F9),
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        color: Color(0xFF0F172A),
                      ),
                      a: TextStyle(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Fallback CS WhatsApp Button if applicable
                  if (message.isFallback &&
                      (message.whatsappLink != null || message.csContact != null)) ...[
                    const SizedBox(height: 12),
                    _buildFallbackContactButton(message, l10n),
                  ],

                  const SizedBox(height: 8),

                  // Footer: Timestamp + Feedback buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
                      ),

                      // Feedback action buttons (only if messageId != null)
                      if (message.messageId != null)
                        _buildFeedbackButtons(message),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackButtons(AiChatMessage message) {
    final feedbackGiven = message.feedbackGiven;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Thumbs Up
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: feedbackGiven == null
              ? () => _showFeedbackModal(message, true)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              feedbackGiven == true
                  ? Icons.thumb_up_alt_rounded
                  : Icons.thumb_up_alt_outlined,
              size: 16,
              color: feedbackGiven == true
                  ? const Color(0xFF10B981)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(width: 4),

        // Thumbs Down
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: feedbackGiven == null
              ? () => _showFeedbackModal(message, false)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              feedbackGiven == false
                  ? Icons.thumb_down_alt_rounded
                  : Icons.thumb_down_alt_outlined,
              size: 16,
              color: feedbackGiven == false
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackContactButton(
      AiChatMessage message, AppLocalizations? l10n) {
    final label = message.csContact?.label ?? 'Customer Service';
    final link = message.whatsappLink ??
        (message.csContact?.number != null
            ? 'https://wa.me/${message.csContact!.number}'
            : null);

    if (link == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchUrlSafe(link),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF25D366), // WhatsApp official green
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25D366).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n?.aiChatContactCs(label) ?? 'Hubungi $label via WhatsApp',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 80),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF59E0B),
                  Color(0xFFD97706),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const SpinKitThreeBounce(
              color: Color(0xFFD97706),
              size: 18.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBubble(AiChatMessage message, AppLocalizations? l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade700,
              size: 18,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text.isNotEmpty
                        ? message.text
                        : (l10n?.aiChatError ??
                            'Gagal mengirim pesan. Silakan coba lagi.'),
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _retryLastMessage,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n?.aiChatRetry ?? 'Coba Lagi',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestionsSection(
      List<String> quickQuestions, AppLocalizations? l10n) {
    return Container(
      margin: const EdgeInsets.only(left: 44, top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 16,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 4),
              Text(
                l10n?.aiChatQuickQuestions ?? 'Pertanyaan Cepat',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickQuestions.map((q) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : () => _sendMessage(q),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            q,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_outward_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(AppLocalizations? l10n) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  enabled: !_isLoading,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n?.aiChatInputHint ?? 'Tulis pertanyaan...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (val) => _sendMessage(val),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.grey.shade400 : AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isLoading
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isLoading
                        ? null
                        : () => _sendMessage(_textController.text),
                    child: const Center(
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Disclaimer: asisten robot, jawaban mungkin bisa salah
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  l10n?.aiChatDisclaimer ??
                      'Asisten ini adalah robot virtual, jawaban mungkin bisa salah.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
