import 'passage.dart';

class Piece {
    String name;
    String composer;
    int tempo;
    List<Passage> passages;
    String? source; //String? means it can be null

    Piece({
        required this.name,
        required this.composer,
        required this.tempo,
        required this.passages,
        this.source,
    });
}