import ChessKit
import GameKit
import Observation
import UIKit

/// Game Center payload: UCI moves and White’s player ID.
struct OnlineMatchData: Codable, Sendable {
  var moves: [String]
  var whiteID: String
}

/// One online game as the friends list shows it.
struct OnlineSummary: Identifiable, Equatable {
  enum State: Equatable { case yourMove, theirMove, invited, won, lost, drawn }
  let id: String
  let opponent: String
  let state: State
  let updated: Date

  var label: String {
    switch state {
    case .yourMove: "Your move"
    case .theirMove: "Their move"
    case .invited: "Waiting for them to join"
    case .won: "You won"
    case .lost: "You lost"
    case .drawn: "Draw"
    }
  }

  var finished: Bool { [.won, .lost, .drawn].contains(state) }
}

/// Games against friends through Game Center: sign-in, the invite sheet, turn events, and
/// sending each move. The open game lives in `store`, the same GameStore the board uses.
@MainActor
@Observable
final class OnlineGames: NSObject {
  enum Status: Equatable { case unknown, signedIn, signedOut, unavailable(String) }

  private(set) var status = Status.unknown
  private(set) var summaries: [OnlineSummary] = []
  private(set) var busy = false
  /// A sentence to show when online play can't start (signed out, offline).
  var problem: String?
  /// Bumped when Game Center asks to show a game (an invite accepted, a turn notification tapped).
  private(set) var presentRequest = 0
  let store: GameStore

  private var matches: [String: GKTurnBasedMatch] = [:]
  private var openID: String?
  private weak var matchmaker: UIViewController?

  /// Seconds allowed for each turn.
  static let turnTimeout: TimeInterval = 24 * 60 * 60

  init(history: History) {
    store = GameStore(mode: .online, history: history)
    super.init()
    store.onlineSubmit = { [weak self] saved in self?.submit(saved) }
    store.onlineResign = { [weak self] in self?.resign() }
    store.onlineRematch = { [weak self] in self?.rematch() }
  }

  var yourMoveCount: Int { summaries.filter { $0.state == .yourMove }.count }

  // MARK: Sign-in

  /// Game Center's sign-in: shows Apple's sheet when needed, else signs in quietly.
  func authenticate() {
    GKLocalPlayer.local.authenticateHandler = { [weak self] controller, error in
      let failure = error.map(Self.explain)
      Task { @MainActor in
        guard let self else { return }
        if let controller {
          Presenter.present(controller)
          return
        }
        if GKLocalPlayer.local.isAuthenticated {
          self.status = .signedIn
          GKLocalPlayer.local.register(self)
          await self.refresh()
        } else {
          self.status = failure ?? .signedOut
        }
      }
    }
  }

  /// GameKit's errors, said plainly: signed out, this app unknown to Game Center, or offline.
  nonisolated private static func explain(_ error: Error) -> Status {
    switch (error as? GKError)?.code {
    case .notAuthenticated?, .cancelled?, .userDenied?, .notAuthorized?, .parentalControlsBlocked?:
      .signedOut
    case .gameUnrecognized?, .invalidPlayer?:
      .unavailable("Game Center doesn't recognise this app yet.")
    case .communicationsFailure?, .connectionTimeout?:
      .unavailable("Check your connection and try again.")
    default:
      .unavailable("Game Center couldn't be reached.")
    }
  }

  // MARK: Invites and games

  /// The Online tile's tap: Apple's invite sheet, or the reason it can't open yet.
  func startInvite() {
    switch status {
    case .signedIn:
      invite()
    case .signedOut, .unknown:
      problem = "Sign in to Game Center in the Settings app, then try again."
      authenticate()
    case let .unavailable(message):
      problem = message
      authenticate()
    }
  }

  /// Apple's friend picker, invite-only: Game Center friends, recent players, or Messages.
  func invite() {
    let request = GKMatchRequest()
    request.minPlayers = 2
    request.maxPlayers = 2
    request.inviteMessage = "Let's play a game of chess."
    let controller = GKTurnBasedMatchmakerViewController(matchRequest: request)
    controller.turnBasedMatchmakerDelegate = self
    controller.showExistingMatches = false
    controller.matchmakingMode = .inviteOnly
    matchmaker = controller
    Presenter.present(controller)
  }

