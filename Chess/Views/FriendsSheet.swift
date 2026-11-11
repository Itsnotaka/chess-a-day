import SwiftUI

/// Online: invite a friend through Game Center (Messages, friends, recent players), or pick up
/// an online game where it stands. Free play on one phone is offered here too, as the fallback.
struct FriendsSheet: View {
  @Environment(OnlineGames.self) private var online
  @Environment(GameStore.self) private var computer
  let passAndPlay: () -> Void
  let openOnline: (String) -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        Text("Play online")
          .scaledFont(28, .heavy)
          .foregroundStyle(Theme.ink)
          .frame(maxWidth: .infinity)
          .padding(.bottom, 6)

        choice(symbol: "paperplane.fill", title: "Invite a friend",
               detail: "Send an invite in Messages or to a Game Center friend. One day per move.",
               enabled: online.status == .signedIn) {
          online.invite()
        }
        choice(symbol: "iphone", title: "Free play", detail: "Together on this phone instead.", enabled: true, perform: passAndPlay)

        signInNote

        if !online.summaries.isEmpty {
          SectionLabel(title: "Your games").padding(.top, 12)
          VStack(spacing: 0) {
            ForEach(online.summaries) { game in
              row(game)
              if game.id != online.summaries.last?.id { Hairline().padding(.leading, 62) }
            }
          }
          .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 30)
      .padding(.bottom, 24)
    }
    .task { await online.refresh() }
    .refreshable { await online.refresh() }
  }

  @ViewBuilder
  private var signInNote: some View {
    switch online.status {
    case .signedOut:
      note("Sign in to Game Center in the Settings app to play friends online.", action: "Try again") { online.authenticate() }
    case let .unavailable(message):
      note(message, action: "Try again") { online.authenticate() }
    case .unknown, .signedIn:
      EmptyView()
    }
  }

  private func choice(symbol: String, title: String, detail: String, enabled: Bool, perform: @escaping () -> Void) -> some View {
    Button(action: perform) {
      HStack(spacing: 14) {
        Image(systemName: symbol)
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(Theme.onInk)
          .frame(width: 48, height: 48)
          .background(Theme.ink, in: Circle())
        VStack(alignment: .leading, spacing: 3) {
          Text(title).scaledFont(18, .bold).foregroundStyle(Theme.ink)
          Text(detail).scaledFont(15, .medium).foregroundStyle(Theme.inkMuted).multilineTextAlignment(.leading)
        }
        Spacer(minLength: 0)
        Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.inkFaint)
      }
      .padding(14)
      .background(Theme.raised, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    .buttonStyle(SoftPress())
    .disabled(!enabled)
    .opacity(enabled ? 1 : 0.45)
    .accessibilityElement(children: .combine)
  }

  private func note(_ text: String, action: String, perform: @escaping () -> Void) -> some View {
    HStack(spacing: 12) {
      Text(text).scaledFont(15, .medium).foregroundStyle(Theme.ink)
      Spacer(minLength: 8)
      Button(action, action: perform)
        .scaledFont(15, .bold)
        .foregroundStyle(Theme.onInk)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.ink, in: Capsule())
    }
    .padding(14)
    .background(Theme.raised, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
  }

  private func row(_ game: OnlineSummary) -> some View {
    Button { openOnline(game.id) } label: {
      HStack(spacing: 12) {
        Text(String(game.opponent.prefix(1)).uppercased())
          .scaledFont(17, .heavy)
          .foregroundStyle(Theme.ink)
          .frame(width: 38, height: 38)
          .background(Theme.card, in: Circle())
        VStack(alignment: .leading, spacing: 2) {
          Text(game.opponent).scaledFont(17, .bold).foregroundStyle(Theme.ink)
          Text(game.updated.formatted(.relative(presentation: .named)))
            .scaledFont(13, .medium).foregroundStyle(Theme.inkMuted)
        }
        Spacer(minLength: 8)
        Text(game.label)
          .scaledFont(14, .bold)
          .foregroundStyle(game.state == .yourMove ? Theme.onInk : Theme.ink)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(game.state == .yourMove ? Theme.ink : Theme.card, in: Capsule())
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .contentShape(Rectangle())
    }
    .buttonStyle(SoftPress())
    .contextMenu {
      if game.finished {
        Button("Remove", systemImage: "trash", role: .destructive) { Task { await online.remove(game.id) } }
      }
    }
    .accessibilityElement(children: .combine)
  }
}
