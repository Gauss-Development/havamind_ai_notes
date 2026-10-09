/// How the founder opened the concept screen.
enum ConceptResultEntry {
  /// Debrief of a pitch someone just heard. Rewrite waits for a label.
  pitchDebrief,

  /// A speech nobody has heard. Uses `rewrite_unheard`.
  coldPitch,

  /// Read the current speech and who already heard older ones.
  view,
}
