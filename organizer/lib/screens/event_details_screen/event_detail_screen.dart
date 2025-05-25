import 'package:flutter/material.dart';
import '../../model/event_model.dart';
import '../event_edit_screen/edit_event_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;
  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: CustomScrollView(
        slivers: [
          // Modern SliverAppBar with a Hero image and multi-stop gradient overlay.
          SliverAppBar(
            backgroundColor:  Colors.grey[900],
            iconTheme: const IconThemeData(color: Colors.white),
            expandedHeight: 280,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditEventScreen(event: event),
                    ),
                  );
                  if (updated == true) {
                    Navigator.pop(context, true);
                  }
                },
                tooltip: 'Edit Event',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                event.eventName,
                style: textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              background: ClipRRect(
                clipBehavior: Clip.hardEdge,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Hero widget for a smooth image transition.
                    Hero(
                      tag: event.imageUrl,
                      child: event.imageUrl.isNotEmpty
                          ? Image.network(
                              event.imageUrl,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey[700],
                              child: const Icon(
                                Icons.event,
                                size: 100,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    // Gradient overlay for a modern look.
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Details section wrapped in a rounded container with chips for metadata.
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display key event metadata using chips.
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          event.eventType,
                          style: textTheme.bodySmall?.copyWith(color: Colors.white),
                        ),
                        backgroundColor: Colors.deepPurple,
                      ),
                      Chip(
                        label: Text(
                          event.date,
                          style: textTheme.bodySmall?.copyWith(color: Colors.white),
                        ),
                        backgroundColor: Colors.deepPurple,
                      ),
                      Chip(
                        label: Text(
                          "\$${event.price}",
                          style: textTheme.bodySmall?.copyWith(color: Colors.white),
                        ),
                        backgroundColor: Colors.deepPurple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(context, "Available Count", event.availableCount.toString()),
                  _buildDetailRow(context, "Location", event.location),
                  _buildDetailRow(context, "Venue", event.venue),
                  const SizedBox(height: 24),
                  Text(
                    "Description",
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description.isNotEmpty
                        ? event.description
                        : "No description provided.",
                    style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
