//
//  TickWidget.swift
//  TickWidget
//

import WidgetKit
import SwiftUI

private let appGroupId = "group.com.tick.tick"
private let todosKey = "todos"
private let mintColor = Color(red: 0x5E / 255.0, green: 0xCF / 255.0, blue: 0xB1 / 255.0)

// MARK: - Data

struct TodoEntry: TimelineEntry {
    let date: Date
    let todos: [String]
}

// MARK: - Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: Date(), todos: ["장보기", "운동하기", "독서"])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        completion(TodoEntry(date: Date(), todos: loadTodos()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> Void) {
        let entry = TodoEntry(date: Date(), todos: loadTodos())
        // Flutter 앱이 updateWidget() 호출할 때만 갱신 (.never)
        completion(Timeline(entries: [entry], policy: .never))
    }

    private func loadTodos() -> [String] {
        guard
            let defaults = UserDefaults(suiteName: appGroupId),
            let json = defaults.string(forKey: todosKey),
            let data = json.data(using: .utf8),
            let list = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return list
    }
}

// MARK: - Views

struct TickWidgetEntryView: View {
    var entry: TodoEntry
    @Environment(\.widgetFamily) var family

    private var maxItems: Int { family == .systemSmall ? 3 : 5 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Tick")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(mintColor)
                Spacer()
            }

            if entry.todos.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("할 일이 없어요")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(Array(entry.todos.prefix(maxItems).enumerated()), id: \.offset) { _, text in
                    HStack(spacing: 6) {
                        Circle()
                            .stroke(mintColor, lineWidth: 1.5)
                            .frame(width: 11, height: 11)
                        Text(text)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }

                if entry.todos.count > maxItems {
                    Text("+\(entry.todos.count - maxItems)개 더")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }

                Spacer()
            }
        }
        .padding(12)
    }
}

// MARK: - Widget

struct TickWidget: Widget {
    let kind: String = "TickWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                TickWidgetEntryView(entry: entry)
                    .containerBackground(.background, for: .widget)
            } else {
                TickWidgetEntryView(entry: entry)
                    .background(Color(UIColor.systemBackground))
            }
        }
        .configurationDisplayName("Tick")
        .description("오늘의 할 일을 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    TickWidget()
} timeline: {
    TodoEntry(date: .now, todos: ["장보기", "운동하기", "독서"])
    TodoEntry(date: .now, todos: [])
}

#Preview(as: .systemMedium) {
    TickWidget()
} timeline: {
    TodoEntry(date: .now, todos: ["장보기", "운동하기", "독서", "이메일 확인", "회의 준비"])
}
