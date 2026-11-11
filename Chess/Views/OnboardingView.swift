import SwiftUI

/// First launch: Welcome, Level, Reminder, on one floating card over the grey ground.
struct OnboardingView: View {
  @AppStorage(Pref.onboarded) private var onboarded = false
  @AppStorage(Pref.level) private var level = Level.medium
  @AppStorage(Pref.reminder) private var reminder = false
  @AppStorage(Pref.reminderHour) private var reminderHour = 9
  @State private var step = 0
  @State private var forward = true

  var body: some View {
    ZStack(alignment: .bottom) {
      Theme.ground.ignoresSafeArea()
      VStack(spacing: 16) {
        AppMark()
        ZStack {
          switch step {
          case 0: welcome
          case 1: levels
          default: nudge
          }
        }
        .id(step)
        .transition(.asymmetric(
          insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
          removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)))
        .frame(maxHeight: .infinity)
        buttons
      }
      .padding(.horizontal, 22)
      .padding(.top, 28)
      .padding(.bottom, 22)
      .frame(maxWidth: .infinity)
      .frame(height: step == 1 ? 640 : 560)
      .background(Theme.card, in: RoundedRectangle(cornerRadius: 44, style: .continuous))
      .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
      .softShadow(radius: 30, y: 12)
      .padding(.horizontal, 12)
      .padding(.bottom, 8)
    }
    .animation(Theme.spring, value: step)
  }

  private var welcome: some View {
    VStack(spacing: 12) {
      Text("Chess").font(.system(size: 40, weight: .heavy)).tracking(-1.2)
      Text("One calm game a day. Play the computer, solve a puzzle, keep your streak.")
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(Theme.inkMuted)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 300)
    }
    .foregroundStyle(Theme.ink)
  }

  private var levels: some View {
    VStack(spacing: 10) {
      Text("Select your level")
        .font(.system(size: 24, weight: .heavy))
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
        .font(.system(size: 40, weight: .bold))
        .foregroundStyle(level.tint)
        .symbolEffect(.bounce, value: step)
      Text("A daily nudge?").font(.system(size: 28, weight: .heavy)).foregroundStyle(Theme.ink)
      Text("One reminder a day, when your game and puzzle are waiting.")
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(Theme.inkMuted)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 300)
      ReminderHours(hour: $reminderHour).padding(.top, 6)
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
          InkPill(title: "Remind me", fullWidth: true) { finish(remind: true) }
          Button("Not now") { finish(remind: false) }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Theme.inkMuted)
            .frame(height: 36)
        }
      }
    }
  }

  private func finish(remind: Bool) {
    reminder = remind
    if remind { Reminders.schedule(hour: reminderHour) }
    onboarded = true
    Haptics.finish(won: true)
  }
}

/// The app's mark: a knight on a white tile, as Sudoku a Day shows its icon.
struct AppMark: View {
  var size: CGFloat = 64

  var body: some View {
    Image("wN")
      .resizable()
      .scaledToFit()
      .padding(size * 0.14)
      .frame(width: size, height: size)
      .background(Color.white, in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
      .softShadow(radius: 12, y: 4)
  }
}

/// The reminder hours as chips.
struct ReminderHours: View {
  @Binding var hour: Int
  static let hours = [8, 9, 12, 18, 21]

  var body: some View {
    FlowLayout(spacing: 8) {
      ForEach(Self.hours, id: \.self) { option in
        Chip(title: "\(option):00", selected: hour == option) {
          withAnimation(Theme.spring) { hour = option }
          Haptics.selection()
        }
      }
    }
  }
}
