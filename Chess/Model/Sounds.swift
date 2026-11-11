import AVFoundation

/// Plays cues on a serial queue to keep audio setup off the main thread.
/// The ambient session mixes with music and respects the silent switch and Sounds setting.
enum Sounds {
  enum Cue: String, CaseIterable, Sendable { case move, capture, end }

  static func play(_ cue: Cue) {
    guard UserDefaults.standard.object(forKey: Pref.sounds) as? Bool ?? true else { return }
    Bank.shared.play(cue)
  }

  /// Loads the players ahead of the first move, off the main thread.
  static func warmUp() { Bank.shared.load() }

  /// Player and load state are confined to `queue`, justifying unchecked Sendable.
  private final class Bank: @unchecked Sendable {
    static let shared = Bank()
    private let queue = DispatchQueue(label: "chess.sounds", qos: .userInitiated)
    private var players: [Cue: AVAudioPlayer] = [:]
    private var loaded = false

    func load() { queue.async { self.loadOnQueue() } }

    func play(_ cue: Cue) {
      queue.async {
        self.loadOnQueue()
        guard let player = self.players[cue] else { return }
        player.currentTime = 0
        player.play()
      }
    }

    private func loadOnQueue() {
      guard !loaded else { return }
      loaded = true
      try? AVAudioSession.sharedInstance().setCategory(.ambient)
      for cue in Cue.allCases {
        guard let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url) else { continue }
        player.prepareToPlay()
        players[cue] = player
      }
    }
  }
}
