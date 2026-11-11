import ChessKit
import SwiftUI

struct LessonRequest: Identifiable, Hashable {
  let course: String
  let lesson: Int
  let practice: Bool
  var id: String { "\(course)/\(lesson)/\(practice)" }
}

struct LessonScreen: View {
  @Environment(History.self) private var history
  @Environment(LearnProgress.self) private var progress
  @State private var request: LessonRequest
  @State private var player: LessonPlayer?

  init(request: LessonRequest) {
    _request = State(initialValue: request)
  }

  var body: some View {
    Group {
      if let player {
        LessonView(player: player, open: open)
          .id(player.lesson.id + (player.practice ? "/practice" : ""))
          .transition(.opacity)
      }
    }
    .background(Theme.card.ignoresSafeArea())
    .onAppear { if player == nil { open(request) } }
  }

  private func open(_ next: LessonRequest) {
    guard let course = Courses.course(next.course), course.lessons.indices.contains(next.lesson) else { return }
    let player = LessonPlayer(course: course, lesson: course.lessons[next.lesson], practice: next.practice,
                              history: history, progress: progress)
    withAnimation(Theme.spring) {
      request = next
      self.player = player
    }
    player.start()
  }
}

struct LessonView: View {
  let player: LessonPlayer
  let open: (LessonRequest) -> Void
  @Environment(\.dismiss) private var dismiss
  @AppStorage(Pref.appearance) private var appearance = Appearance.system
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack(spacing: 14) {
      header
      ProgressTrack(fraction: player.fraction)
      Spacer(minLength: 6)
      BoardView().environment(player.store)
      coach
      Spacer(minLength: 6)
      footer
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 4)
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    .background(Theme.card.ignoresSafeArea())
    .preferredColorScheme(appearance.scheme)
  }

  private var header: some View {
    HStack {
      RaisedCircleButton(symbol: "chevron.down", label: "Close") { dismiss() }
      Spacer()
      VStack(spacing: 2) {
        Text(player.lesson.title).scaledFont(17, .bold).foregroundStyle(Theme.ink).lineLimit(1)
        Text(player.practice ? "\(player.course.title) · Practice" : player.course.title)
          .scaledFont(14, .semibold).foregroundStyle(Theme.inkMuted).lineLimit(1)
      }
      Spacer()
      Image(systemName: player.course.symbol)
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(Theme.ink)
        .frame(width: 52, height: 52)
        .background(Theme.raised, in: Circle())
        .accessibilityHidden(true)
    }
    .padding(.top, 4)
  }

  private var coach: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: player.mood == .good ? "checkmark" : player.mood == .wrong ? "arrow.uturn.backward" : "graduationcap.fill")
        .font(.system(size: 16, weight: .heavy))
        .foregroundStyle(player.mood == .calm ? Theme.ink : Theme.onTint)
        .frame(width: 40, height: 40)
        .background(player.mood == .good ? Theme.teal : player.mood == .wrong ? Theme.red : Theme.card, in: Circle())
        .contentTransition(.symbolEffect(.replace))
        .accessibilityHidden(true)
      ScrollView {
        VStack(alignment: .leading, spacing: 4) {
          if let detail = player.detail {
            Text(detail).scaledFont(14, .semibold).foregroundStyle(Theme.inkMuted)
          }
          Text(player.finished ? finishText : player.message)
            .scaledFont(17, .semibold)
            .foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .id(player.message)
            .motionTransition(.opacity.combined(with: .move(edge: .bottom)))
        }
      }
      .scrollBounceBehavior(.basedOnSize)
      .frame(maxHeight: 170)
      .fixedSize(horizontal: false, vertical: true)
    }
    .padding(14)
    .background(Theme.raised, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    .modifier(Shake(trigger: reduceMotion ? 0 : player.shake))
    .animation(Theme.spring, value: player.message)
    .animation(Theme.spring, value: player.mood)
    .accessibilityElement(children: .combine)
  }

  private var finishText: String {
    player.practice ? "Practice done: \(player.stars) of 3 stars." : "Lesson learned. Practise it from memory to earn stars."
  }

  @ViewBuilder
  private var footer: some View {
    if player.finished {
      finishActions
    } else {
      HStack(spacing: 12) {
        if player.canHint {
          SoftPill(title: "Hint", symbol: "lightbulb.fill") { player.hint() }
            .motionTransition(.opacity.combined(with: .scale(scale: 0.9)))
        }
        Spacer(minLength: 0)
        if player.waiting {
          InkPill(title: "Continue", symbol: "arrow.right") { player.next() }
            .motionTransition(.opacity.combined(with: .scale(scale: 0.9)))
        }
      }
      .frame(minHeight: 56)
      .animation(Theme.spring, value: player.waiting)
      .animation(Theme.spring, value: player.canHint)
    }
  }

  private var finishActions: some View {
    let index = player.course.lessons.firstIndex { $0.id == player.lesson.id } ?? 0
    let hasNext = index + 1 < player.course.lessons.count
    return VStack(spacing: 12) {
      if player.practice {
        HStack(spacing: 6) {
          ForEach(0..<3, id: \.self) { star in
            Image(systemName: star < player.stars ? "star.fill" : "star")
              .font(.system(size: 26, weight: .bold))
              .foregroundStyle(star < player.stars ? Theme.ink : Theme.inkFaint)
          }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(player.stars) of 3 stars")
      }
      HStack(spacing: 10) {
        if player.lesson.style == .play {
          SoftPill(title: player.practice ? "Again" : "Practise", symbol: "arrow.clockwise") {
            open(LessonRequest(course: player.course.id, lesson: index, practice: true))
          }
        }
        if hasNext {
          InkPill(title: "Next lesson", symbol: "arrow.right") {
            open(LessonRequest(course: player.course.id, lesson: index + 1, practice: false))
          }
        } else {
          InkPill(title: "Done", symbol: "checkmark") { dismiss() }
        }
      }
    }
    .motionTransition(.move(edge: .bottom).combined(with: .opacity))
  }
}

struct ProgressTrack: View {
  let fraction: Double

  var body: some View {
    GeometryReader { proxy in
      Capsule().fill(Theme.raised)
        .overlay(alignment: .leading) {
          Capsule().fill(Theme.ink).frame(width: max(8, proxy.size.width * fraction))
        }
    }
    .frame(height: 6)
    .animation(Theme.spring, value: fraction)
    .accessibilityElement()
    .accessibilityLabel("Lesson progress")
    .accessibilityValue("\(Int(fraction * 100)) percent")
  }
}

struct Shake: ViewModifier {
  let trigger: Int

  func body(content: Content) -> some View {
    content.keyframeAnimator(initialValue: 0.0, trigger: trigger) { view, x in
      view.offset(x: x)
    } keyframes: { _ in
      KeyframeTrack {
        LinearKeyframe(-9, duration: 0.06)
        LinearKeyframe(8, duration: 0.07)
        LinearKeyframe(-5, duration: 0.07)
        SpringKeyframe(0, duration: 0.2, spring: .snappy)
      }
    }
  }
}
