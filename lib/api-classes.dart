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
  final int ownerUserId;
  final InvitationStatus invitationStatus;

  FantasyTournament(
      {required this.id,
      required this.name,
      required this.ownerUserId,
      required this.invitationStatus});

  factory FantasyTournament.fromJson(Map<String, dynamic> json) {
    return FantasyTournament(
      id: json['id'],
      name: json['name'],
      ownerUserId: json["owner_id"],
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

class Pick {
  int slot;
  int pdgaNumber;
  String name;

  Pick({required this.slot, required this.pdgaNumber, required this.name});

  factory Pick.fromJson(Map<String, dynamic> json) {
    return Pick(
        slot: json['slot'] as int,
        pdgaNumber: json['pdga_number'] as int,
        name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {
      'slot': slot,
      'pdga_number': pdgaNumber,
      'name': name,
    };
  }

  static Pick empty(int slot) {
    return Pick(slot: slot, pdgaNumber: slot, name: ' ' * slot);
  }
}

class Picks {
  List<Pick> picks;
  final bool owner;
  final int fantasyTournamentId;

  Picks({
    required this.picks,
    required this.owner,
    required this.fantasyTournamentId,
  });

  factory Picks.fromJson(Map<String, dynamic> json) {
    return Picks(
      picks: (json['picks'] as List<dynamic>)
          .map((item) => Pick.fromJson(item as Map<String, dynamic>))
          .toList(),
      owner: json['owner'] as bool,
      fantasyTournamentId: json['fantasy_tournament_id'] as int,
    );
  }
}
