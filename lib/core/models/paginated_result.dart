class PaginatedResult<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  // Optional metadata, e.g. for keeping track of raw data if really needed,
  // but ideally we should map everything to the domain model.
  // For ChatList, we had 'rawConversations' to access lastMessageId.
  // We should try to move that into the Chat model or a separate field if it doesn't fit.
  final Map<String, dynamic>? metadata;

  PaginatedResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    this.metadata,
  });

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT, {
    String itemsKey = 'items',
    String? metadataKey,
  }) {
    final pagination = json['pagination'] as Map<String, dynamic>;

    return PaginatedResult<T>(
      items: (json[itemsKey] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int,
      metadata: metadataKey != null ? json[metadataKey] as Map<String, dynamic>? : null,
    );
  }
}
