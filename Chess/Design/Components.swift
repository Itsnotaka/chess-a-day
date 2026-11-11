import SwiftUI

/// Shared press feedback: scale and dim, or only dim under Reduce Motion.
struct SoftPress: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1)
      .opacity(configuration.isPressed ? 0.85 : 1)
      .animation(reduceMotion ? .easeOut(duration: 0.1) : .spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
  }
}

/// A round icon button, 52 points by default; `tint` overrides the card fill.
struct CircleIconButton: View {
  let symbol: String
  let label: String
  var tint: Color?
  var size: CGFloat = 52
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: size * 0.36, weight: .bold))
        .foregroundStyle(tint == nil ? Theme.ink : Theme.onTint)
        .frame(width: size, height: size)
        .background(tint ?? Theme.card, in: Circle())
        .shadow(color: (tint ?? .black).opacity(tint == nil ? 0.05 : 0.3), radius: 10, y: 4)
    }
    .buttonStyle(SoftPress())
    .accessibilityLabel(label)
  }
}

/// A round button on a raised fill, for sheet and game headers.
struct RaisedCircleButton: View {
  let symbol: String
  let label: String
  var size: CGFloat = 52
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: size * 0.34, weight: .bold))
        .foregroundStyle(Theme.ink)
        .frame(width: size, height: size)
        .background(Theme.raised, in: Circle())
    }
    .buttonStyle(SoftPress())
    .accessibilityLabel(label)
  }
}

/// The primary action, filled with the current ink colour.
struct InkPill: View {
  let title: String
  var symbol: String?
  var fullWidth = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        if let symbol { Image(systemName: symbol).scaledFont(17, .bold) }
        Text(title).scaledFont(19, .bold)
      }
      .foregroundStyle(Theme.onInk)
      .padding(.horizontal, 28)
      .padding(.vertical, 8)
      .frame(minHeight: 56)
      .frame(maxWidth: fullWidth ? .infinity : nil)
      .background(Theme.ink, in: Capsule())
    }
    .buttonStyle(SoftPress())
  }
}

/// A quiet pill on the raised fill: the secondary action beside an `InkPill`.
struct SoftPill: View {
  let title: String
  var symbol: String?
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        if let symbol { Image(systemName: symbol).scaledFont(15, .bold) }
        Text(title).scaledFont(17, .semibold)
      }
      .foregroundStyle(Theme.ink)
      .padding(.horizontal, 22)
      .padding(.vertical, 8)
      .frame(minHeight: 50)
      .background(Theme.raised, in: Capsule())
    }
    .buttonStyle(SoftPress())
  }
}

/// One level as a rounded row; the chosen one turns ink with a check and its description.
struct LevelRow: View {
  let level: Level
  let selected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 14) {
          Image(systemName: level.symbol)
            .scaledFont(17, .bold)
            .foregroundStyle(selected ? Theme.onInk : Theme.inkMuted)
          Text(level.name)
            .scaledFont(20, .bold)
            .opacity(selected ? 1 : 0.55)
          Spacer()
          if selected {
            Image(systemName: "checkmark")
              .font(.system(size: 12, weight: .heavy))
              .foregroundStyle(Theme.ink)
              .frame(width: 26, height: 26)
              .background(Theme.onInk, in: Circle())
              .transition(.scale.combined(with: .opacity))
          }
        }
        if selected {
          Text(level.detail)
            .scaledFont(16, .medium)
            .opacity(0.85)
            .multilineTextAlignment(.leading)
            .transition(.opacity)
        }
      }
      .foregroundStyle(selected ? Theme.onInk : Theme.ink)
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(selected ? Theme.ink : Theme.raised, in: RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous))
    }
    .buttonStyle(SoftPress())
    .accessibilityAddTraits(selected ? .isSelected : [])
  }
}

/// A short choice, such as a reminder time or a clock.
struct Chip: View {
  let title: String
  let selected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .scaledFont(16, .bold)
        .foregroundStyle(selected ? Theme.onInk : Theme.ink)
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .frame(minHeight: 44)
        .background(selected ? Theme.ink : Theme.raised, in: Capsule())
    }
    .buttonStyle(SoftPress())
    .accessibilityAddTraits(selected ? .isSelected : [])
  }
}

/// A sheet page's header: a round Back button and a centred title.
struct SheetHeader: View {
  let title: String
  let back: () -> Void

