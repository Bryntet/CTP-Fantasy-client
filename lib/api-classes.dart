class FantasyTournamentInput {
  String name;
  int? maxPicksPerUser;

  FantasyTournamentInput({required this.name, this.maxPicksPerUser});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (maxPicksPerUser != null) {
      data['max_picks_per_user'] = maxPicksPerUser;
    }
    return data;
  }
}

enum InvitationStatus { Pending, Accepted, Declined }

class FantasyTournament {
  final int id;
  final String name;
  final bool userIsOwner;
  final InvitationStatus invitationStatus;

  FantasyTournament(
      {required this.id,
      required this.name,
      required this.userIsOwner,
      required this.invitationStatus});

  factory FantasyTournament.fromJson(Map<String, dynamic> json) {
    return FantasyTournament(
      id: json['id'],
      name: json['name'],
      userIsOwner: json["user_is_owner"],
      invitationStatus: InvitationStatus.values.firstWhere(
          (e) =>
              e.toString() == 'InvitationStatus.' + json['invitation_status'],
          orElse: () => throw Exception('Invalid invitation status')),
    );
  }
}

class Participant {
  final int id;
  final String name;
  final int score;

  Participant({required this.id, required this.name, required this.score});

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as int,
      name: json['name'] as String,
      score: json['score'] as int,
    );
  }
}
