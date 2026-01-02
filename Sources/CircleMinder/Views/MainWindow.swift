import SwiftUI

struct MainWindow: View {
    @EnvironmentObject var store: ReminderStore
    @State private var showingAddSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Text("提醒任务")
                    .font(.largeTitle)
                    .padding(.leading, 20)
                    .padding(.top, 20) // Push down slightly to clear traffic lights visually if needed
                
                Spacer()
                
                if !store.items.isEmpty {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.primary)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(.regularMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                            .overlay(
                                Circle()
                                    .stroke(.primary.opacity(0.1), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                    .padding(.trailing, 16)
                }
            }
            .padding(.bottom, 10)
            
            if store.items.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(store.items) { item in
                        ReminderRow(item: item)
                    }
                    .onDelete { indexSet in
                        store.deleteItem(at: indexSet)
                    }
                }
                .scrollContentBackground(.hidden) // Key for glass effect
                .background(Color.clear)
            }
        }
        .frame(minWidth: 400, minHeight: 400)
        .sheet(isPresented: $showingAddSheet) {
            AddReminderView()
                .presentationDetents([.medium])
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "timer")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            Text("No Reminders Yet")
                .font(.title2)
                .foregroundStyle(.secondary)
            Button("添加第一个提醒") {
                showingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ReminderRow: View {
    let item: ReminderItem
    @EnvironmentObject var store: ReminderStore
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.content)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Label(formatDuration(item.interval), systemImage: "arrow.triangle.2.circlepath")
                        .help("提醒间隔")
                    Text("|")
                        .foregroundStyle(.secondary.opacity(0.5))
                    // Keep duration and icon on same line, use fixed label style if needed
                    Label("持续: \(formatDuration(item.activeDuration))", systemImage: "hourglass")
                        .help("持续时间")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { item.isEnabled },
                set: { _ in store.toggleItem(id: item.id) }
            ))
            .toggleStyle(.switch)
            
            Button(action: { store.deleteItem(id: item.id) }) {
                Image(systemName: "trash")
                    .foregroundStyle(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .listRowSeparator(.hidden) // Cleaner look
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .padding(.vertical, 4)
        )
    }
    
    func formatDuration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? ""
    }
}

struct AddReminderView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: ReminderStore
    
    @State private var content: String = ""
    @State private var interval: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    
    // We can use Pickers for H/M/S manually to match "x小时x分钟x秒" requirement perfectly
    // rather than a single duration picker which is sometimes limited.
    
    var isValid: Bool {
        return !content.isEmpty && interval >= 5 && store.isValid(interval: interval, duration: duration)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Field: Content
            VStack(alignment: .leading, spacing: 12) {
                Text("提醒内容")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                TextField("", text: $content)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
                    .padding(.horizontal)
            }
            .padding(.top, 20)
            
            // Field: Interval
            VStack(alignment: .leading, spacing: 12) {
                Text("提醒间隔 (每隔多久提醒一次)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    TimePickerView(selection: $interval)
                        .padding(.vertical, 8)
                    
                    if interval > 0 && interval < 5 {
                        Text("间隔时间必须至少 5 秒")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                )
                .padding(.horizontal)
            }
            
            // Field: Duration
            VStack(alignment: .leading, spacing: 12) {
                Text("持续时长 (倒计时结束后自动关闭)")
                    .font(.headline)
                    .foregroundStyle(.secondary) // Slightly softer header
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    TimePickerView(selection: $duration)
                        .padding(.vertical, 8)
                    
                    if duration > 0 && !store.isValid(interval: interval, duration: duration) {
                        Text("持续时长必须大于提醒间隔")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                )
                .padding(.horizontal)
            }
            
            
            HStack(spacing: 20) {
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .controlSize(.large)
                
                Button("添加") {
                    let newItem = ReminderItem(
                        content: content,
                        interval: interval,
                        activeDuration: duration,
                        isEnabled: false
                    )
                    store.addItem(newItem)
                    dismiss()
                }
                .disabled(!isValid)
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 30) // Slightly more breathing room
            .padding(.horizontal)
        }
        .frame(width: 400, height: 450) // Force fixed size to match main window default
        .background(.ultraThinMaterial)
    }
}

struct TimePickerView: View {
    @Binding var selection: TimeInterval
    
    // Decompose to H M S
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    
    // Formatter for display
    private var durationString: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        return formatter.string(from: selection) ?? ""
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // Removed Live Feedback Text as requested
            
            HStack(spacing: 10) {
                Picker("时", selection: $hours) {
                    ForEach(0..<24) { Text("\($0)时").tag($0) }
                }
                .labelsHidden()
                .frame(width: 75)
                .clipped()
                
                Picker("分", selection: $minutes) {
                    ForEach(0..<60) { Text("\($0)分").tag($0) }
                }
                .labelsHidden()
                .frame(width: 75)
                .clipped()
                
                Picker("秒", selection: $seconds) {
                    ForEach(0..<60) { Text("\($0)秒").tag($0) }
                }
                .labelsHidden()
                .frame(width: 75)
                .clipped()
            }
        }
        .onAppear {
            let total = Int(selection)
            hours = total / 3600
            minutes = (total % 3600) / 60
            seconds = total % 60
        }
        .onChange(of: hours) { updateSelection() }
        .onChange(of: minutes) { updateSelection() }
        .onChange(of: seconds) { updateSelection() }
    }
    
    func updateSelection() {
        selection = TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }
}
