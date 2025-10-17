// lib/dashboard/models.dart
class FinancePoint {
  final String month; // ex: '2025-06'
  final double receivable;
  final double payable;
  FinancePoint(this.month, this.receivable, this.payable);
}

class TicketStatusCounts {
  final int open;
  final int inProgress;
  final int closed;
  TicketStatusCounts(
      {required this.open, required this.inProgress, required this.closed});
}

class ChatsDailyPoint {
  final DateTime date;
  final int openChats;
  ChatsDailyPoint(this.date, this.openChats);
}
