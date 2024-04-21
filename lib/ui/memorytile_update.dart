import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/btn.dart';

class MemoryTileGameUpdate extends StatefulWidget {
  @override
  _MemoryTileGameState createState() => _MemoryTileGameState();
}

class _MemoryTileGameState extends State<MemoryTileGameUpdate> with TickerProviderStateMixin {
  late List<List<bool>> patternGrid;
  late List<List<bool>> inputGrid;
  int score = 0;
  int maxScore = 0;
  int attemptsLeft = 10;
  int currentLevel = 0;
  List<int> levelTiles = [4, 5, 6, 7, 8, 9, 10, 11, 12];
  List<int> levelRows = [5, 4, 4, 4, 5, 5, 5, 5, 5];
  List<int> levelCols = [6, 4, 5, 5, 5, 6, 6, 6, 6];
  late Timer timer;
  int durationInSeconds = 6;
  bool isShowingPattern = true;
  late int remainingTime;
  bool isGameOver = false;

  late AnimationController _flipAnimationController;
  late Animation<double> _flipAnimation;
  int _tappedRow = -1;
  int _tappedCol = -1;
  bool isCelebrating = false;
  bool isWrongGuess = false;
  bool canTap = true;
  late List<List<AnimationController>> _flipAnimationControllers;
  final player = AudioPlayer();
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    initializeGame();
    _flipAnimationControllers = List.generate(
      levelRows[currentLevel],
          (_) => List.generate(
        levelCols[currentLevel],
            (_) => AnimationController(
          vsync: this,
          duration: Duration(milliseconds: 500),
        ),
      ),
    );
    loadScore();
    currentLevel = getInitialLevel();
  }

  @override
  void dispose() {
    timer?.cancel();
    for (var rowControllers in _flipAnimationControllers) {
      for (var controller in rowControllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  int getInitialLevel() {
    if (score < 30) {
      return 0; // Beginner
    } else if (score < 60) {
      return 1; // Intermediate
    } else {
      return 2; // Advanced
    }
  }

  void initializeGame() {
    score = 0;
    maxScore = 0;
    attemptsLeft = 10;
    isGameOver = false;
    generatePattern();
    resetInputGrid();
    showPatternAndStartTimer();
  }

  void showPatternAndStartTimer() {
    isShowingPattern = true;
    generatePattern();
    resetInputGrid();
    startTimer();
  }

  Future<void> playCorrectSound() async {
    String audioPath = "audio/correct.mp3";
    await player.play(AssetSource(audioPath));
  }
  Future<void> playWrongSound() async {
    String audioPath = "audio/losing.mp3";
    await player.play(AssetSource(audioPath));
  }

  void startTimer() {
    remainingTime = durationInSeconds;
    canTap = false;
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          timer.cancel();
          isShowingPattern = false;
          startTileFlipAnimationForAll();
          canTap = true;
        }
      });
    });
  }

  void generatePattern() {
    Random random = Random();
    int rows = levelRows[currentLevel];
    int cols = levelCols[currentLevel];
    patternGrid = List.generate(rows, (_) => List.filled(cols, false));

    int tilesCount = min(levelTiles[currentLevel], rows * cols);
    maxScore += tilesCount;

    for (int i = 0; i < tilesCount; i++) {
      int row = random.nextInt(rows);
      int col = random.nextInt(cols);
      patternGrid[row][col] = true;
    }
  }

  void resetInputGrid() {
    int rows = levelRows[currentLevel];
    int cols = levelCols[currentLevel];
    inputGrid = List.generate(rows, (_) => List.filled(cols, false));
  }

  void checkAnswer() {
    int wrongCount = 0;
    for (int i = 0; i < inputGrid.length; i++) {
      for (int j = 0; j < inputGrid[i].length; j++) {
        if (inputGrid[i][j] != patternGrid[i][j]) {
          wrongCount++;
        }
      }
    }

    setState(() {
      if (wrongCount > 0) {
        playWrongSound();
        isWrongGuess = true;
        isCelebrating = false;
      } else {
        playCorrectSound();
        isCelebrating = true;
        isWrongGuess = false;
        score += 10;
      }
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        isCelebrating = false;
        isWrongGuess = false;
        attemptsLeft--;
        currentLevel = getInitialLevel();
        if (attemptsLeft == 0) {
          saveScore();
          isGameOver = true;
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Game Over"),
                content: Text("Your final score is $score out of 100."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      initializeGame();
                    },
                    child: Text("Restart"),
                  ),
                ],
              );
            },
          );
        } else {
          showPatternAndStartTimer();
        }
      });
    });
  }

  void startTileFlipAnimation(int row, int col) {
    _flipAnimationControllers[row][col].reset();
    _flipAnimationControllers[row][col].forward();
  }

  void startTileFlipAnimationForAll() {
    for (var rowControllers in _flipAnimationControllers) {
      for (var controller in rowControllers) {
        controller.reset();
      }
    }
    for (var rowControllers in _flipAnimationControllers) {
      for (var controller in rowControllers) {
        controller.forward();
      }
    }
  }

  Widget buildTile(int row, int col) {
    double tileSize = 50;

    if (row < patternGrid.length && col < patternGrid[row].length) {
      Color? tileColor = isShowingPattern
          ? (patternGrid[row][col] ? Colors.lightBlue[100] : Colors.grey[300])
          : (inputGrid[row][col] ? Colors.lightBlue[100] : Colors.grey[300]);

      if (!isShowingPattern && isWrongGuess && !patternGrid[row][col] && inputGrid[row][col]) {
        tileColor = Colors.red;
      }

      return GestureDetector(
        onTap: () {
          if (!isShowingPattern) {
            setState(() {
              inputGrid[row][col] = !inputGrid[row][col];
              startTileFlipAnimation(row, col);
            });
          }
        },
        child: AnimatedBuilder(
          animation: _flipAnimationControllers[row][col],
          builder: (context, child) {
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(isShowingPattern ? 0 : _flipAnimationControllers[row][col].value * pi),
              alignment: Alignment.center,
              child: Container(
                margin: EdgeInsets.all(2),
                width: tileSize,
                height: tileSize,
                decoration: BoxDecoration(
                  color: tileColor,
                  border: Border.all(color: Colors.brown, width: 2.0),
                ),
                child: Center(
                  child: Text(
                    '',
                    style: TextStyle(
                      fontSize: tileSize * 0.3,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      return Container();
    }
  }

  void saveScore() async {
    prefs = await SharedPreferences.getInstance();
    prefs.setInt('score', score);
  }

  void loadScore() async {
    prefs = await SharedPreferences.getInstance();
    int? savedScore = prefs.getInt('score');
    if (savedScore != null) {
      setState(() {
        score = savedScore;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFFFF8E1),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 36.0, 8.0, 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.75,
                    child: Card(
                      elevation: 4,
                      margin: EdgeInsets.only(bottom: 20.0),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Brain Game',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.orange,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Short term memory',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Click on the squares that were blue',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                              ),
                            ),
                            Divider(),
                            SizedBox(height: 20),
                            Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.brown,
                                    width: 5.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Center(
                                  child: Container(
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: levelCols[currentLevel],
                                        childAspectRatio: 1.0,
                                      ),
                                      itemBuilder: (BuildContext context, int index) {
                                        int row = index ~/ levelCols[currentLevel];
                                        int col = index % levelCols[currentLevel];
                                        return SizedBox(
                                          width: 50, // Fixed tile size
                                          height: 50, // Fixed tile size
                                          child: buildTile(row, col),
                                        );
                                      },
                                      itemCount: levelRows[currentLevel] * levelCols[currentLevel],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            isShowingPattern
                                ? Center(
                              child: Container(
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.timer, color: Colors.lightGreen),
                                    SizedBox(width: 4),
                                    Text(
                                      '$remainingTime',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'sec. left to remember the pattern.',
                                      style: GoogleFonts.poppins(fontSize: 16,),
                                    ),
                                  ],
                                ),
                              ),
                            )
                                : SizedBox(),


                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RectangularButton(
                          onPressed: () {
                            // Add functionality for back button
                          },
                          text: 'Back',
                          color: Colors.white,
                          btnText: Colors.black87,
                        ),
                        SizedBox(
                          width: 100,
                          height: 60,
                          child: Container(
                            padding: EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.lightBlue[100],
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: Colors.lightBlueAccent, width: 0),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.stars, color: Colors.orange, size: 18),
                                Text(
                                  '$score',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                        RectangularButton(
                          onPressed: () {
                            if (!isShowingPattern) {
                              checkAnswer();
                            }
                          },
                          text: 'Next',
                          color: Colors.orange,
                          btnText: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isCelebrating)
              Positioned.fill(
                child: Center(
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 100,
                  ),
                ),
              ),
            if (isWrongGuess)
              Positioned.fill(
                child: Center(
                  child: Icon(
                    Icons.clear_rounded,
                    color: Colors.red,
                    size: 100,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
