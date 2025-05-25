// event_model.dart

class Event {
  final int id;
  final String organizerId;
  final int availableCount;
  final String date;
  final String eventName;
  final String eventType;
  final String location;
  final int price;
  final String imageUrl;
  final String description;
  final String venue;
  final int initialCount;
  final int ratingTotal;
  final int totalRaters;
  final int rating;

  Event({
    required this.id,
    required this.organizerId,
    required this.availableCount,
    required this.date,
    required this.eventName,
    required this.eventType,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.venue,
    required this.initialCount,
    required this.ratingTotal,
    required this.totalRaters,
    required this.rating,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int,
      organizerId: (json['organizerId'] ?? json['organizer_id']) as String,
      availableCount: (json['availableCount'] ?? json['available_count']) as int,
      date: json['date'] as String,
      eventName: (json['eventName'] ?? json['event_name']) as String,
      eventType: (json['eventType'] ?? json['event_type']) as String,
      location: json['location'] as String,
      price: json['price'] as int,
      imageUrl: (json['imageUrl'] ?? json['image_url'] ?? "") as String,
      description: json['description'] as String? ?? "",
      venue: json['venue'] as String? ?? "",
      initialCount: json['initialCount'] as int? ?? (json['availableCount'] ?? json['available_count']) as int,
      ratingTotal: json['ratingTotal'] ?? json['rating_total'] ?? 0,
      totalRaters: json['totalRaters'] ?? json['total_raters'] ?? 0,
      rating: json['rating'] ?? 0,
    );
  }
}
