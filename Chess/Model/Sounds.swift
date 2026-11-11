import AVFoundation

enum Sounds {
  enum Cue: String, CaseIterable, Sendable { case move, capture, end }

  static func play(_ cue: Cue) {
    guard UserDefaults.standard.object(forKey: Pref.sounds) as? Bool ?? true else { return }
    Bank.shared.play(cue)
  }

  static func warmUp() { Bank.shared.load() }

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
