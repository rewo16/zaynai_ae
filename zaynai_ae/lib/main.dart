import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Setting system UI properties
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      home: const ApiUrlInputScreen(),
    );
  }
}

// API URL sabit değerleri
class ApiConstants {
  static const String defaultApiUrlHint = "https://your-api-url.ngrok-free.app/generate";
  static const String apiUrlKey = 'api_url';
}

// Renk sabitleri
class AppColors {
  static const Color backgroundColor = Color(0xFF19191F);
  static const Color cardColor = Color(0xFF1E1F25);
  static const Color messageUserColor = Color(0x682C3647);
  static const Color messageAiColor = Color(0xFF28292E);

  static const List<Color> gradientColors = [
    Color(0xFF4285F4),
    Color(0xFF9B72CB),
    Color(0xFFD96570),
  ];
}

// Yeni ekran: API URL giriş ekranı
class ApiUrlInputScreen extends StatefulWidget {
  const ApiUrlInputScreen({super.key});

  @override
  State<ApiUrlInputScreen> createState() => _ApiUrlInputScreenState();
}

class _ApiUrlInputScreenState extends State<ApiUrlInputScreen> {
  final TextEditingController _apiUrlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedApiUrl();
  }

  Future<void> _loadSavedApiUrl() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(ApiConstants.apiUrlKey);

      if (savedUrl != null && savedUrl.isNotEmpty) {
        _apiUrlController.text = savedUrl;
      }
    } catch (e) {
      debugPrint('Error loading API URL: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveApiUrlAndContinue() async {
    final apiUrl = _apiUrlController.text.trim();

    if (apiUrl.isEmpty) {
      setState(() => _errorMessage = 'API URL cannot be empty');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // API URL geçerliliğini kontrol et
      await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('API connection timed out'),
      );

      // URL'yi yerel depolamaya kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConstants.apiUrlKey, apiUrl);

      // Sohbet ekranına git
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GradientTextFieldScreen(apiUrl: apiUrl),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'API connection error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: AppColors.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    "ZaynAI",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  "Enter API",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildApiUrlInput(),
                const SizedBox(height: 8),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 24),
                _buildContinueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApiUrlInput() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.4),
            Colors.purple.withOpacity(0.4),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: TextField(
        controller: _apiUrlController,
        decoration: const InputDecoration(
          hintText: ApiConstants.defaultApiUrlHint,
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 15.0,
            horizontal: 20.0,
          ),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveApiUrlAndContinue,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 40,
          vertical: 15,
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey,
        disabledForegroundColor: Colors.white60,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ).copyWith(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
            return states.contains(MaterialState.disabled)
                ? Colors.grey
                : Colors.blue;
          },
        ),
      ),
      child: _isLoading
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : const Text(
        "continue",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }
}

class GradientTextFieldScreen extends StatefulWidget {
  final String apiUrl;

  const GradientTextFieldScreen({super.key, required this.apiUrl});

  @override
  State<GradientTextFieldScreen> createState() => _GradientTextFieldScreenState();
}