  var body: some View {
    HStack {
      RaisedCircleButton(symbol: "chevron.left", label: "Back", action: back)
      Spacer()
      Text(title).scaledFont(26, .heavy).tracking(-0.4)
      Spacer()
      Color.clear.frame(width: 52, height: 52)
    }
    .padding(.horizontal, 20)
    .padding(.top, 20)
    .padding(.bottom, 8)
  }
}

/// A settings row: symbol, title, chevron, hairline below.
struct SettingsRowLabel: View {
  let symbol: String
  let title: String

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: symbol).scaledFont(20, .bold).frame(width: 28)
      Text(title).scaledFont(20, .bold)
      Spacer()
      Image(systemName: "chevron.right").scaledFont(15, .bold).foregroundStyle(Theme.inkFaint)
    }
    .foregroundStyle(Theme.ink)
    .padding(.vertical, 20)
    .contentShape(Rectangle())
    .overlay(alignment: .bottom) { Theme.hairline.frame(height: 1) }
  }
}

/// A switch row; the switch is the system's, in ink.
struct ToggleRow: View {
  let symbol: String
  let title: String
  @Binding var isOn: Bool

  var body: some View {
    Toggle(isOn: $isOn) {
      HStack(spacing: 14) {
        Image(systemName: symbol).scaledFont(19, .bold).frame(width: 26)
        Text(title).scaledFont(19, .bold)
      }
    }
    .tint(Theme.ink)
    .foregroundStyle(Theme.ink)
    .padding(.vertical, 12)
  }
}

/// A section label inside a sheet page.
struct SectionLabel: View {
  let title: String
  var body: some View {
    Text(title)
      .scaledFont(18, .bold)
      .foregroundStyle(Theme.ink)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// A one-point divider using the theme's hairline colour.
struct Hairline: View {
  var body: some View { Theme.hairline.frame(height: 1) }
}

/// A segmented picker with two label layers; the thumb masks the active layer.
/// Dragging updates the binding continuously; tapping commits on lift.
/// VoiceOver uses a system segmented picker instead of the custom gesture.
struct PillSegments<Option: Hashable, Label: View>: View {
  /// Must be nonempty and unique; selection should be one of these values.
  let options: [Option]
  @Binding var selection: Option
  var height: CGFloat = 40
  let name: (Option) -> String
  /// One segment's content; `active` is true in the copy the thumb reveals.
  @ViewBuilder let label: (Option, Bool) -> Label

  @GestureState private var pressing = false
  @State private var dragX: CGFloat?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var motion: Animation {
    reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 0.8)
  }

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width / CGFloat(max(options.count, 1))
      let index = CGFloat(options.firstIndex(of: selection) ?? 0)
      let thumbX = dragX ?? index * width
      let thumb = Capsule()
        .frame(width: width, height: proxy.size.height)
        .scaleEffect(pressing && dragX == nil && !reduceMotion ? 0.94 : 1)
        .offset(x: thumbX)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

      ZStack(alignment: .leading) {
        thumb.foregroundStyle(Theme.card).shadow(color: Theme.shadow, radius: 6, y: 2)
        row(width: width, height: proxy.size.height, active: false)
        row(width: width, height: proxy.size.height, active: true)
          .mask { thumb }
      }
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .updating($pressing) { _, state, _ in state = true }
          .onChanged { value in
            guard abs(value.translation.width) > 6 else { return }
            dragX = min(max(value.location.x - width / 2, 0), proxy.size.width - width)
            let nearest = segment(at: value.location.x, width: width)
            if options[nearest] != selection {
              selection = options[nearest]
              Haptics.selection()
            }
          }
          .onEnded { value in
            let chosen = options[segment(at: value.location.x, width: width)]
            withAnimation(motion) {
              dragX = nil
              if chosen != selection {
                selection = chosen
                Haptics.selection()
              }
            }
          })
    }
    .frame(height: height)
    .padding(4)
    .background(Theme.raised, in: Capsule())
    .animation(dragX == nil ? motion : nil, value: selection)
    .animation(motion, value: pressing)
    .accessibilityRepresentation {
      Picker("", selection: $selection) {
        ForEach(options, id: \.self) { Text(name($0)).tag($0) }
      }
      .pickerStyle(.segmented)
    }
  }

  private func row(width: CGFloat, height: CGFloat, active: Bool) -> some View {
    HStack(spacing: 0) {
      ForEach(options, id: \.self) { option in
        label(option, active).frame(width: width, height: height)
      }
    }
    .allowsHitTesting(false)
  }

  private func segment(at x: CGFloat, width: CGFloat) -> Int {
    min(max(Int(x / width), 0), options.count - 1)
  }
}

