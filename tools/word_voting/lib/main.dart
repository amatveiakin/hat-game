import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Lexion {
  static List<String>? _words;

  static Future<void> init() async {
    _words = (await rootBundle.loadString('words.txt')).split('\n');
  }

  static String randomWord() {
    return _words![Random().nextInt(_words!.length)];
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Lexion.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hat Game Word Voting',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Hat Game Word Voting'),
        ),
        body: VotingView(),
      ),
    );
  }
}

enum Sector {
  ok, // right
  bad, // left
  easy, // bottom
  hard, // top
}

class DragState {
  static const double certaintyThreshold = 0.8;

  final Sector? sector;
  final double? certainty; // [0.0, 1.0]

  DragState({this.sector, this.certainty});
}

class VotingViewPainter extends CustomPainter {
  final String word;
  final DragState state;

  VotingViewPainter({required this.word, required this.state});

  static Color sectorColor(Sector sector) {
    switch (sector) {
      case Sector.ok:
        return Colors.green;
      case Sector.bad:
        return Colors.red;
      case Sector.easy:
        return Colors.blue;
      case Sector.hard:
        return Colors.black;
    }
  }

  static String sectorText(Sector sector) {
    switch (sector) {
      case Sector.ok:
        return 'Normal';
      case Sector.bad:
        return 'Bad';
      case Sector.easy:
        return 'Easy';
      case Sector.hard:
        return 'Hard';
    }
  }

  static Offset sectorTextOffset(
      Sector sector, Size canvasSize, Size textSize) {
    switch (sector) {
      case Sector.ok:
        return canvasSize.topRight(Offset.zero) -
            textSize.topRight(Offset.zero);
      case Sector.bad:
        return canvasSize.topLeft(Offset.zero) - textSize.topLeft(Offset.zero);
      case Sector.easy:
        return canvasSize.bottomCenter(Offset.zero) -
            textSize.bottomCenter(Offset.zero);
      case Sector.hard:
        return canvasSize.topCenter(Offset.zero) -
            textSize.topCenter(Offset.zero);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sector = state.sector;
    final certainty = state.certainty;

    if (sector != null && certainty != null) {
      final Color color = sectorColor(sector);

      var overlayPaint = Paint()
        ..color = color.withOpacity(certainty / 2.0)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
          Rect.fromPoints(
              size.topLeft(Offset.zero), size.bottomRight(Offset.zero)),
          overlayPaint);

      if (certainty >= DragState.certaintyThreshold) {
        final textPainter = TextPainter(textDirection: TextDirection.rtl);
        textPainter.text = TextSpan(
            text: sectorText(sector),
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Color.lerp(color, Colors.black, 0.3),
            ));
        textPainter.layout();
        textPainter.paint(
            canvas, sectorTextOffset(sector, size, textPainter.size));
      }
    }

    final textPainter = TextPainter(textDirection: TextDirection.rtl);
    double fontSize = 54.0;
    do {
      textPainter.text = TextSpan(
          text: word,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.black,
          ));
      textPainter.layout();
      fontSize -= 1.0;
    } while (fontSize > 6.0 && textPainter.size.width > size.width * 0.9);
    textPainter.paint(canvas,
        size.center(Offset.zero) - textPainter.size.center(Offset.zero));
  }

  @override
  bool shouldRepaint(VotingViewPainter oldPainter) {
    return word != oldPainter.word ||
        state.sector != oldPainter.state.sector ||
        state.certainty != oldPainter.state.certainty;
  }
}

class VotingView extends StatefulWidget {
  VotingView();

  @override
  VotingViewState createState() => VotingViewState();
}

class VotingViewState extends State<VotingView> {
  String? word;
  Offset? dragStartPos;
  Offset? dragShift;

  DragState getDragState() {
    final dragShift = this.dragShift;
    if (dragShift == null) {
      return DragState();
    }
    final double dist = dragShift.distance;
    const distMin = 30.0;
    const distMax = 100.0;
    if (dist <= distMin) {
      return DragState();
    }
    final double angle = atan2(dragShift.dy, dragShift.dx) * 4 / pi; // -4 to 4
    const aMin = 0.3;
    const aMax = 0.5;
    double a = angle.abs();
    if (a > 2.0) a -= 2.0;
    a = (a - 1.0).abs();
    if (a < aMin) {
      return DragState();
    }
    Sector sector;
    if (angle < -3.0) {
      sector = Sector.bad;
    } else if (angle < -1.0) {
      sector = Sector.hard;
    } else if (angle < 1.0) {
      sector = Sector.ok;
    } else if (angle < 3.0) {
      sector = Sector.easy;
    } else {
      sector = Sector.bad;
    }
    return DragState(
      sector: sector,
      certainty: max(
          0.0,
          min(1.0, (dist - distMin) / (distMax - distMin)) *
              min(1.0, (a - aMin) / (aMax - aMin))),
    );
  }

  void generateWord() {
    word = Lexion.randomWord();
  }

  void countVote() {
    final dragState = getDragState();
    if (dragState.certainty == null ||
        dragState.certainty! < DragState.certaintyThreshold) {
      return;
    }
    // TODO: Write vote to Firebase
    generateWord();
  }

  @override
  void initState() {
    super.initState();
    generateWord();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (DragStartDetails details) {
        assert(dragStartPos == null);
        setState(() {
          dragStartPos = details.localPosition;
          dragShift = Offset.zero;
        });
      },
      onPanUpdate: (DragUpdateDetails details) {
        setState(() {
          dragShift = details.localPosition - dragStartPos!;
        });
      },
      onPanEnd: (DragEndDetails details) {
        setState(() {
          countVote();
          dragStartPos = null;
          dragShift = null;
        });
      },
      child: CustomPaint(
        painter: VotingViewPainter(
          word: word!,
          state: getDragState(),
        ),
        child: Container(),
      ),
    );
  }
}
