enum MobileOperator {
  airtel({'75'}),
  dialog({'74', '76', '77'}),
  hutch({'72', '78'}),
  mobitel({'70', '71'});

  final Set<String> prefixes;

  const MobileOperator(this.prefixes);

  static MobileOperator? forPrefix(String prefix) {
    for (final candidate in values) {
      if (candidate.prefixes.contains(prefix)) return candidate;
    }
    return null;
  }
}
