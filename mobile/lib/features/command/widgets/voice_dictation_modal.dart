import 'dart:async';
import 'package:flutter/material.dart';

class VoiceDictationModal extends StatefulWidget {
  final Function(String transcript) onTranscriptConfirmed;

  const VoiceDictationModal({super.key, required this.onTranscriptConfirmed});

  @override
  State<VoiceDictationModal> createState() => _VoiceDictationModalState();
}

class _VoiceDictationModalState extends State<VoiceDictationModal> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _transcriptController = TextEditingController();
  Timer? _mockSpeechTimer;
  int _speechStep = 0;
  bool _isListening = true;

  final List<String> _simulatedPhrases = [
    'Run unit tests',
    'Run unit tests and check git status',
    'Run unit tests and check git status on the workstation',
    'Run unit tests and check git status on the workstation for any uncommitted changes',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _startSimulatedSpeech();
  }

  void _startSimulatedSpeech() {
    _mockSpeechTimer?.cancel();
    _speechStep = 0;
    _mockSpeechTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted || !_isListening) {
        timer.cancel();
        return;
      }

      if (_speechStep < _simulatedPhrases.length) {
        setState(() {
          _transcriptController.text = _simulatedPhrases[_speechStep];
          _speechStep++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mockSpeechTimer?.cancel();
    _transcriptController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _pulseController.repeat();
        _startSimulatedSpeech();
      } else {
        _pulseController.stop();
        _mockSpeechTimer?.cancel();
      }
    });
  }

  void _confirmTranscript() {
    final text = _transcriptController.text.trim();
    Navigator.of(context).pop();
    if (text.isNotEmpty) {
      widget.onTranscriptConfirmed(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF13161C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2E3440),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Voice Command Dictation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isListening
                        ? const Color(0xFF00E676).withValues(alpha: 0.15)
                        : const Color(0xFFFFB300).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isListening ? 'Listening...' : 'Paused',
                    style: TextStyle(
                      color: _isListening ? const Color(0xFF00E676) : const Color(0xFFFFB300),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pulsing Radial Sound Rings Visualizer
            GestureDetector(
              onTap: _toggleListening,
              child: SizedBox(
                width: 140,
                height: 140,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _RadialRingsPainter(
                        animationValue: _isListening ? _pulseController.value : 0.0,
                        isActive: _isListening,
                      ),
                      child: Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isListening
                                  ? [const Color(0xFF00E676), const Color(0xFF00B0FF)]
                                  : [const Color(0xFF374151), const Color(0xFF1F2937)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isListening
                                    ? const Color(0xFF00E676).withValues(alpha: 0.4)
                                    : Colors.transparent,
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_off,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _isListening ? 'Tap mic to pause recording' : 'Tap mic to resume recording',
              style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Editable Live Transcript
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2E39)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: TextField(
                controller: _transcriptController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Speak now, transcript will appear here...',
                  hintStyle: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Actions Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8A94A6),
                      side: const BorderSide(color: Color(0xFF2A2E39)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Use Transcript'),
                    onPressed: _confirmTranscript,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF090A0C),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RadialRingsPainter extends CustomPainter {
  final double animationValue;
  final bool isActive;

  _RadialRingsPainter({required this.animationValue, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw 3 expanding concentric rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (animationValue + (i * 0.33)) % 1.0;
      final radius = 35.0 + (maxRadius - 35.0) * ringProgress;
      final opacity = (1.0 - ringProgress).clamp(0.0, 0.8);

      final paint = Paint()
        ..color = const Color(0xFF00E676).withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialRingsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.isActive != isActive;
  }
}
