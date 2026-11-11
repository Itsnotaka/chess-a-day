import ChessKit
import SwiftUI

struct LearnSheet: View {
  let start: (LessonRequest) -> Void
  @Environment(LearnProgress.self) private var progress
  @State private var course: Course?
  @State private var forward = true

  var body: some View {
    FittedSheet {
      ZStack(alignment: .top) {
        Group {
          if let course {
            CoursePage(course: course, start: start) {
              forward = false
              withAnimation(Theme.sheetResize) { self.course = nil }
            }
          } else {
            courses
          }
        }
        .id(course?.id ?? "courses")
        .motionTransition(.asymmetric(
          insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
          removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)))
      }
      .clipped()
    }
  }

  private var courses: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Learn").scaledFont(28, .heavy).foregroundStyle(Theme.ink).frame(maxWidth: .infinity)
        .padding(.bottom, 4)
      ForEach([Piece.Color.white, .black], id: \.self) { side in
        SectionLabel(title: side == .white ? "As White" : "As Black").padding(.top, 6)
        ForEach(Courses.all.filter { $0.side == side }) { course in
          Button {
            forward = true
            withAnimation(Theme.sheetResize) { self.course = course }
            Haptics.selection()
          } label: { CourseCard(course: course, learned: progress.learned(in: course)) }
            .buttonStyle(SoftPress())
        }
      }
      Text("Courses are lichess studies, shared by their authors.")
        .scaledFont(13, .medium).foregroundStyle(Theme.inkMuted)
        .frame(maxWidth: .infinity).padding(.top, 6)
    }
    .padding(.horizontal, 20)
    .padding(.top, 30)
    .padding(.bottom, 12)
  }
}

private struct CourseCard: View {
  let course: Course
  let learned: Int

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: course.symbol)
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(Theme.onInk)
        .frame(width: 48, height: 48)
        .background(Theme.ink, in: Circle())
      VStack(alignment: .leading, spacing: 3) {
        Text(course.title).scaledFont(18, .bold).foregroundStyle(Theme.ink)
        Text(course.summary).scaledFont(14, .medium).foregroundStyle(Theme.inkMuted)
          .multilineTextAlignment(.leading)
        ProgressTrack(fraction: Double(learned) / Double(max(course.lessons.count, 1)))
          .frame(width: 120)
          .padding(.top, 4)
      }
      Spacer(minLength: 0)
      Text("\(learned)/\(course.lessons.count)")
        .scaledFont(14, .bold).monospacedDigit().foregroundStyle(Theme.inkMuted)
    }
    .padding(14)
    .background(Theme.raised, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    .accessibilityElement(children: .combine)
  }
}

private struct CoursePage: View {
  let course: Course
  let start: (LessonRequest) -> Void
  let back: () -> Void
  @Environment(LearnProgress.self) private var progress

  var body: some View {
    VStack(spacing: 0) {
      SheetHeader(title: course.title, back: back)
      VStack(alignment: .leading, spacing: 0) {
        ForEach(Array(course.lessons.enumerated()), id: \.element.id) { index, lesson in
          row(index, lesson)
          if index < course.lessons.count - 1 { Hairline() }
        }
        Link(destination: course.source) {
          Text("Lessons by \(course.author) on lichess")
            .scaledFont(13, .semibold)
            .foregroundStyle(Theme.inkMuted)
            .underline()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
      .padding(.bottom, 20)
    }
  }

  private func row(_ index: Int, _ lesson: Lesson) -> some View {
    let result = progress.result(lesson)
    return HStack(spacing: 14) {
      Button { start(LessonRequest(course: course.id, lesson: index, practice: false)) } label: {
        HStack(spacing: 14) {
          ZStack {
            Circle().fill(result.learned ? Theme.ink : Theme.raised)
            if result.learned {
              Image(systemName: "checkmark").font(.system(size: 13, weight: .heavy)).foregroundStyle(Theme.onInk)
            } else {
              Text("\(index + 1)").scaledFont(15, .bold).foregroundStyle(Theme.ink)
            }
          }
          .frame(width: 34, height: 34)
          VStack(alignment: .leading, spacing: 2) {
            Text(lesson.title).scaledFont(17, .bold).foregroundStyle(Theme.ink).multilineTextAlignment(.leading)
            Text(lesson.style == .play ? "Play the moves" : "Watch and read")
              .scaledFont(13, .medium).foregroundStyle(Theme.inkMuted)
          }
          Spacer(minLength: 4)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(SoftPress())
      if result.learned, lesson.style == .play {
        Button { start(LessonRequest(course: course.id, lesson: index, practice: true)) } label: {
          HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { star in
              Image(systemName: star < result.stars ? "star.fill" : "star")
                .font(.system(size: 11, weight: .bold))
            }
          }
          .foregroundStyle(Theme.ink)
          .padding(.horizontal, 10)
          .frame(height: 30)
          .background(Theme.raised, in: Capsule())
        }
        .buttonStyle(SoftPress())
        .accessibilityLabel("Practise, \(result.stars) of 3 stars")
      }
    }
    .padding(.vertical, 12)
  }
}
