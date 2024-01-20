import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rusty_chains/user_picks.dart';

import 'api.dart';
import 'api_classes.dart';

class TournamentDetailsPage extends StatefulWidget {
  final int id;

  const TournamentDetailsPage({super.key, required this.id});

  @override
  _TournamentDetailsPageState createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage> {
  late Future<FantasyTournament> tournament;
  late Future<List<Participant>> futureParticipants;
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tournament = ApiService().getFantasyTournament(widget.id);
    futureParticipants =
        ApiService().getFantasyTournamentParticipants(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return buildTournamentFutureBuilder();
  }

  FutureBuilder<FantasyTournament> buildTournamentFutureBuilder() {
    return FutureBuilder<FantasyTournament>(
      future: tournament,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          FantasyTournament tournament = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: Text("Fantasy Tournament: \"${tournament.name}\""),
            ),
            body: buildParticipantsFutureBuilder(tournament),
            floatingActionButton: buildOwnerActionButton(tournament),
          );
        } else if (snapshot.hasError) {
          print(snapshot.error);
          return Text("${snapshot.error}");
        }
        return const CircularProgressIndicator();
      },
    );
  }

  FutureBuilder<List<Participant>> buildParticipantsFutureBuilder(
      FantasyTournament tournament) {
    return FutureBuilder<List<Participant>>(
      future: futureParticipants,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Participant> participants = snapshot.data!;
          participants.sort((a, b) => b.score.compareTo(a.score));
          return buildParticipantsListView(participants, tournament);
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return const CircularProgressIndicator();
      },
    );
  }

  ListView buildParticipantsListView(
      List<Participant> participants, FantasyTournament tournament) {
    return ListView.builder(
      itemCount: participants.length,
      itemBuilder: (context, index) {
        return ListTile(
            title: Text(participants[index].name),
            subtitle: Text('Score: ${participants[index].score}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserPicksPage(
                    tournament: tournament,
                    userId: participants[index].id,
                    username: participants[index].name,
                  ),
                ),
              );
            });
      },
    );
  }

  FutureBuilder<int> buildOwnerActionButton(FantasyTournament tournament) {
    return FutureBuilder<int>(
        future: ApiService().getUserId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            print(snapshot.error);
            return const Text('Error: :(');
          }
          if (snapshot.data == tournament.ownerUserId) {
            return FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return buildInviteUserDialog();
                  },
                );
              },
              tooltip: 'Invite User',
              child: const Icon(Icons.add),
            );
          }
          return Container();
        });
  }

  AlertDialog buildInviteUserDialog() {
    return AlertDialog(
      title: const Text('Invite User'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _userIdController,
          decoration: const InputDecoration(labelText: 'Username'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the username';
            }
            return null;
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Invite'),
          onPressed: () async {
            if (_formKey.currentState?.validate() == true) {
              try {
                FantasyTournament tournamentData = await tournament;
                await ApiService()
                    .inviteUser(tournamentData.id, _userIdController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User invited successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context); // Close the dialog
              } catch (e) {
                if (e is DioError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.response?.data),
                      backgroundColor: Colors.red, // error color
                    ),
                  );
                }
              }
            }
          },
        ),
      ],
    );
  }
}
