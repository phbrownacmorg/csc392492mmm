import 'package:flutter/material.dart';
import 'main.dart';

class WorksheetControl {

  // Piece must be selected before tempo can be edited
  static bool canEditTempo(PracticeRowData row) {
    return row.pieceController.text.trim().isNotEmpty;
  }

  // Passage requires piece first
  static bool canEditPassage(PracticeRowData row) {
    return row.pieceController.text.trim().isNotEmpty;
  }

  // Problems require passage first
  static bool canSelectProblems(PracticeRowData row) {
    return row.passageController.text.trim().isNotEmpty;
  }

  // Strategy requires at least one problem
  static bool canSelectStrategy(PracticeRowData row) {
    return row.selectedProblems.isNotEmpty;
  }

  // Video upload requires strategy
  static bool canUploadVideo(PracticeRowData row) {
    return row.selectedStrategy != null;
  }

  // Mastery requires some practice data
  static bool canEditMastery(PracticeRowData row) {
    return totalPracticeMinutes(row) > 0;
  }

  static int totalPracticeMinutes(PracticeRowData row) {
    return _parse(row.monController.text) +
        _parse(row.tueController.text) +
        _parse(row.wedController.text) +
        _parse(row.thuController.text) +
        _parse(row.friController.text) +
        _parse(row.satController.text) +
        _parse(row.sunController.text);
  }

  static int _parse(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }
}
