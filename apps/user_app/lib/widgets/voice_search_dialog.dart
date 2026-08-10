import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceSearchDialog extends StatefulWidget {
  final Function(String query) onQueryRecognized;

  const VoiceSearchDialog({super.key, required this.onQueryRecognized});

  static Future<void> show(BuildContext context, {required Function(String query) onQueryRecognized}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: VoiceSearchDialog(onQueryRecognized: onQueryRecognized),
      ),
    );
  }

  @override
  State<VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<VoiceSearchDialog> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isAvailable = false;
  String _wordsSpoken = '';
  String _statusText = 'Initializing voice search...';
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (mounted) {
            setState(() {
              if (status == 'listening') {
                _statusText = 'Listening... Say something like "Fresh Milk" or "Apples"';
              } else if (status == 'notListening' || status == 'done') {
                _isListening = false;
                if (_wordsSpoken.trim().isNotEmpty) {
                  _submitSearch(_wordsSpoken);
                } else {
                  _statusText = 'Tap microphone to try again';
                }
              }
            });
          }
        },
        onError: (errorNotification) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _statusText = 'Could not catch that. Tap microphone to try again.';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isAvailable = available;
          if (available) {
            _startListening();
          } else {
            _statusText = 'Voice search ready. Tap microphone to speak.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAvailable = false;
          _statusText = 'Tap microphone to speak';
        });
      }
    }
  }

  void _startListening() async {
    // Play system audio chime sound and haptic vibration feedback for enabling microphone
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();

    if (!_isAvailable && !_speech.isAvailable) {
      await _initSpeech();
      return;
    }
    setState(() {
      _isListening = true;
      _wordsSpoken = '';
      _statusText = 'Listening... Speak now';
    });

    _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _wordsSpoken = result.recognizedWords;
          });
          if (result.finalResult && _wordsSpoken.trim().isNotEmpty) {
            _submitSearch(_wordsSpoken);
          }
        }
      },
    );
  }

  void _stopListening() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
    _speech.stop();
    setState(() {
      _isListening = false;
    });
    if (_wordsSpoken.trim().isNotEmpty) {
      _submitSearch(_wordsSpoken);
    }
  }

  void _submitSearch(String text) {
    if (text.trim().isEmpty) return;
    Navigator.of(context).pop();
    widget.onQueryRecognized(text.trim());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 25, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row with Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.mic_rounded, color: Color(0xFF059669), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Voice Search',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Color(0xFF4B5563), size: 18),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isListening ? const Color(0xFF059669) : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Recognized Text Display Box
          if (_wordsSpoken.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                '"$_wordsSpoken"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF065F46),
                ),
              ),
            ),

          // Animated Pulsing Microphone Button
          GestureDetector(
            onTap: () {
              if (_isListening) {
                _stopListening();
              } else {
                _startListening();
              }
            },
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (ctx, child) {
                final scale = _isListening ? 1.0 + (_animCtrl.value * 0.15) : 1.0;
                final ringOpacity = _isListening ? (0.4 - (_animCtrl.value * 0.3)).clamp(0.0, 0.4) : 0.0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isListening)
                      Container(
                        width: 110 * scale,
                        height: 110 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981).withValues(alpha: ringOpacity),
                        ),
                      ),
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF10B981)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons / Sample voice chips
          Wrap(
            spacing: 8,
            children: [
              _SampleQueryChip(label: '🍎 Fresh Apples', onTap: () => _submitSearch('Apples')),
              _SampleQueryChip(label: '🥛 Pure Milk', onTap: () => _submitSearch('Milk')),
              _SampleQueryChip(label: '🍞 Fresh Bread', onTap: () => _submitSearch('Bread')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SampleQueryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SampleQueryChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF065F46))),
      backgroundColor: const Color(0xFFF0FDF4),
      side: const BorderSide(color: Color(0xFFBBF7D0)),
      onPressed: onTap,
    );
  }
}
