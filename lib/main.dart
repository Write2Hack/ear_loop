import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(EarTrainingApp());
}

class EarTrainingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ear Training',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: QuestionSetupScreen(),
    );
  }
}

class QuestionSetupScreen extends StatefulWidget {
  @override
  _QuestionSetupScreenState createState() => _QuestionSetupScreenState();
}

class _QuestionSetupScreenState extends State<QuestionSetupScreen> {
  int selectedQuestions = 10;
  final List<int> options = [10, 30, 50, 100];

  void startExercise() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EarTrainingScreen(totalQuestions: selectedQuestions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Up Exercise")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("How many questions?", style: TextStyle(fontSize: 22)),
            SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: options.map((q) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedQuestions = q;
                    });
                    startExercise();
                  },
                  child: Text("$q"),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Text("Or enter a number:"),
            SizedBox(height: 10),
            SizedBox(
              width: 80,
              child: TextField(
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  selectedQuestions = int.tryParse(val) ?? 10;
                },
                decoration: InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: startExercise,
              child: Text("Start"),
            ),
          ],
        ),
      ),
    );
  }
}

class EarTrainingScreen extends StatefulWidget {
  final int totalQuestions;

  EarTrainingScreen({required this.totalQuestions});

  @override
  _EarTrainingScreenState createState() => _EarTrainingScreenState();
}

class _EarTrainingScreenState extends State<EarTrainingScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<String> notes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  int score = 0;
  int currentQuestion = 0;
  String firstNote = '';
  String secondNote = '';
  String? selectedAnswer;
  bool showFeedback = false;

  @override
  void initState() {
    super.initState();
    _generateNewQuestion();
  }

  void _generateNewQuestion() {
    if (currentQuestion >= widget.totalQuestions) {
      _showFinalScore();
      return;
    }

    setState(() {
      Random rand = Random();
      int firstIndex = rand.nextInt(notes.length);
      int secondIndex = rand.nextInt(notes.length);

      firstNote = notes[firstIndex];
      secondNote = notes[secondIndex];
      selectedAnswer = null;
      showFeedback = false;
    });

    _playNotes();
  }

  Future<void> _playNotes() async {
    await _audioPlayer.play(AssetSource('sounds/$firstNote.wav'));
    await Future.delayed(Duration(seconds: 1));
    await _audioPlayer.play(AssetSource('sounds/$secondNote.wav'));
  }

  void _checkAnswer(String answer) {
    bool correctAnswer =
        (notes.indexOf(firstNote) < notes.indexOf(secondNote) && answer == 'Up') ||
        (notes.indexOf(firstNote) > notes.indexOf(secondNote) && answer == 'Down') ||
        (firstNote == secondNote && answer == 'Same');

    setState(() {
      if (correctAnswer) {
        score++;
      }
      selectedAnswer = answer;
      showFeedback = true;
    });
  }

  void _showFinalScore() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Exercise Complete"),
        content: Text("You got $score out of ${widget.totalQuestions} correct!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("OK"),
          )
        ],
      ),
    );
  }

  Widget _buildPianoKeyboard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: notes.map((note) {
        bool isFirst = note == firstNote;
        bool isSecond = note == secondNote;

        return Column(
          children: [
            Text(note, style: TextStyle(fontSize: 16)),
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () => _audioPlayer.play(AssetSource('sounds/$note.wav')),
                  child: Container(
                    width: 40,
                    height: 100,
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                    ),
                  ),
                ),
                if (isFirst) Text("1", style: TextStyle(fontSize: 24, color: Colors.red)),
                if (isSecond) Text("2", style: TextStyle(fontSize: 24, color: Colors.blue)),
              ],
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAnswerButton(String label) {
    bool isSelected = selectedAnswer == label;
    Color buttonColor = Colors.grey;
    if (isSelected) {
      buttonColor = (label == selectedAnswer && showFeedback)
          ? (selectedAnswer == "Up" && notes.indexOf(firstNote) < notes.indexOf(secondNote) ||
                  selectedAnswer == "Down" && notes.indexOf(firstNote) > notes.indexOf(secondNote) ||
                  selectedAnswer == "Same" && firstNote == secondNote)
              ? Colors.green
              : Colors.red
          : Colors.grey;
    }

    return ElevatedButton(
      onPressed: selectedAnswer == null ? () => _checkAnswer(label) : null,
      style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ear Training")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _playNotes,
                  child: Text("▶︎", style: TextStyle(fontSize: 28)),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildAnswerButton("Up"),
            _buildAnswerButton("Same"),
            _buildAnswerButton("Down"),
            SizedBox(height: 20),
            if (showFeedback) _buildPianoKeyboard(),
            if (showFeedback)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentQuestion++;
                  });
                  _generateNewQuestion();
                },
                child: Text("Next"),
              ),
          ],
        ),
      ),
    );
  }
}