  /// Reloads the match list and, if still present, the open game.
  func refresh() async {
    guard GKLocalPlayer.local.isAuthenticated else { return }
    let loaded = (try? await GKTurnBasedMatch.loadMatches()) ?? []
    matches = Dictionary(loaded.map { ($0.matchID, $0) }, uniquingKeysWith: { first, _ in first })
    summaries = loaded.map(summary).sorted { order($0) < order($1) }
    if let openID, let match = matches[openID] { await load(match) }
  }

  /// Opens a game on the board.
  func open(_ id: String) async {
    guard let match = matches[id] else { return }
    openID = id
    await load(match)
  }

  /// Removes a match for this player; callers must restrict this to finished games.
  func remove(_ id: String) async {
    guard let match = matches[id] else { return }
    try? await match.remove()
    await refresh()
  }

  // MARK: The open game

  private func load(_ match: GKTurnBasedMatch) async {
    let data = (try? await match.loadMatchData()).flatMap { try? JSONDecoder().decode(OnlineMatchData.self, from: $0) }
    let me = GKLocalPlayer.local.gamePlayerID
    // Before the first payload, assume the first participant is White; fall back to us.
    let whiteID = data?.whiteID ?? match.participants.first?.player?.gamePlayerID ?? me
    let you: Piece.Color = whiteID == me ? .white : .black
    let mine = match.participants.first { $0.player?.gamePlayerID == me }
    let theirs = match.participants.first { $0.player?.gamePlayerID != me }
    var saved = SavedGame(
      you: you, level: .medium, timeControl: .none,
      startedAt: match.creationDate, lastMoveAt: theirs?.lastTurnDate ?? match.creationDate,
      whiteLeft: 0, blackLeft: 0)
    saved.moves = data?.moves ?? []
    saved.ending = Self.ending(mine: mine, theirs: theirs, you: you)
    // Online games stay out of the streak and Stats.
    saved.recorded = true
    store.loadOnline(
      saved,
      opponent: theirs?.player?.displayName ?? "Your friend",
      waiting: match.currentParticipant?.player?.gamePlayerID != me || match.status != .open)
    // Finalise an external ending only when Game Center gives us the turn.
    if saved.ending != nil, match.status == .open, match.currentParticipant?.player?.gamePlayerID == me {
      await endMatch(match, saved: saved)
    }
  }

  /// An ending the board can't see from the moves: a resignation or a turn left too long.
  private static func ending(mine: GKTurnBasedParticipant?, theirs: GKTurnBasedParticipant?, you: Piece.Color) -> SavedGame.Ending? {
    switch theirs?.matchOutcome {
    case .quit?: return .resigned(you.opposite)
    case .timeExpired?: return .flagged(you.opposite)
    default: break
    }
    switch mine?.matchOutcome {
    case .quit?: return .resigned(you)
    case .timeExpired?: return .flagged(you)
    default: return nil
    }
  }

  private func submit(_ saved: SavedGame) {
    guard let openID, let found = matches[openID] else { return }
    nonisolated(unsafe) let match = found
    Task {
      busy = true
      defer { busy = false }
      if store.isOver {
        await endMatch(match, saved: saved)
      } else {
        let others = match.participants.filter { $0.player?.gamePlayerID != GKLocalPlayer.local.gamePlayerID }
        try? await match.endTurn(withNextParticipants: others, turnTimeout: Self.turnTimeout, match: encode(saved))
      }
      await refresh()
    }
  }

  private func endMatch(_ match: GKTurnBasedMatch, saved: SavedGame) async {
    let me = GKLocalPlayer.local.gamePlayerID
    for participant in match.participants where participant.matchOutcome == .none {
      let isMe = participant.player?.gamePlayerID == me
      participant.matchOutcome = switch store.result {
      case .win?: isMe ? .won : .lost
      case .loss?: isMe ? .lost : .won
      default: .tied
      }
    }
    try? await match.endMatchInTurn(withMatch: encode(saved))
  }