class _GradientTextFieldScreenState extends State<GradientTextFieldScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<List<String>> _chatHistory = [];
  final List<String> _currentChat = [];

  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;

  late AnimationController _dotController;
  late Animation<double> _dotScaleAnimation;

  late String _apiUrl;

  // Belirli mesaj ön eklerini tanımlayan sabitler
  static const String _userPrefix = "You: ";
  static const String _aiPrefix = "ZaynAI: ";

  @override
  void initState() {
    super.initState();
    _apiUrl = widget.apiUrl;
    _initAnimations();
    _initSpeech();
  }

  void _initAnimations() {
    // Döndürme animasyonu
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(_controller);
    _controller.repeat();

    // Nokta animasyonu
    _dotController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _dotScaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _dotController, curve: Curves.easeInOutSine),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dotController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _dotController.forward();
      }
    });
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' && mounted) {
            setState(() {
              _isListening = false;
              _dotController.stop();
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _dotController.stop();
            });
          }
        },
      );

      if (!mounted) return;
      if (!available) {
        debugPrint('Speech recognition unavailable');
      }
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
    }
  }

  void _startListening() async {
    if (!_isListening) {
      try {
        bool available = await _speechToText.initialize();
        if (available && mounted) {
          setState(() {
            _isListening = true;
            _dotController.repeat();
          });
          _speechToText.listen(
            onResult: (result) {
              if (mounted) {
                setState(() {
                  _textController.text = result.recognizedWords;
                });
              }
            },
            localeId: "tr_TR",
          );
        }
      } catch (e) {
        debugPrint('Error starting listen: $e');
      }
    } else {
      _stopListening();
    }
  }

  void _stopListening() {
    _speechToText.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        _dotController.stop();
      });
    }
  }

  void _changeApiUrl() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApiUrlInputScreen(),
      ),
    );

    if (result != null && result is String && mounted) {
      setState(() {
        _apiUrl = result;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_isListening) return;

    final message = _textController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _currentChat.add("$_userPrefix$message");
    });
    _textController.clear();

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': message,
          'mode': 'qa',
          'max_tokens': 256,
        }),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final aiResponse = data['response']?.toString() ?? 'API did not respond';

          setState(() {
            _currentChat.add("$_aiPrefix$aiResponse");
          });
        } catch (e) {
          _addErrorMessage("JSON parse errors - $e");
        }
      } else {
        _addErrorMessage("${response.statusCode} - Blank answer");
      }
    } catch (e) {
      if (mounted) {
        _addErrorMessage("$e");
      }
    }
  }

  void _addErrorMessage(String error) {
    if (mounted) {
      setState(() {
        _currentChat.add("${_aiPrefix}Error: $error");
      });
    }
  }

  void _startNewChat() {
    if (_currentChat.isEmpty) return;

    setState(() {
      // Aynı sohbeti tekrar eklemeyi önle
      if (!_chatHistory.any(
            (chat) => chat.length == _currentChat.length &&
            chat.every((msg) => _currentChat.contains(msg)),
      )) {
        _chatHistory.insert(0, List.from(_currentChat));
      }
      _currentChat.clear();
    });
  }

  String _getChatTitle(String firstMessage) {
    const int maxLength = 20;
    if (firstMessage.length <= maxLength) {
      return firstMessage;
    }
    return "${firstMessage.substring(0, maxLength)}...";
  }

  void _showChatHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _buildChatHistoryDialog(dialogContext),
    );
  }

  Widget _buildChatHistoryDialog(BuildContext dialogContext) {
    return AlertDialog(
      title: const Text(
        "Chat history",
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: AppColors.backgroundColor,
      content: SizedBox(
        width: double.maxFinite,
        child: _chatHistory.isEmpty
            ? const Center(
          child: Text(
            "No chat history yet",
            style: TextStyle(color: Colors.white70),
          ),
        )
            : ListView.builder(
          shrinkWrap: true,
          itemCount: _chatHistory.length,
          itemBuilder: (context, index) {
            final chat = _chatHistory[index];
            final chatTitle = _getChatTitle(
              chat.isNotEmpty ? chat[0] : "New chat",
            );
            return ListTile(
              title: Text(
                chatTitle,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                "number of messages: ${chat.length}",
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: () {
                setState(() {
                  _currentChat.clear();
                  _currentChat.addAll(chat);
                  _chatHistory.removeAt(index);
                  _chatHistory.insert(0, List.from(_currentChat));
                });
                Navigator.pop(dialogContext);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text("close", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _addAttachment(String attachmentType) {
    setState(() {
      _currentChat.add(attachmentType);
    });
  }

  Widget _buildVoiceBars() {
    return SizedBox(
      key: const ValueKey<bool>(true),
      width: 60,
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: AnimatedBuilder(
              animation: _dotScaleAnimation,
              builder: (context, child) {
                final phaseShift = (index / 5) * 2 * pi;
                final animationValue = (_dotController.value * 2 * pi + phaseShift);
                final value = sin(animationValue).abs();
                final heightFactor = 0.3 + (value * 0.7);

                return Container(
                  width: 4,
                  height: 6 + (heightFactor * 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.gradientColors,
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(statusBarHeight),
            Expanded(
              child: Stack(
                children: [
                  _buildChatMessages(),
                  if (_currentChat.isEmpty)
                    _buildWelcomeMessage(),
                ],
              ),
            ),
            _buildInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double statusBarHeight) {
    return Container(
      padding: EdgeInsets.only(
        top: statusBarHeight + 16,
        bottom: 16,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(
                Icons.menu,
                size: 30,
                color: Colors.white,
              ),
              onPressed: () => _showChatHistory(context),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: AppColors.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    "ZaynAI",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7.0,
                    vertical: 3.0,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 1.5),
                        blurRadius: 3,
                        spreadRadius: 0.75,
                      ),
                    ],
                  ),
                  child: const Text(
                    "1.0",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: _changeApiUrl,
                ),
                IconButton(
                  icon: const Icon(Icons.chat, color: Colors.white),
                  onPressed: _startNewChat,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _currentChat.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: _currentChat[index]);
      },
    );
  }

  Widget _buildWelcomeMessage() {
    return Align(
      alignment: Alignment.topCenter,
      child: Transform.translate(
        offset: const Offset(0, 200),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 20,
          ),
          color: AppColors.backgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Hello, I'm ZaynAI.",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "How can I help you?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "API used: ${Uri.parse(_apiUrl).host}",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.8),
              Colors.purple.withOpacity(0.8),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              spreadRadius: 3,
              blurRadius: 10,
              offset: const Offset(-5, 0),
            ),
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              spreadRadius: 3,
              blurRadius: 10,
              offset: const Offset(5, 0),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: "Enter a promt...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 20.0,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onSubmitted: (value) => _sendMessage(),
              ),
            ),
            _buildAttachmentButton(),
            IconButton(
              icon: Icon(
                _isListening ? Icons.mic_off : Icons.mic,
                color: Colors.white,
              ),
              onPressed: _startListening,
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: _isListening
                  ? _buildVoiceBars()
                  : IconButton(
                key: const ValueKey<bool>(false),
                icon: const Icon(
                  Icons.send,
                  color: Colors.white,
                ),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.add, color: Colors.white),
      color: AppColors.backgroundColor,
      padding: EdgeInsets.zero,
      onSelected: _addAttachment,
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: "photo added",
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.image,
            color: Colors.white,
            size: 24,
          ),
        ),
        const PopupMenuItem<String>(
          value: "file added",
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.attach_file,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
      offset: const Offset(0, -120),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(
        minWidth: 40,
        maxWidth: 40,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _dotController.dispose();
    _textController.dispose();
    _speechToText.stop();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  static const String _userPrefix = "You: ";
  static const String _aiPrefix = "ZaynAI: ";

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUserMessage = message.startsWith(_userPrefix);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUserMessage
                ? AppColors.messageUserColor
                : AppColors.messageAiColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            _getMessageContent(message),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            softWrap: true,
            textAlign: TextAlign.left,
          ),
        ),
      ),
    );
  }

  String _getMessageContent(String message) {
    if (message.startsWith(_userPrefix)) {
      return message.substring(_userPrefix.length);
    }
    if (message.startsWith(_aiPrefix)) {
      return message.substring(_aiPrefix.length);
    }
    return message;
  }
}