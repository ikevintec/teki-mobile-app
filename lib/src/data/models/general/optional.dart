class Optional<T> {
  final bool hasValue;
  final T? value;

  const Optional.absent() : hasValue = false, value = null;
  const Optional.of(this.value) : hasValue = true;

  static Optional<T> ofNullable<T>(T? value) =>
      value == null ? Optional.absent() : Optional.of(value);
}
