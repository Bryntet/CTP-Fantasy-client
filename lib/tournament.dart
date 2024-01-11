import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rusty_chains/user_picks.dart';
import 'api-classes.dart';
import 'api.dart';

class TournamentDetailsPage extends StatefulWidget {
  final FantasyTournament tournament;

  const TournamentDetailsPage({super.key, required this.tournament});

  @override
  _TournamentDetailsPageState createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage> {
  late Future<List<Participant>> futureParticipants;
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureParticipants =
        ApiService().getFantasyTournamentParticipants(widget.tournament.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Fantasy Tournament: \"${widget.tournament.name}\""),
      ),
      body: FutureBuilder<List<Participant>>(
        future: futureParticipants,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Participant> participants = snapshot.data!;
            participants.sort((a, b) => b.score.compareTo(a.score));
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
                            tournament: widget.tournament,
                            userId: participants[index].id,
                            username: participants[index].name,
                          ),
                        ),
                      );
                    });
              },
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return const CircularProgressIndicator();
        },
      ),
      floatingActionButton: widget.tournament.userIsOwner
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
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
                                await ApiService().inviteUser(
                                    widget.tournament.id,
                                    _userIdController.text);
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
                                      backgroundColor:
                                          Colors.red, // error color
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              tooltip: 'Invite User',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
