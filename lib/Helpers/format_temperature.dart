String formatTemperature(double? celsius) {
  if (celsius == null) {
    return '—';
  }
  return '${celsius.round()} °C';
}
