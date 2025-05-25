class Ticket {
  final int id;
  final String eventId;
  final String userId;
  final String eventName;
  final int noOfTickets;
  final DateTime purchaseDate;
  final int totalPrice;
  final int unitPrice;

  Ticket({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.eventName,
    required this.noOfTickets,
    required this.purchaseDate,
    required this.totalPrice,
    required this.unitPrice,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as int,
      eventId: json['eventId'] ?? json['event_id'],
      userId: json['userId'] ?? json['user_id'],
      eventName: json['eventName'] ?? json['event_name'],
      noOfTickets: json['noOfTickets'] ?? json['no_of_tickets'],
      purchaseDate: DateTime.parse(json['purchaseDate'] ?? json['purchase_date']),
      totalPrice: json['totalPrice'] ?? json['total_price'],
      unitPrice: json['unitPrice'] ?? json['unit_price'],
    );
  }
}
