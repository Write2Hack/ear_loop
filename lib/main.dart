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
  int questionCount = 10;
  final TextEditingController _controller = TextEditingController();

  void _startExercise() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EarTrainingScreen(totalQuestions: questionCount)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Up Exercise")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("How many questions do you want?", style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter a number",
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  questionCount = int.tryParse(value) ?? 10;
                }
              },
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [10, 30, 50, 100].map((num) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      questionCount = num;
                    });
                    _startExercise();
                  },
                  child: Text("$num Questions"),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startExercise,
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
  int questionNumber = 0;
  String firstNote = '';
  String secondNote = '';
  bool showFeedback = false;
  bool isCorrect = false;

  @override
  void initState() {
    super.initState();
    _generateNewQuestion();
  }

  void _generateNewQuestion() {
    if (questionNumber >= widget.totalQuestions) {
      _showFinalScore();
      return;
    }

    setState(() {
      Random rand = Random();
      int firstIndex = rand.nextInt(notes.length);
      int secondIndex = rand.nextInt(notes.length);

      firstNote = notes[firstIndex];
      secondNote = notes[secondIndex];
      showFeedback = false;
    });

    Future.delayed(Duration(milliseconds: 500), _playNotes);
  }

  Future<void> _playNotes() async {
    await _audioPlayer.play(AssetSource('sounds/$firstNote.wav'));
    await Future.delayed(Duration(seconds: 1));
    await _audioPlayer.play(AssetSource('sounds/$secondNote.wav'));
  }

  void _playSingleNote(String note) async {
    await _audioPlayer.play(AssetSource('sounds/$note.wav'));
  }

  void _checkAnswer(String answer) {
    bool correctAnswer = (firstNote == secondNote && answer == 'Same') ||
        (notes.indexOf(firstNote) < notes.indexOf(secondNote) && answer == 'Up') ||
        (notes.indexOf(firstNote) > notes.indexOf(secondNote) && answer == 'Down');

    setState(() {
      questionNumber++;
      if (correctAnswer) {
        score++;
        isCorrect = true;
      } else {
        isCorrect = false;
      }
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
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text("Back to Start"),
          )
        ],
      ),
    );
  }

  void _nextQuestion() {
    _generateNewQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ear Training')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Did the pitch go up, down, or stay the same?", style: TextStyle(fontSize: 22)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _checkAnswer('Up'),
              child: Text("Up"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _checkAnswer('Down'),
              child: Text("Down"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _checkAnswer('Same'),
              child: Text("Same"),
            ),
            SizedBox(height: 20),
            if (showFeedback)
              Column(
                children: [
                  Text(
                    isCorrect ? "Correct!" : "Wrong!",
                    style: TextStyle(fontSize: 24, color: isCorrect ? Colors.green : Colors.red),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Notes played:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _playSingleNote(firstNote),
                        child: Text(firstNote),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _playSingleNote(secondNote),
                        child: Text(secondNote),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _nextQuestion,
                    child: Text("Next"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}