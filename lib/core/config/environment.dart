enum Environment {
  mock('https://api.salli.lk', ''),
  staging('https://staging-api.salli.lk', String.fromEnvironment('SALLI_SPKI_PINS'));

  final String baseUrl;
  final String pinList;

  const Environment(this.baseUrl, this.pinList);

  Set<String> get pins => {
    for (final pin in pinList.split(','))
      if (pin.trim().isNotEmpty) pin.trim(),
  };
}
