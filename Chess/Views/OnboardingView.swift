import ChessKit
import SwiftUI

/// First launch: Welcome, Level, Reminder, on one floating card over the grey ground.
struct OnboardingView: View {
  @AppStorage(Pref.onboarded) private var onboarded = false
  @AppStorage(Pref.level) private var level = Level.medium
  @AppStorage(Pref.reminder) private var reminder = false
  @AppStorage(Pref.reminderMinute) private var reminderMinute = ReminderTime.defaultMinute
  @State private var step = 0
  @State private var forward = true
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack(spacing: 0) {
      // The ground above the card shows what the app is: a board, set up and waiting.
      MiniBoard(pieces: Self.startPieces, flipped: false)
        .frame(maxWidth: 230)
        .rotationEffect(.degrees(-6))
        .softShadow(radius: 24, y: 12)
        .padding(.horizontal, 60)
        .padding(.vertical, 24)
        // The board takes only the height the card leaves; it shrinks or fades, never the card.
        .frame(minHeight: 0, maxHeight: .infinity)
        .opacity(step == 0 ? 1 : 0.5)
        .accessibilityHidden(true)

      VStack(spacing: 18) {
        AppMark()
        Group {
          switch step {
          case 0: welcome
          case 1: levels
          default: nudge
          }
        }
        .id(step)
        .transition(reduceMotion ? .opacity : .asymmetric(
          insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
          removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)))
        buttons.padding(.top, 6)
      }
      .padding(.horizontal, 22)
      .padding(.top, 26)
      .padding(.bottom, 22)
      .frame(maxWidth: .infinity)
      .background(Theme.card, in: RoundedRectangle(cornerRadius: 44, style: .continuous))
      .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
      .softShadow(radius: 30, y: 12)
      .padding(.horizontal, 12)
      .padding(.bottom, 8)
      .layoutPriority(1)
    }
    .background(Theme.ground.ignoresSafeArea())
    .animation(Theme.spring, value: step)
  }

  private static let startPieces = Board().position.pieces.map { BoardPiece(id: $0.square.notation, piece: $0) }

  private var welcome: some View {
    VStack(spacing: 18) {
      VStack(spacing: 6) {
        Text("Chess").scaledFont(36, .heavy).tracking(-1.1)
        Text("One calm game a day.")
          .scaledFont(18, .medium)
          .foregroundStyle(Theme.inkMuted)
      }
      .foregroundStyle(Theme.ink)
      VStack(spacing: 10) {
        Feature(symbol: "cpu", title: "Play the computer", detail: "Five levels, from Easy to Master.")
        Feature(symbol: "person.2.fill", title: "Play a friend", detail: "Two players, one phone.")
        Feature(symbol: "laurel.leading", title: "Keep a streak", detail: "One game a day keeps it going.")
      }
    }
  }

  /// The list as it is, or scrolling when large text makes it taller than the screen.
  private var levels: some View {
    ViewThatFits(in: .vertical) {
      levelList
      ScrollView { levelList }
    }
  }

  private var levelList: some View {
    VStack(spacing: 10) {
      Text("Select your level")
        .scaledFont(24, .heavy)
        .foregroundStyle(Theme.ink)
        .padding(.bottom, 6)
      ForEach(Level.allCases) { option in
        LevelRow(level: option, selected: option == level) {
          withAnimation(Theme.spring) { level = option }
          Haptics.selection()
        }
      }
    }
  }

  private var nudge: some View {
    VStack(spacing: 14) {
      Image(systemName: "bell.badge.fill")
        .scaledFont(40, .bold)
        .foregroundStyle(level.tint)
        .symbolEffect(.bounce, value: reduceMotion ? 0 : step)
      Text("A daily nudge?").scaledFont(28, .heavy).foregroundStyle(Theme.ink)
      Text("One reminder a day, at a time that suits you.")
        .scaledFont(17, .medium)
        .foregroundStyle(Theme.inkMuted)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 300)
      ReminderTime(minute: $reminderMinute).padding(.top, 6)
    }
  }

  private var buttons: some View {
    HStack(spacing: 12) {
      if step > 0 {
        RaisedCircleButton(symbol: "arrow.left", label: "Back", size: 56) {
          forward = false
          step -= 1
        }
        .transition(.scale.combined(with: .opacity))
      }
      if step < 2 {
        InkPill(title: "Continue", fullWidth: true) {
          forward = true
          step += 1
          Haptics.tap()
        }
      } else {
        VStack(spacing: 6) {
          MorphPill(title: "Remind me", doneTitle: "Reminder set", action: {
            await Reminders.enable(minute: reminderMinute)
          }, finished: { allowed in
            reminder = allowed
            onboarded = true
          })
          Button("Not now") { finish(remind: false) }
            .scaledFont(16, .semibold)
            .foregroundStyle(Theme.inkMuted)
            .frame(height: 36)
        }
      }
    }
  }

  private func finish(remind: Bool) {
    Haptics.finish(won: true)
    reminder = remind
    onboarded = true
  }
}

