import 'piece.dart';
import 'practice_log.dart';

class Worksheet{
    String name;
    DateTime date;
    List<Piece> pieces;
    List<String> strategies;
    List<PracticeLog> checklist;

    Worksheet({
        required this.name,
        required this.date,
        required this.pieces,
        required this.strategies,
        required this.checklist,
    });
}