/// Shows a spinner during an async action, then a success label or the idle state on failure.
/// Calls `finished` after restoring idle on failure or briefly showing the success label.
struct MorphPill: View {
  let title: String
  let doneTitle: String
  var symbol: String?
  /// Return true for success; false restores the button for another attempt.
  let action: () async -> Bool
  var finished: (Bool) -> Void = { _ in }

  private enum Phase { case idle, working, done }
  @State private var phase = Phase.idle
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    Button {
      guard phase == .idle else { return }
      Haptics.tap()
      withAnimation(motion) { phase = .working }
      Task {
        let started = ContinuousClock.now
        let ok = await action()
        // Keep fast actions from flashing the spinner.
        let shown = ContinuousClock.now - started
        if shown < .milliseconds(450) { try? await Task.sleep(for: .milliseconds(450) - shown) }
        guard ok else {
          withAnimation(motion) { phase = .idle }
          finished(false)
          return
        }
        withAnimation(motion) { phase = .done }
        Haptics.finish(won: true)
        try? await Task.sleep(for: .milliseconds(700))
        finished(true)
      }
    } label: {
      ZStack {
        switch phase {
        case .idle:
          HStack(spacing: 10) {
            if let symbol { Image(systemName: symbol).scaledFont(17, .bold) }
            Text(title).scaledFont(19, .bold)
          }
          .transition(.opacity.combined(with: .scale(scale: 0.9)))
        case .working:
          ProgressView().tint(Theme.onInk).transition(.opacity)
        case .done:
          HStack(spacing: 8) {
            Image(systemName: "checkmark").scaledFont(17, .heavy)
              .transition(.scale.combined(with: .opacity))
            Text(doneTitle).scaledFont(19, .bold)
          }
          .transition(.opacity.combined(with: .scale(scale: 0.9)))
        }
      }
      .foregroundStyle(Theme.onInk)
      .padding(.horizontal, phase == .working ? 0 : 28)
      .frame(width: phase == .working ? 56 : nil, height: 56)
      .frame(maxWidth: phase == .working ? 56 : .infinity)
      .background(Theme.ink, in: Capsule())
    }
    .buttonStyle(SoftPress())
    .disabled(phase != .idle)
    .accessibilityLabel(phase == .done ? doneTitle : title)
  }

  private var motion: Animation {
    reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.38, dampingFraction: 0.78)
  }
}

/// Requires a second tap to confirm a destructive action; disarms after three seconds.
struct ConfirmCircle: View {
  let symbol: String
  let title: String
  var size: CGFloat = 56
  let action: () -> Void

  @State private var armed = false
  @State private var disarm: Task<Void, Never>?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    Button {
      if armed {
        disarm?.cancel()
        withAnimation(motion) { armed = false }
        Haptics.finish(won: false)
        action()
      } else {
        Haptics.miss()
        withAnimation(motion) { armed = true }
        disarm?.cancel()
        disarm = Task {
          try? await Task.sleep(for: .seconds(3))
          guard !Task.isCancelled else { return }
          withAnimation(motion) { armed = false }
        }
      }
    } label: {
      HStack(spacing: 8) {
        Image(systemName: symbol).font(.system(size: size * 0.32, weight: .bold))
        if armed {
          Text(title)
            .scaledFont(17, .bold)
            .lineLimit(1)
            .fixedSize()
            .transition(.opacity.combined(with: .move(edge: .leading)))
        }
      }
      .foregroundStyle(armed ? Color.white : Theme.ink)
      .padding(.horizontal, armed ? 22 : 0)
      .frame(minWidth: size, minHeight: size)
      .background(armed ? Theme.red : Theme.raised, in: Capsule())
    }
    .buttonStyle(SoftPress())
    .accessibilityLabel(armed ? "\(title), tap again to confirm" : title)
    .onDisappear { disarm?.cancel() }
  }

  private var motion: Animation {
    reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.34, dampingFraction: 0.78)
  }
}