/// One thing the app does: a round symbol, a title and a line.
private struct Feature: View {
  let symbol: String
  let title: String
  let detail: String

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: symbol)
        .font(.system(size: 17, weight: .bold))
        .foregroundStyle(Theme.ink)
        .frame(width: 44, height: 44)
        .background(Theme.raised, in: Circle())
      VStack(alignment: .leading, spacing: 2) {
        Text(title).scaledFont(17, .bold).foregroundStyle(Theme.ink)
        Text(detail).scaledFont(15, .medium).foregroundStyle(Theme.inkMuted)
      }
      Spacer(minLength: 0)
    }
    .padding(12)
    .background(Theme.raised.opacity(0.5), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    .accessibilityElement(children: .combine)
  }
}

/// The app's mark: the logo tile, with the rounded corners iOS gives the icon.
struct AppMark: View {
  var size: CGFloat = 68

  var body: some View {
    Image("Logo")
      .resizable()
      .interpolation(.high)
      .frame(width: size, height: size)
      .clipShape(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous))
      .softShadow(radius: 12, y: 4)
      .accessibilityHidden(true)
  }
}

/// The reminder's time: a large readout over a slider in quarter hours, 5 AM to 11 PM. Each step
/// ticks; `committed` runs when the finger lifts, so the reminder is rescheduled once.
struct ReminderTime: View {
  @Binding var minute: Int
  var committed: (Int) -> Void = { _ in }

  static let defaultMinute = 9 * 60
  private static let range = 5.0 * 60 ... 23.0 * 60

  var body: some View {
    VStack(spacing: 10) {
      Text(Self.label(minute))
        .scaledFont(34, .heavy)
        .monospacedDigit()
        .contentTransition(.numericText())
        .foregroundStyle(Theme.ink)
        .animation(.snappy(duration: 0.2), value: minute)
      Slider(
        value: Binding(get: { Double(minute) }, set: { minute = Int($0) }),
        in: Self.range, step: 15,
        label: { Text("Reminder time") },
        minimumValueLabel: { Text("5 AM").scaledFont(13, .semibold).foregroundStyle(Theme.inkMuted) },
        maximumValueLabel: { Text("11 PM").scaledFont(13, .semibold).foregroundStyle(Theme.inkMuted) },
        onEditingChanged: { editing in if !editing { committed(minute) } })
        .tint(Theme.ink)
        .accessibilityValue(Self.label(minute))
    }
    .onChange(of: minute) { Haptics.selection() }
  }

  static func label(_ minute: Int) -> String {
    let date = Calendar.current.date(from: DateComponents(hour: minute / 60, minute: minute % 60)) ?? .now
    return date.formatted(date: .omitted, time: .shortened)
  }
}
