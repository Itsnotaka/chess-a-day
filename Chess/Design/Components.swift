import SwiftUI

/// Presses sink a little and spring back: the one press feel every control shares.
/// Under Reduce Motion a press only dims.
struct SoftPress: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1)
      .opacity(configuration.isPressed ? 0.85 : 1)
      .animation(reduceMotion ? .easeOut(duration: 0.1) : .spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
  }
}

/// A 52-point round icon button on a card; with a `tint` it is filled with that colour.
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

/// The black (white in dark mode) pill: the screen's one main action.
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

struct Hairline: View {
  var body: some View { Theme.hairline.frame(height: 1) }
}
