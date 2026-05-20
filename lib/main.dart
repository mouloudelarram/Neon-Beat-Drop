import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MagicPianoQuestApp());
}

class MagicPianoQuestApp extends StatelessWidget {
  const MagicPianoQuestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magic Piano Quest',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0a0e27),
        primarySwatch: Colors.purple,
      ),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late Ticker _gameLoopTicker;
  late AudioPlayer _audioPlayer;
  
  double screenWidth = 0;
  double screenHeight = 0;
  
  static const int laneCount = 4;
  static const double tileSize = 80;
  static const double tileSpeedInitial = 250;
  static const double tileSpawnRate = 0.6;
  static const int maxLives = 3;
  
  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  int lives = maxLives;
  bool gameOver = false;
  double gameSpeed = 1.0;
  int tilesCleared = 0;
  
  final List<GameTile> tiles = [];
  final List<ParticleEffect> particles = [];
  double timeSinceLastSpawn = 0;
  final Random random = Random();
  
  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    _gameLoopTicker = createTicker((elapsed) {
      _updateGameLoop(elapsed.inMilliseconds / 1000.0);
    });
    _gameLoopTicker.start();
  }

  @override
  void dispose() {
    _gameLoopTicker.stop();
    _gameLoopTicker.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updateGameLoop(double deltaTime) {
    if (gameOver) return;
    
    if (!mounted) return;
    
    setState(() {
      timeSinceLastSpawn += deltaTime;
      
      if (timeSinceLastSpawn >= tileSpawnRate / gameSpeed) {
        _spawnNewTile();
        timeSinceLastSpawn = 0;
      }
      
      for (int i = tiles.length - 1; i >= 0; i--) {
        tiles[i].y += tileSpeedInitial * gameSpeed * deltaTime;
        
        if (tiles[i].y > screenHeight + 100) {
          tiles.removeAt(i);
          if (lives > 0) {
            lives--;
            if (lives == 0) {
              gameOver = true;
              _showGameOverScreen();
            }
          }
          combo = 0;
        }
      }
      
      for (int i = particles.length - 1; i >= 0; i--) {
        particles[i].update(deltaTime);
        if (particles[i].isDead) {
          particles.removeAt(i);
        }
      }
    });
  }

  void _spawnNewTile() {
    final lane = random.nextInt(laneCount);
    final colors = [
      const Color(0xFFFF006E),
      const Color(0xFF00D9FF),
      const Color(0xFFFFBE0B),
      const Color(0xFF8338EC),
    ];
    
    tiles.add(
      GameTile(
        lane: lane,
        y: -tileSize,
        color: colors[lane],
      ),
    );
  }

  void _onTileTapped(int tileIndex) {
    if (gameOver || tileIndex >= tiles.length) return;
    
    _playTapSound();
    
    final tile = tiles[tileIndex];
    final laneX = (screenWidth / laneCount) * tile.lane + (screenWidth / laneCount) / 2;
    
    for (int i = 0; i < 8; i++) {
      particles.add(
        ParticleEffect(
          x: laneX,
          y: tile.y + tileSize / 2,
          vx: (random.nextDouble() - 0.5) * 400,
          vy: (random.nextDouble() - 0.5) * 400 - 100,
          color: tile.color,
          life: 0.6,
        ),
      );
    }
    
    score += (10 * (1 + combo ~/ 10));
    combo++;
    tilesCleared++;
    maxCombo = max(maxCombo, combo);
    
    if (tilesCleared % 5 == 0) {
      gameSpeed += 0.05;
    }
    
    tiles.removeAt(tileIndex);
  }

  void _playTapSound() async {
    try {
      await _audioPlayer.play(UrlSource('data:audio/wav;base64,UklGRiYAAABXQVZFZm10IBAAAAABAAEAQB8AAAB9AAACABAAZGF0YQIAAAAAAA=='));
    } catch (e) {
      // Silent fallback if audio fails
    }
  }

  void _showGameOverScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1f3a),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF00D9FF), width: 3),
          ),
          title: const Text(
            '🎮 GAME OVER',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFF006E),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Final Score: $score',
                style: const TextStyle(
                  color: Color(0xFFFFBE0B),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Max Combo: $maxCombo',
                style: const TextStyle(
                  color: Color(0xFF8338EC),
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tiles Cleared: $tilesCleared',
                style: const TextStyle(
                  color: Color(0xFF00D9FF),
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Play Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _restartGame() {
    setState(() {
      score = 0;
      combo = 0;
      maxCombo = 0;
      lives = maxLives;
      gameOver = false;
      gameSpeed = 1.0;
      tilesCleared = 0;
      tiles.clear();
      particles.clear();
      timeSinceLastSpawn = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    screenWidth = size.width;
    screenHeight = size.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e27),
      body: Stack(
        children: [
          Container(
            width: screenWidth,
            height: screenHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0a0e27),
                  const Color(0xFF1a1f3a).withOpacity(0.8),
                ],
              ),
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1a1f3a),
                      const Color(0xFF1a1f3a).withOpacity(0.6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D9FF).withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '♪ Magic Piano Quest ♪',
                          style: TextStyle(
                            color: const Color(0xFF00D9FF),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF00D9FF).withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Score: $score',
                          style: const TextStyle(
                            color: Color(0xFFFFBE0B),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Combo: $combo',
                          style: TextStyle(
                            color: combo > 0 ? const Color(0xFF8338EC) : Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(
                            maxLives,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                Icons.favorite,
                                color: index < lives
                                    ? const Color(0xFFFF006E)
                                    : Colors.grey.withOpacity(0.3),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTapDown: (details) {
                    if (!gameOver) {
                      final laneWidth = screenWidth / laneCount;
                      final tappedLane = (details.globalPosition.dx ~/ laneWidth).clamp(0, laneCount - 1);
                      
                      for (int i = 0; i < tiles.length; i++) {
                        if (tiles[i].lane == tappedLane &&
                            tiles[i].y >= screenHeight - 150 &&
                            tiles[i].y <= screenHeight - 20) {
                          _onTileTapped(i);
                          break;
                        }
                      }
                    }
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: CustomPaint(
                      painter: GameRenderer(
                        tiles: tiles,
                        particles: particles,
                        laneCount: laneCount,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        tileSize: tileSize,
                      ),
                      size: Size(screenWidth, screenHeight - MediaQuery.of(context).padding.top - kToolbarHeight),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (gameOver)
            Container(
              width: screenWidth,
              height: screenHeight,
              color: Colors.black.withOpacity(0.3),
            ),
        ],
      ),
    );
  }
}

class GameTile {
  final int lane;
  double y;
  final Color color;

  GameTile({
    required this.lane,
    required this.y,
    required this.color,
  });
}

class ParticleEffect {
  double x;
  double y;
  final double vx;
  final double vy;
  final Color color;
  double life;
  final double maxLife;
  bool isDead = false;

  ParticleEffect({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.life,
  }) : maxLife = life;

  void update(double deltaTime) {
    x += vx * deltaTime;
    y += vy * deltaTime;
    life -= deltaTime;
    if (life <= 0) {
      isDead = true;
    }
  }

  double get opacity => (life / maxLife).clamp(0, 1);
}

class GameRenderer extends CustomPainter {
  final List<GameTile> tiles;
  final List<ParticleEffect> particles;
  final int laneCount;
  final double screenWidth;
  final double screenHeight;
  final double tileSize;

  GameRenderer({
    required this.tiles,
    required this.particles,
    required this.laneCount,
    required this.screenWidth,
    required this.screenHeight,
    required this.tileSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final laneWidth = screenWidth / laneCount;
    
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity * 0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        4 * particle.opacity,
        paint,
      );
    }
    
    for (var tile in tiles) {
      final laneX = tile.lane * laneWidth + laneWidth / 2;
      
      final shadowPaint = Paint()
        ..color = tile.color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(laneX, tile.y),
            width: tileSize - 8,
            height: tileSize - 8,
          ),
          const Radius.circular(12),
        ),
        shadowPaint,
      );
      
      final paint = Paint()
        ..color = tile.color
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(laneX, tile.y),
            width: tileSize - 8,
            height: tileSize - 8,
          ),
          const Radius.circular(12),
        ),
        paint,
      );
      
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(laneX, tile.y),
            width: tileSize - 8,
            height: tileSize - 8,
          ),
          const Radius.circular(12),
        ),
        borderPaint,
      );
      
      final glowPaint = Paint()
        ..color = tile.color.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 15);
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(laneX, tile.y),
            width: tileSize,
            height: tileSize,
          ),
          const Radius.circular(12),
        ),
        glowPaint,
      );
    }
    
    final tapZonePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, screenHeight - 150, screenWidth, 150),
      tapZonePaint,
    );
    
    final tapZoneBorder = Paint()
      ..color = const Color(0xFF00D9FF).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawLine(
      Offset(0, screenHeight - 150),
      Offset(screenWidth, screenHeight - 150),
      tapZoneBorder,
    );
    
    for (int i = 0; i < laneCount - 1; i++) {
      final x = (i + 1) * laneWidth;
      canvas.drawLine(
        Offset(x, screenHeight - 150),
        Offset(x, screenHeight),
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..strokeWidth = 1,
      );
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(GameRenderer oldDelegate) => true;
}
