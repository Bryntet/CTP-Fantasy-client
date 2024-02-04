import 'package:flutter/material.dart';
import 'package:multiselect/multiselect.dart';
import 'package:rusty_chains/home_page.dart';
import 'package:rusty_chains/tournament.dart';

import 'api.dart';
import 'api_classes.dart';

class TournamentsPage extends StatefulWidget {
  const TournamentsPage({super.key});

  @override
  _TournamentsPageState createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  Future<List<FantasyTournament>>? _futureTournaments;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _maxPicksController = TextEditingController();
  bool _showDeclined = false;
  final _userId = ApiService().getUserId();

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
                        builder: (context) => const CombinedLoginScreen(),
                        settings: const RouteSettings(name: '/login')));
                const SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: Colors.greenAccent, // success color
                );
                await ApiService().logout();
              },
              color: Colors.red,
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
              child: buildTournamentsFutureBuilder(),
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
            child: const Icon(Icons
                .refresh), // Required to use multiple FloatingActionButtons
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return buildCreateTournamentDialog();
                  },
                );
              },
              heroTag: null,
              child: const Icon(Icons.add)),
        ]));
  }

  FutureBuilder<List<FantasyTournament>> buildTournamentsFutureBuilder() {
    return FutureBuilder<List<FantasyTournament>>(
      future: _futureTournaments,
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
          print(snapshot.error);
          return const Center(child: Text('Error: :('));
        } else {
          return buildTournamentsListView(snapshot.data!);
        }
      },
    );
  }

  FutureBuilder<int> buildTournamentsListView(
      List<FantasyTournament> tournaments) {
    return FutureBuilder<int>(
      future: _userId,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return const Center(
            child: Text('Error fetching user ID'),
          );
        } else {
          int userId = snapshot.data!;
          return ListView.builder(
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              var tournament = tournaments[index];
              if (tournament.invitationStatus == InvitationStatus.declined &&
                  !_showDeclined) {
                return Container(); // Return an empty container for declined tournaments when _showDeclined is false
              }
              return ListTile(
                tileColor: tournament.invitationStatus ==
                        InvitationStatus.accepted
                    ? null
                    : tournament.invitationStatus == InvitationStatus.declined
                        ? Colors.red
                        : Colors.green,
                title: Text(tournament.name),
                trailing: SizedBox(
                  width: 50, // Specify your width here
                  child: userId == tournament.ownerUserId
                      ? const Icon(Icons.check_circle, color: Colors.yellow)
                      : Container(),
                ),
                onTap: () {
                  if (tournament.invitationStatus !=
                      InvitationStatus.declined) {
                    if (tournament.invitationStatus ==
                        InvitationStatus.pending) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return buildInvitationDialog(tournament);
                        },
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TournamentDetailsPage(
                            id: tournament.id,
                          ),
                          settings: RouteSettings(
                              name: '/tournament/${tournament.id}'),
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
    );
  }

  AlertDialog buildCreateTournamentDialog() {
    List<Division> selectedDivisions = []; // List to store selected divisions

    return AlertDialog(
      title: const Text('Create Fantasy Tournament'),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _maxPicksController,
                  decoration:
                      const InputDecoration(labelText: 'Max Picks Per User'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                DropDownMultiSelect(
                    onChanged: (List<String> selected) {
                      setState(() {
                        selectedDivisions = selected
                            .map((e) => Division.values.firstWhere((element) =>
                                element.toString().split('.').last == e))
                            .toList();
                      });
                    },
                    options: Division.values
                        .map((e) => e.toString().split('.').last)
                        .toList(),
                    selectedValues: selectedDivisions
                        .map((e) => e.toString().split('.').last)
                        .toList(),
                    isDense: false,
                    decoration: const InputDecoration(
                      labelText: 'Divisions',
                    )),
              ],
            ),
          );
        },
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Create'),
          onPressed: () async {
            if (_formKey.currentState?.validate() == true) {
              var tournament = FantasyTournamentInput(
                name: _nameController.text,
                maxPicksPerUser: int.tryParse(_maxPicksController.text),
                divisions: selectedDivisions,
              );
              Navigator.of(context).pop();

              await ApiService().createFantasyTournament(tournament);
              setState(() {
                _futureTournaments = ApiService().getFantasyTournaments();
              });
            }
          },
        )
      ],
    );
  }

  AlertDialog buildInvitationDialog(FantasyTournament tournament) {
    return AlertDialog(
      title: const Text('Invitation'),
      content: const Text('Do you want to accept the invitation?'),
      actions: <Widget>[
        TextButton(
          child: const Text('Accept', style: TextStyle(color: Colors.green)),
          onPressed: () async {
            await ApiService().answerInvitation(tournament.id, true);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TournamentDetailsPage(
                  id: tournament.id,
                ),
              ),
            );
            setState(() {
              _futureTournaments = _fetchTournaments();
            });
          },
        ),
        TextButton(
          child: const Text('Decline', style: TextStyle(color: Colors.red)),
          onPressed: () async {
            Navigator.pop(context);
            await ApiService().answerInvitation(tournament.id, false);
            setState(() {
              _futureTournaments = ApiService().getFantasyTournaments();
            });
          },
        ),
      ],
    );
  }
}
