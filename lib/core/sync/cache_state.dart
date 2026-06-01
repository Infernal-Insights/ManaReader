enum CacheState {
  remote,
  cached,
  evicted;

  String get value => name;
  static CacheState from(String s) => CacheState.values.byName(s);
}
