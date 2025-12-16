import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../constants/api_constants.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late AudioRecorder _audioRecorder;
  bool _audioSupported = false;

  final ImagePicker _picker = ImagePicker();

  bool _isTyping = false;
  bool _isRecording = false;
  bool _showWelcomeAnimation = true;

  late AnimationController _welcomeController;
  late Animation<double> _welcomeFadeAnimation;

  XFile? _selectedImage;
  String? _recordedAudioPath;

  String _sessionId = 'flutter_default_${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();

    // Support audio
    if (kIsWeb) {
      _audioSupported = false;
    } else if (Platform.isAndroid || Platform.isIOS) {
      _audioSupported = true;
      _audioRecorder = AudioRecorder();
    } else {
      _audioSupported = false;
    }

    // Message de bienvenue
    _messages.add({
      'text':
      '👋 Salut ! Je suis ton assistant AgriSmart.\nTu peux m\'envoyer du texte, des photos${_audioSupported ? ' ou des notes vocales 🎤' : ''} !',
      'isBot': true,
    });

    // Animation de bienvenue
    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _welcomeFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeInOut),
    );

    _welcomeController.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _welcomeController.reverse().then((_) {
          if (mounted) {
            setState(() => _showWelcomeAnimation = false);
          }
        });
      }
    });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    if (_audioSupported) _audioRecorder.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  bool get _hasContent =>
      _controller.text.trim().isNotEmpty || _selectedImage != null || _recordedAudioPath != null;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final imageToSend = _selectedImage;
    final audioToSend = _recordedAudioPath;

    if (text.isEmpty && imageToSend == null && audioToSend == null) return;

    // Copier le fichier audio dans un emplacement permanent
    String? permanentAudioPath;
    if (audioToSend != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final permanentFile = File(path.join(appDir.path, fileName));
        await File(audioToSend).copy(permanentFile.path);
        permanentAudioPath = permanentFile.path;
      } catch (e) {
        debugPrint('Erreur copie audio: $e');
        permanentAudioPath = audioToSend; // Fallback
      }
    }

    if (mounted) {
      setState(() {
        _messages.add({
          'text': text,
          'isBot': false,
          'image': imageToSend?.path,
          'audio': permanentAudioPath,
        });
        _controller.clear();
        _isTyping = true;
        _selectedImage = null;
        _recordedAudioPath = null;
      });
      _scrollToBottom();
    }

    try {
      var uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatStreamEndpoint}');
      var request = http.MultipartRequest('POST', uri);

      request.fields['message'] = text;
      request.fields['session_id'] = _sessionId;

      if (imageToSend != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageToSend.path,
          filename: 'image.jpg',
        ));
      }

      if (audioToSend != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'audio',
          audioToSend,
          filename: 'voice.m4a',
        ));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 40));

      if (streamedResponse.statusCode != 200) {
        String msg = '❌ Erreur serveur (${streamedResponse.statusCode})';
        if (streamedResponse.statusCode == 429 || streamedResponse.statusCode == 503) {
          msg = '⚠️ Limite atteinte ou serveur surchargé.\nRéessaie plus tard.';
        }
        _addBotMessage(msg);
        return;
      }

      String accumulatedText = '';
      bool hasReceivedContent = false;

      await for (var chunk in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (chunk.startsWith('data: ')) {
          final data = chunk.substring(6).trim();
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data);

            if (json['error'] != null) {
              _addBotMessage(json['error']);
              hasReceivedContent = true;
              break;
            }

            if (json['text'] != null) {
              hasReceivedContent = true;
              accumulatedText += json['text'];
              if (mounted) {
                if (_messages.last['isBot'] == true) {
                  setState(() => _messages.last['text'] = accumulatedText);
                } else {
                  setState(() => _messages.add({'text': accumulatedText, 'isBot': true}));
                }
                _scrollToBottom();
              }
            }
          } catch (_) {}
        }
      }

      if (!hasReceivedContent && accumulatedText.isEmpty) {
        _addBotMessage('❌ Aucune réponse reçue. Le serveur IA est peut-être surchargé.');
      }
    } on TimeoutException {
      _addBotMessage('⏳ Temps d\'attente dépassé.\nRéessaie dans quelques minutes.');
    } catch (e) {
      String errorMsg = '❌ Erreur de connexion';
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socket') || errorStr.contains('host lookup') || errorStr.contains('network')) {
        errorMsg = '🌐 Pas de connexion internet.\nVérifie ta connexion.';
      }
      _addBotMessage(errorMsg);
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
      }
    }
  }

  void _addBotMessage(String text) {
    if (mounted) {
      setState(() {
        _messages.add({'text': text, 'isBot': true});
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _newConversation() {
    setState(() {
      _sessionId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
      _messages.clear();
      _messages.add({
        'text': '👋 Nouvelle conversation démarrée !\nComment puis-je t\'aider ?',
        'isBot': true,
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startRecording() async {
    if (!_audioSupported) return;

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission microphone requise')),
        );
      }
      return;
    }

    try {
      final directory = Directory.systemTemp;
      final path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1, sampleRate: 44100),
        path: path,
      );

      if (mounted) {
        setState(() => _isRecording = true);
      }
    } catch (e) {
      debugPrint('Erreur démarrage enregistrement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'enregistrement')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final path = await _audioRecorder.stop();
      if (path != null && mounted) {
        setState(() {
          _isRecording = false;
          _recordedAudioPath = path;
        });
      }
    } catch (e) {
      debugPrint('Erreur arrêt enregistrement: $e');
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'arrêt')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      debugPrint('Erreur sélection image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null && mounted) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      debugPrint('Erreur prise photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const SizedBox.shrink(),
        actions: [
          TextButton.icon(
            onPressed: _newConversation,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Nouvelle discussion'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // === EN-TÊTE STYLE DIAGNOSTICSCREEN ===
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[600]!, Colors.green[700]!],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Assistant IA AgriSmart",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Posez-moi toutes vos questions agricoles",
                      style: TextStyle(color: Colors.green[100]),
                    ),
                  ],
                ),
              ),

              // === LISTE DES MESSAGES ===
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return const AnimatedTypingIndicator();
                    }
                    final msg = _messages[index];
                    return MessageBubble(
                      text: msg['text'] ?? '',
                      isBot: msg['isBot'],
                      imagePath: msg['image'],
                      audioPath: msg['audio'],
                    );
                  },
                ),
              ),

              // === PRÉVISUALISATION IMAGE / AUDIO ===
              if (_selectedImage != null || _recordedAudioPath != null)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_selectedImage != null)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_selectedImage!.path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: -8,
                                right: -8,
                                child: IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => setState(() => _selectedImage = null),
                                ),
                              ),
                            ],
                          ),
                        if (_recordedAudioPath != null)
                          Container(
                            margin: const EdgeInsets.only(left: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: const Color(0xFF0A7B5A)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.mic, color: Color(0xFF0A7B5A)),
                                const SizedBox(width: 8),
                                const Text('Note vocale', style: TextStyle(color: Color(0xFF0A7B5A))),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                                  onPressed: () => setState(() => _recordedAudioPath = null),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // === BARRE D'ENTRÉE ===
              Container(
                color: Colors.white,
                padding: EdgeInsets.only(
                  left: 8,
                  right: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file, color: Colors.grey),
                        onPressed: _pickImage,
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.grey),
                        onPressed: _takePhoto,
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText: 'Écris un message...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                            onTapOutside: (event) {
                              // Empêcher l'erreur de widget désactivé
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onLongPressStart: _audioSupported && !_hasContent ? (_) => _startRecording() : null,
                        onLongPressEnd: _audioSupported && !_hasContent ? (_) => _stopRecording() : null,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: _hasContent ? const Color(0xFF0A7B5A) : Colors.grey.shade300,
                          onPressed: _hasContent ? _sendMessage : null,
                          child: Icon(
                            _hasContent ? Icons.send : (_isRecording ? Icons.mic : Icons.mic_none),
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (_isRecording)
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text('Enregistrement...', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // === ANIMATION DE BIENVENUE ===
          if (_showWelcomeAnimation)
            FadeTransition(
              opacity: _welcomeFadeAnimation,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 220,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(110),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 40,
                            spreadRadius: 10,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                    ),
                    Lottie.asset(
                      'assets/animations/chatbot_wave.json',
                      width: 320,
                      height: 320,
                      fit: BoxFit.contain,
                      repeat: true,
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

// === INDICATEUR DE TYPAGE ===
class AnimatedTypingIndicator extends StatefulWidget {
  const AnimatedTypingIndicator({super.key});

  @override
  State<AnimatedTypingIndicator> createState() => _AnimatedTypingIndicatorState();
}

class _AnimatedTypingIndicatorState extends State<AnimatedTypingIndicator> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Lottie.asset(
              'assets/animations/robot_wave.json',
              controller: AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat(),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.7, end: 1.3).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Interval(0.0 + index * 0.2, 0.6 + index * 0.2, curve: Curves.easeInOut),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A7B5A),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// === BULLE DE MESSAGE ===
class MessageBubble extends StatefulWidget {
  final String text;
  final bool isBot;
  final String? imagePath;
  final String? audioPath;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isBot,
    this.imagePath,
    this.audioPath,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with TickerProviderStateMixin {
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _playingSubscription;

  AnimationController? _avatarController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    if (widget.audioPath != null) {
      _initAudio();
    }

    if (widget.isBot) {
      _avatarController = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      )..repeat();
    }
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setFilePath(widget.audioPath!);

      _durationSubscription = _audioPlayer.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d ?? Duration.zero);
      });

      _positionSubscription = _audioPlayer.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });

      _playingSubscription = _audioPlayer.playingStream.listen((p) {
        if (mounted) setState(() => _isPlaying = p);
      });
    } catch (e) {
      debugPrint("Erreur chargement audio : $e");
    }
  }

  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint("Erreur lecture audio : $e");
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playingSubscription?.cancel();
    _audioPlayer.dispose();
    _avatarController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: widget.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.isBot) ...[
            SizedBox(
              width: 44,
              height: 44,
              child: Lottie.asset(
                'assets/animations/robot_wave.json',
                controller: _avatarController,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: widget.isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                if (widget.imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(widget.imagePath!),
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (widget.audioPath != null) ...[
                  Container(
                    width: 280,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.isBot ? Colors.grey.shade200 : const Color(0xFF0A7B5A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: widget.isBot ? Colors.black87 : Colors.white,
                          ),
                          onPressed: _togglePlayback,
                        ),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: _duration.inSeconds.toDouble(),
                            value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
                            onChanged: (v) => _audioPlayer.seek(Duration(seconds: v.toInt())),
                            activeColor: widget.isBot ? Colors.green : Colors.white,
                          ),
                        ),
                        Text(
                          '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                          style: TextStyle(
                            color: widget.isBot ? Colors.black54 : Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (widget.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: widget.isBot ? Colors.white : const Color(0xFF0A7B5A),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
                    ),
                    child: widget.isBot
                        ? MarkdownBody(
                      data: widget.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 15.5),
                        strong: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                        : Text(widget.text, style: const TextStyle(color: Colors.white, fontSize: 15.5)),
                  ),
              ],
            ),
          ),

          if (!widget.isBot) const SizedBox(width: 44),
        ],
      ),
    );
  }
}