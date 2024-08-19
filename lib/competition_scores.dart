import 'dart:developer';

import 'package:flutter/material.dart';

import 'api.dart';
import 'api_classes.dart';

class CompetitionScoresPage extends StatefulWidget {
  final int fantasyTournamentId;
  final int competitionId;

  const CompetitionScoresPage({
    Key? key,
    required this.fantasyTournamentId,
    required this.competitionId,
  }) : super(key: key);

  @override
  _CompetitionScoresPageState createState() => _CompetitionScoresPageState();
}

class _CompetitionScoresPageState extends State<CompetitionScoresPage> {
  late Future<List<UserCompetitionScore>> futureScores;

  @override
  void initState() {
    super.initState();
    futureScores = ApiService().getUserCompetitionScores(
      widget.fantasyTournamentId,
      widget.competitionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scores from Competition: ${widget.competitionId}'),
      ),
      body: FutureBuilder<List<UserCompetitionScore>>(
        future: futureScores,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeCap: StrokeCap.round,
                ),
              ),
            );
          } else if (snapshot.hasError) {
            log("${snapshot}");
            return Text("${snapshot.error}");
          } else {
            List<UserCompetitionScore> scores = snapshot.data!;
            scores.sort(
                (a, b) => b.scores.total_score.compareTo(a.scores.total_score));
            return ListView.builder(
              itemCount: scores.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    ListTile(
                      title: Text(scores[index].user.name),
                      subtitle: Text(
                          'Total Score: ${scores[index].scores.total_score}'),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: scores[index].scores.player_scores.length,
                      itemBuilder: (context, scoreIndex) {
                        return ListTile(
                          title: Text(
                              '${scores[index].scores.player_scores[scoreIndex].player.name} - ${scores[index].scores.player_scores[scoreIndex].placement}'),
                          subtitle: Text(
                              'Score: ${scores[index].scores.player_scores[scoreIndex].score}'),
                          contentPadding: const EdgeInsets.only(
                              left: 40), // Indent the player scores
                        );
                      },
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }
}
