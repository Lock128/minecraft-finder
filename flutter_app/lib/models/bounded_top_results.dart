/// Collects items while retaining only the top [capacity] by a numeric score.
///
/// This keeps peak memory bounded during a search: instead of appending every
/// matching location to an unbounded list and sorting at the end (which can
/// exhaust memory on large-radius searches and get the process OOM-killed),
/// callers add candidates one at a time and only the highest-scoring
/// [capacity] items are ever held.
///
/// The internal list is kept sorted in descending score order, so [toList]
/// returns results ready for display without an extra sort. Insertion is a
/// linear scan, which is fine because [capacity] is small (<= a few hundred)
/// relative to the number of candidates scanned.
class BoundedTopResults<T> {
  BoundedTopResults(this.capacity, this._scoreOf)
      : assert(capacity > 0, 'capacity must be positive');

  /// Maximum number of items to retain.
  final int capacity;

  /// Extracts the score used for ranking (higher is better).
  final double Function(T) _scoreOf;

  final List<T> _items = <T>[];

  /// Total number of candidates offered via [add], regardless of whether they
  /// were retained. Lets callers report "top N of X found".
  int _totalOffered = 0;
  int get totalOffered => _totalOffered;

  /// Number of items currently retained.
  int get length => _items.length;

  /// Offers [item] to the collection. It is retained only if the collection is
  /// not yet full or its score beats the current lowest retained score.
  void add(T item) {
    _totalOffered++;

    final double score = _scoreOf(item);

    // Fast reject: full and this item is no better than the weakest kept item.
    if (_items.length >= capacity && score <= _scoreOf(_items.last)) {
      return;
    }

    // Find the insertion point that keeps _items sorted descending by score.
    int lo = 0;
    int hi = _items.length;
    while (lo < hi) {
      final int mid = (lo + hi) >> 1;
      if (_scoreOf(_items[mid]) >= score) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    _items.insert(lo, item);

    // Drop the weakest item(s) if we exceeded capacity.
    if (_items.length > capacity) {
      _items.removeLast();
    }
  }

  /// Returns the retained items, highest score first. Returns the internal
  /// list directly; callers should not mutate it after this call.
  List<T> toList() => _items;
}