  private func resign() {
    guard let openID, let found = matches[openID] else { return }
    nonisolated(unsafe) let match = found
    Task {
      let me = GKLocalPlayer.local.gamePlayerID
      if match.currentParticipant?.player?.gamePlayerID == me {
        for participant in match.participants {
          participant.matchOutcome = participant.player?.gamePlayerID == me ? .quit : .won
        }
        if let saved = store.saved { try? await match.endMatchInTurn(withMatch: encode(saved)) }
      } else {
        try? await match.participantQuitOutOfTurn(with: .quit)
      }
      await refresh()
    }
  }

  private func rematch() {
    guard let openID, let found = matches[openID] else { return }
    nonisolated(unsafe) let match = found
    Task {
      guard let next = try? await match.rematch() else { return }
      await refresh()
      await open(next.matchID)
    }
  }

  private func encode(_ saved: SavedGame) -> Data {
    let whiteID = saved.you == .white ? GKLocalPlayer.local.gamePlayerID : (matches[openID ?? ""]?.participants.first { $0.player?.gamePlayerID != GKLocalPlayer.local.gamePlayerID }?.player?.gamePlayerID ?? "")
    return (try? JSONEncoder().encode(OnlineMatchData(moves: saved.moves, whiteID: whiteID))) ?? Data()
  }

  // MARK: The list

  private func summary(_ match: GKTurnBasedMatch) -> OnlineSummary {
    let me = GKLocalPlayer.local.gamePlayerID
    let mine = match.participants.first { $0.player?.gamePlayerID == me }
    let theirs = match.participants.first { $0.player?.gamePlayerID != me }
    let state: OnlineSummary.State = switch (match.status, mine?.matchOutcome) {
    case (.ended, .won?): .won
    case (.ended, .lost?), (.ended, .quit?), (.ended, .timeExpired?): .lost
    case (.ended, _): .drawn
    default:
      if match.currentParticipant?.player?.gamePlayerID == me { .yourMove }
      else if theirs?.status == .invited || theirs?.status == .matching { .invited }
      else { .theirMove }
    }
    return OnlineSummary(
      id: match.matchID,
      opponent: theirs?.player?.displayName ?? "Invited friend",
      state: state,
      updated: [mine?.lastTurnDate, theirs?.lastTurnDate, match.creationDate].compactMap { $0 }.max() ?? match.creationDate)
  }

  /// Your turns first, finished games last; newest first within each group.
  private func order(_ summary: OnlineSummary) -> (Int, TimeInterval) {
    let rank = switch summary.state {
    case .yourMove: 0
    case .theirMove, .invited: 1
    default: 2
    }
    return (rank, -summary.updated.timeIntervalSince1970)
  }

  fileprivate func show(_ match: GKTurnBasedMatch) {
    matches[match.matchID] = match
    matchmaker?.dismiss(animated: true)
    matchmaker = nil
    Task {
      await open(match.matchID)
      await refresh()
      presentRequest += 1
    }
  }
}

// MARK: Game Center callbacks

extension OnlineGames: GKLocalPlayerListener {
  nonisolated func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
    nonisolated(unsafe) let match = match
    Task { @MainActor in
      // Opened from an invite or a notification, or a new match from the picker: show it.
      if didBecomeActive || self.matchmaker != nil { self.show(match) } else { await self.refresh() }
    }
  }

  nonisolated func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
    Task { @MainActor in await self.refresh() }
  }

  nonisolated func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) {
    nonisolated(unsafe) let match = match
    Task { @MainActor in
      self.openID = match.matchID
      self.matches[match.matchID] = match
      self.resign()
    }
  }
}

extension OnlineGames: GKTurnBasedMatchmakerViewControllerDelegate {
  nonisolated func turnBasedMatchmakerViewControllerWasCancelled(_ viewController: GKTurnBasedMatchmakerViewController) {
    Task { @MainActor in
      self.matchmaker?.dismiss(animated: true)
      self.matchmaker = nil
    }
  }

  nonisolated func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFailWithError error: Error) {
    let message = error.localizedDescription
    Task { @MainActor in
      self.matchmaker?.dismiss(animated: true)
      self.matchmaker = nil
      self.status = .unavailable(message)
    }
  }
}

/// Presents above the topmost controller in the first connected scene with a key window.
@MainActor
enum Presenter {
  static func present(_ controller: UIViewController) {
    let root = UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.keyWindow }
      .first?.rootViewController
    var top = root
    while let presented = top?.presentedViewController { top = presented }
    top?.present(controller, animated: true)
  }
}
