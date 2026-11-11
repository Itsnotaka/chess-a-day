import ChessKit
import GameKit
import Observation
import UIKit

struct OnlineMatchData: Codable, Sendable {
  var moves: [String]
  var whiteID: String
}

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

@MainActor
@Observable
final class OnlineGames: NSObject {
  enum Status: Equatable { case unknown, signedIn, signedOut, unavailable(String) }

  private(set) var status = Status.unknown
  private(set) var summaries: [OnlineSummary] = []
  private(set) var busy = false
  var problem: String?
  private(set) var presentRequest = 0
  let store: GameStore

  private var matches: [String: GKTurnBasedMatch] = [:]
  private var openID: String?
  private weak var matchmaker: UIViewController?

  static let turnTimeout: TimeInterval = 24 * 60 * 60

  init(history: History) {
    store = GameStore(mode: .online, history: history)
    super.init()
    store.onlineSubmit = { [weak self] saved in self?.submit(saved) }
    store.onlineResign = { [weak self] in
      guard let self, let openID = self.openID, let match = self.matches[openID] else { return }
      self.resign(match)
    }
    store.onlineRematch = { [weak self] in self?.rematch() }
  }

  var yourMoveCount: Int { summaries.filter { $0.state == .yourMove }.count }


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

  func refresh() async {
    guard GKLocalPlayer.local.isAuthenticated else { return }
    guard let loaded = try? await GKTurnBasedMatch.loadMatches() else { return }
    matches = Dictionary(loaded.map { ($0.matchID, $0) }, uniquingKeysWith: { first, _ in first })
    summaries = loaded.map(summary).sorted { order($0) < order($1) }
    if let openID, let match = matches[openID] { _ = await load(match) }
  }

  func open(_ id: String) async -> Bool {
    guard let match = matches[id] else { return false }
    let previous = openID
    openID = id
    if await load(match) { return true }
    guard openID == id else { return false }
    openID = previous
    problem = "That game couldn't be loaded. Check your connection and try again."
    return false
  }

  func remove(_ id: String) async {
    guard let match = matches[id] else { return }
    try? await match.remove()
    await refresh()
  }


  private func load(_ match: GKTurnBasedMatch) async -> Bool {
    guard let payload = try? await match.loadMatchData(), match.matchID == openID else { return false }
    let data: OnlineMatchData?
    if payload.isEmpty {
      data = nil
    } else {
      guard let decoded = try? JSONDecoder().decode(OnlineMatchData.self, from: payload) else { return false }
      data = decoded
    }
    let me = GKLocalPlayer.local.gamePlayerID
    let whiteID = data?.whiteID ?? match.participants.first?.player?.gamePlayerID ?? me
    let you: Piece.Color = whiteID == me ? .white : .black
    let mine = match.participants.first { $0.player?.gamePlayerID == me }
    let theirs = match.participants.first { $0.player?.gamePlayerID != me }
    var saved = SavedGame(
      you: you, level: .medium, timeControl: .none,
      startedAt: match.creationDate, lastMoveAt: theirs?.lastTurnDate ?? match.creationDate,
      whiteLeft: 0, blackLeft: 0)
    saved.moves = data?.moves ?? []
    saved.ending = Self.resignationOrTimeout(mine: mine, theirs: theirs, you: you)
    saved.recorded = true
    store.loadOnline(
      saved,
      opponent: theirs?.player?.displayName ?? "Your friend",
      waiting: match.currentParticipant?.player?.gamePlayerID != me || match.status != .open)
    if saved.ending != nil, match.status == .open, match.currentParticipant?.player?.gamePlayerID == me {
      await endMatch(match, saved: saved)
    }
    return true
  }

  private static func resignationOrTimeout(mine: GKTurnBasedParticipant?, theirs: GKTurnBasedParticipant?, you: Piece.Color) -> SavedGame.Ending? {
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

  private func resign(_ match: GKTurnBasedMatch) {
    nonisolated(unsafe) let match = match
    Task {
      let me = GKLocalPlayer.local.gamePlayerID
      if match.currentParticipant?.player?.gamePlayerID == me {
        guard let payload = try? await match.loadMatchData() else {
          problem = "Couldn't resign. Check your connection and try again."
          return
        }
        for participant in match.participants {
          participant.matchOutcome = participant.player?.gamePlayerID == me ? .quit : .won
        }
        try? await match.endMatchInTurn(withMatch: payload)
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
      _ = await open(next.matchID)
    }
  }

  private func encode(_ saved: SavedGame) -> Data {
    let whiteID = saved.you == .white ? GKLocalPlayer.local.gamePlayerID : (matches[openID ?? ""]?.participants.first { $0.player?.gamePlayerID != GKLocalPlayer.local.gamePlayerID }?.player?.gamePlayerID ?? "")
    return (try? JSONEncoder().encode(OnlineMatchData(moves: saved.moves, whiteID: whiteID))) ?? Data()
  }


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
      let opened = await open(match.matchID)
      await refresh()
      if opened { presentRequest += 1 }
    }
  }
}


extension OnlineGames: GKLocalPlayerListener {
  nonisolated func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
    nonisolated(unsafe) let match = match
    Task { @MainActor in
      if didBecomeActive || self.matchmaker != nil { self.show(match) } else { await self.refresh() }
    }
  }

  nonisolated func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
    Task { @MainActor in await self.refresh() }
  }

  nonisolated func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) {
    nonisolated(unsafe) let match = match
    Task { @MainActor in
      self.matches[match.matchID] = match
      self.resign(match)
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
