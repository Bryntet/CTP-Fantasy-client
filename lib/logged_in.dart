import 'package:flutter/material.dart';
import 'package:rusty_chains/home_page.dart';
import 'package:rusty_chains/tournament.dart';
import 'api.dart';
import 'api-classes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<FantasyTournament>>? _futureTournaments;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _maxPicksController = TextEditingController();
  bool _showDeclined = false;

  @override
  void initState() {
    super.initState();
    _maxPicksController.text = "3";
    _futureTournaments =
        _fetchTournaments(); // Use ApiService().getFantasyTournaments
  }

  Future<List<FantasyTournament>> _fetchTournaments() {
    return ApiService().getFantasyTournaments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Fantasy Tournaments'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CombinedLoginScreen()));
                const SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: Colors.greenAccent, // success color
                );
                await ApiService().logout();
              },
            )
          ],
        ),
        body: Column(
          children: [
            CheckboxListTile(
              title: const Text("Show Declined"),
              value: _showDeclined,
              onChanged: (bool? value) {
                setState(() {
                  _showDeclined = value!;
                });
              },
            ),
            Expanded(
              child: FutureBuilder<List<FantasyTournament>>(
                future: _futureTournaments,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    print(snapshot.error);
                    return const Center(child: Text('Error: :('));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        var tournament = snapshot.data![index];
                        if (tournament.invitationStatus ==
                                InvitationStatus.Declined &&
                            !_showDeclined) {
                          return Container(); // Return an empty container for declined tournaments when _showDeclined is false
                        }
                        return ListTile(
                          tileColor: tournament.invitationStatus ==
                                  InvitationStatus.Accepted
                              ? null
                              : tournament.invitationStatus ==
                                      InvitationStatus.Declined
                                  ? Colors.red
                                  : Colors.green,
                          title: Text(tournament.name),
                          trailing: tournament.userIsOwner
                              ? const Icon(Icons.check_circle, color: Colors.yellow)
                              : null,
                          onTap: () {
                            if (tournament.invitationStatus !=
                                InvitationStatus.Declined) {
                              if (tournament.invitationStatus ==
                                  InvitationStatus.Pending) {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Invitation'),
                                      content: const Text(
                                          'Do you want to accept the invitation?'),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text('Accept',
                                              style: TextStyle(
                                                  color: Colors.green)),
                                          onPressed: () async {
                                            await ApiService().answerInvitation(
                                                tournament.id, true);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TournamentDetailsPage(
                                                        tournament: tournament),
                                              ),
                                            );
                                            setState(() {
                                              _futureTournaments =
                                                  _fetchTournaments();
                                            });
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('Decline',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                          onPressed: () async {
                                            await ApiService().answerInvitation(
                                                tournament.id, false);
                                            Navigator.pop(context);
                                            setState(() {
                                              _futureTournaments = ApiService()
                                                  .getFantasyTournaments();
                                            });
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TournamentDetailsPage(
                                        tournament: tournament),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
        floatingActionButton:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _futureTournaments = _fetchTournaments();
              });
            },
            heroTag: null,
            child: const Icon(Icons.refresh), // Required to use multiple FloatingActionButtons
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Create Fantasy Tournament'),
                      content: Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              controller: _nameController,
                              decoration:
                                  const InputDecoration(labelText: 'Name'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a name';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _maxPicksController,
                              decoration: const InputDecoration(
                                  labelText: 'Max Picks Per User'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null &&
                                    int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Create'),
                          onPressed: () async {
                            if (_formKey.currentState?.validate() == true) {
                              var tournament = FantasyTournamentInput(
                                name: _nameController.text,
                                maxPicksPerUser:
                                    int.tryParse(_maxPicksController.text),
                              );
                              Navigator.of(context).pop();

                              await ApiService()
                                  .createFantasyTournament(tournament);
                              setState(() {
                                _futureTournaments = ApiService()
                                    .getFantasyTournaments(); // Use ApiService().createFantasyTournament
                              });

                              // Refresh the list of tournaments
                            }
                          },
                        )
                      ],
                    );
                  },
                );
              },
              heroTag: null,
              child: const Icon(Icons.add)),
        ]));
  }
}
