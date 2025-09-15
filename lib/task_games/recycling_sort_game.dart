import 'package:flutter/material.dart';
import 'dart:math';

class RecyclingSortGame extends StatefulWidget {
  final VoidCallback? onComplete;
  RecyclingSortGame({this.onComplete});
  @override
  _RecyclingSortGameState createState() => _RecyclingSortGameState();
}

class _RecyclingSortGameState extends State<RecyclingSortGame>
    with TickerProviderStateMixin {
  late AnimationController _conveyorController;
  List<WasteItem> wasteItems = [];
  int score = 0;
  int correctSorts = 0;
  int wrongSorts = 0;
  bool gameCompleted = false;

  final List<String> biodegradableItems = [
    "🍌", "🍎", "🥕", "🍃", "🌽", "🥬"
  ];
  
  final List<String> nonBiodegradableItems = [
    "🥤", "🍼", "🥫", "📱", "🔋", "💡"
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateWasteItems();
  }

  void _initializeAnimations() {
    _conveyorController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  void _generateWasteItems() {
    final random = Random();
    final allItems = [...biodegradableItems, ...nonBiodegradableItems];
    
    for (int i = 0; i < 8; i++) {
      final item = allItems[random.nextInt(allItems.length)];
      wasteItems.add(WasteItem(
        id: i,
        emoji: item,
        isBiodegradable: biodegradableItems.contains(item),
        x: 50.0 + (i * 60),
        y: 300.0,
      ));
    }
  }

  void _sortItem(WasteItem item, bool sortedAsBiodegradable) {
    setState(() {
      wasteItems.remove(item);
      
      if (item.isBiodegradable == sortedAsBiodegradable) {
        correctSorts++;
        score += 10;
      } else {
        wrongSorts++;
        score = max(0, score - 5);
      }
      
      if (wasteItems.isEmpty) {
        _completeGame();
      }
    });
  }

  void _completeGame() {
    setState(() {
      gameCompleted = true;
    });
    if (widget.onComplete != null) widget.onComplete!();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("🎉 Sorting Master!", style: TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Great job sorting the waste!", style: TextStyle(color: Colors.black)),
            SizedBox(height: 10),
            Text("Correct: $correctSorts ✅", style: TextStyle(color: Colors.black)),
            Text("Wrong: $wrongSorts ❌", style: TextStyle(color: Colors.black)),
            Text("Final Score: $score 🏆", style: TextStyle(color: Colors.black)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("Continue Adventure"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _conveyorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E8),
              Color(0xFFC8E6C9),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildConveyorBelt(),
            _buildSortingBins(),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "♻️ Sorting Station",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              Text(
                "Score: $score",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              "${wasteItems.length} items left",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConveyorBelt() {
    return Container(
      height: 200,
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Conveyor Belt Animation
          AnimatedBuilder(
            animation: _conveyorController,
            builder: (context, child) {
              return CustomPaint(
                painter: ConveyorBeltPainter(_conveyorController.value),
                size: Size.infinite,
              );
            },
          ),
          // Waste Items in a horizontal scrollable row
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: wasteItems.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Draggable<WasteItem>(
                      data: item,
                      feedback: _buildWasteItemWidget(item, isDragging: true),
                      childWhenDragging: Container(width: 50, height: 50),
                      child: _buildWasteItemWidget(item),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteItemWidget(WasteItem item, {bool isDragging = false}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDragging ? [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ] : [],
      ),
      child: Center(
        child: Text(
          item.emoji,
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }

  Widget _buildSortingBins() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: DragTarget<WasteItem>(
              onWillAccept: (item) => item != null && item.isBiodegradable,
              onAccept: (item) => _sortItem(item, true),
              onLeave: (item) {
                if (item != null && !item.isBiodegradable) {
                  _showWrongDropMessage();
                }
              },
              builder: (context, candidateData, rejectedData) {
                return _buildBin(
                  "🌱 Biodegradable",
                  Colors.green,
                  candidateData.isNotEmpty,
                );
              },
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: DragTarget<WasteItem>(
              onWillAccept: (item) => item != null && !item.isBiodegradable,
              onAccept: (item) => _sortItem(item, false),
              onLeave: (item) {
                if (item != null && item.isBiodegradable) {
                  _showWrongDropMessage();
                }
              },
              builder: (context, candidateData, rejectedData) {
                return _buildBin(
                  "🗑️ Non-Biodegradable",
                  Colors.red,
                  candidateData.isNotEmpty,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showWrongDropMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Colors.red[50],
        title: Text(
          "Ahh! Ah!!",
          style: TextStyle(
            color: Colors.red[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "It's wrong. Try Again.",
          style: TextStyle(color: Colors.red[800]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK", style: TextStyle(color: Colors.red[800])),
          ),
        ],
      ),
    );
  }

  Widget _buildBin(String label, Color color, bool isHovering) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      height: 120,
      decoration: BoxDecoration(
        color: isHovering ? color.withOpacity(0.8) : color.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color,
          width: isHovering ? 4 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: isHovering ? 12 : 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Text(
        "🎯 Drag items to the correct bins!\n🌱 Biodegradable: Food, plants\n🗑️ Non-Biodegradable: Plastic, metal, electronics",
        style: TextStyle(
          fontSize: 14,
          color: Colors.blue[800],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class ConveyorBeltPainter extends CustomPainter {
  final double animationValue;

  ConveyorBeltPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 3;

    for (double x = -20; x < size.width + 20; x += 40) {
      final adjustedX = (x + animationValue * 40) % (size.width + 40);
      canvas.drawLine(
        Offset(adjustedX, size.height * 0.3),
        Offset(adjustedX + 20, size.height * 0.3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WasteItem {
  final int id;
  final String emoji;
  final bool isBiodegradable;
  final double x;
  final double y;

  WasteItem({
    required this.id,
    required this.emoji,
    required this.isBiodegradable,
    required this.x,
    required this.y,
  });
}
