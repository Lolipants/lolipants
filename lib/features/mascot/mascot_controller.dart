/// High-level mascot emotions for the Rive state machine's `state` input.
enum MascotState {
  /// Default resting loop.
  idle,

  /// Short triumphant reaction.
  celebrate,

  /// Empathic reaction when something fails or is cancelled.
  sad,
}
