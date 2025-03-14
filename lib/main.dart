import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(EarTrainingApp());
}

class EarTrainingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ear Training',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ear Training")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QuestionSetupScreen()),
                );
              },
              child: Text("Start Exercise"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PerformanceScreen()),
                );
              },
              child: Text("View Performance"),
            ),
          ],
        ),
      ),
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
  DateTime? questionStartTime;
  List<int> questionTimes = [];
  Map<String, List<int>> combinationTimes = {};
  Map<String, List<bool>> combinationAccuracy = {};

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
      questionStartTime = DateTime.now();
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

      // Track time taken for the question
      if (questionStartTime != null) {
        int timeTaken = DateTime.now().difference(questionStartTime!).inSeconds;
        questionTimes.add(timeTaken);

        // Track combination accuracy and time
        String combination = '$firstNote$secondNote';
        combinationTimes.putIfAbsent(combination, () => []).add(timeTaken);
        combinationAccuracy.putIfAbsent(combination, () => []).add(correctAnswer);
      }
    });
  }

  void _showFinalScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> performance = prefs.getStringList('accuracy') ?? [];
    performance.add((score / widget.totalQuestions * 100).toString());
    await prefs.setStringList('accuracy', performance);

    // Save average time per question
    double avgTime = questionTimes.isNotEmpty ? questionTimes.reduce((a, b) => a + b) / questionTimes.length : 0;
    List<String> avgTimes = prefs.getStringList('avg_time') ?? [];
    avgTimes.add(avgTime.toString());
    await prefs.setStringList('avg_time', avgTimes);

    // Save combination accuracy and time
    List<String> combinationData = [];
    combinationAccuracy.forEach((combination, accuracies) {
      double accuracy = accuracies.where((a) => a).length / accuracies.length * 100;
      double avgTime = combinationTimes[combination]!.reduce((a, b) => a + b) / combinationTimes[combination]!.length;
      combinationData.add('$combination,$accuracy,$avgTime');
    });
    await prefs.setStringList('combination_data', combinationData);

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

  Widget _buildAnswerButton(String label, IconData icon) {
    bool isSelected = selectedAnswer == label;
    bool isCorrect = (selectedAnswer == "Up" && firstNote != secondNote && notes.indexOf(firstNote) < notes.indexOf(secondNote)) ||
                     (selectedAnswer == "Down" && firstNote != secondNote && notes.indexOf(firstNote) > notes.indexOf(secondNote)) ||
                     (selectedAnswer == "Same" && firstNote == secondNote);

    Color buttonColor = Colors.grey;
    if (isSelected) {
      buttonColor = isCorrect ? Colors.green : Colors.red;
    }

    return GestureDetector(
      onTap: selectedAnswer == null ? () => _checkAnswer(label) : null,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: buttonColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 40, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = (currentQuestion + 1) / widget.totalQuestions;

    return Scaffold(
      appBar: AppBar(title: Text("Ear Training")),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress, minHeight: 8),
          Expanded(
            child: Center(
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
                  if (showFeedback) _buildPianoKeyboard(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnswerButton("Down", Icons.arrow_downward),
                _buildAnswerButton("Same", Icons.horizontal_rule),
                _buildAnswerButton("Up", Icons.arrow_upward),
              ],
            ),
          ),
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
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class PerformanceScreen extends StatelessWidget {
  Future<List<FlSpot>> _getPerformanceData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> performance = prefs.getStringList('accuracy') ?? [];
    return performance.asMap().entries.map((entry) {
      int index = entry.key;
      double value = double.parse(entry.value);
      return FlSpot(index.toDouble(), value);
    }).toList();
  }

  Future<List<FlSpot>> _getAvgTimeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> avgTimes = prefs.getStringList('avg_time') ?? [];
    return avgTimes.asMap().entries.map((entry) {
      int index = entry.key;
      double value = double.parse(entry.value);
      return FlSpot(index.toDouble(), value);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getCombinationData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> combinationData = prefs.getStringList('combination_data') ?? [];
    return combinationData.map((data) {
      var parts = data.split(',');
      return {
        'combination': parts[0],
        'accuracy': double.parse(parts[1]),
        'avgTime': double.parse(parts[2]),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Performance")),
      body: FutureBuilder<List<FlSpot>>(
        future: _getPerformanceData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: snapshot.data!,
                          isCurved: true,
                          barWidth: 4,
                          color: Colors.blue,
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 10,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text('${value.toInt()}%');
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text('${value.toInt()}');
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      gridData: FlGridData(show: true),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                FutureBuilder<List<FlSpot>>(
                  future: _getAvgTimeData(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    return Expanded(
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: snapshot.data!,
                              isCurved: true,
                              barWidth: 4,
                              color: Colors.red,
                              belowBarData: BarAreaData(show: false),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text('${value.toInt()}s');
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text('${value.toInt()}');
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          gridData: FlGridData(show: true),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getCombinationData(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    return Expanded(
                      child: ListView(
                        children: snapshot.data!.map((data) {
                          return ListTile(
                            title: Text('Combination: ${data['combination']}'),
                            subtitle: Text('Accuracy: ${data['accuracy']}%, Avg Time: ${data['avgTime']}s'),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}