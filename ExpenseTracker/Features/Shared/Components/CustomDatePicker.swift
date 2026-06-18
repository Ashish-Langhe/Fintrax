//
//  CustomDatePicker.swift
//  Fintrax
//
//  Fintrax documentation: Defines shared SwiftUI components, modifiers, design tokens, and validation utilities.
//

import SwiftUI

/// Custom date picker with preset options
struct CustomDatePicker: View {
    @Binding var date: Date
    @State private var selectedPreset: DatePreset?
    let title: String
    
    // Date range bounds
    private let minimumDate: Date
    private let maximumDate: Date
    
    private var calendar: Calendar { Calendar.current }
    
    init(date: Binding<Date>, title: String = "Select Date") {
        self._date = date
        self.title = title
        
        // Set reasonable bounds (up to 10 years in the past and future)
        let now = Date()
        let cal = Calendar.current
        self.minimumDate = cal.date(byAdding: .year, value: -10, to: now) ?? now
        self.maximumDate = cal.date(byAdding: .year, value: 10, to: now) ?? now
        
        // Check if current date matches any preset
        self._selectedPreset = State(initialValue: DatePreset.allCases.first {
            $0.isToday(date: date.wrappedValue, calendar: cal)  // FIX 1: use .wrappedValue not Binding directly
        })
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with current date display
                headerView
                
                Divider()
                
                // Preset options
                presetOptionsSection
                
                Divider()
                
                // Calendar date picker
                calendarSection
                
                Spacer()
                
                // Action buttons
                actionButtons
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(LocalizedStringKey(title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // In a real implementation, you'd cancel and restore original date
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedPreset = nil
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            updatePresetSelection()
        }
        .onChange(of: date) { _, _ in
            updatePresetSelection()
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: 4) {
            Text(formattedDate())
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(relativeDateString)  // FIX 2: now a computed var String, not a closure
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var presetOptionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DatePreset.allCases, id: \.self) { preset in
                    PresetButton(
                        preset: preset,
                        isSelected: selectedPreset == preset,
                        date: $date
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("Calendar"))
                .font(.headline)
                .padding(.horizontal)
            
            DatePicker("", selection: $date, in: minimumDate...maximumDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .labelsHidden()
        }
        .frame(height: 300)
        .background(Color(.systemBackground))
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Today") {
                date = Date()
                selectedPreset = .today
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Clear") {
                date = Date()
                selectedPreset = nil
            }
            .foregroundColor(.red)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helper Methods
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // FIX 2: was "private var relativeDateString: String -> String" (closure type by mistake)
    private var relativeDateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func updatePresetSelection() {
        selectedPreset = DatePreset.allCases.first { preset in
            preset.matches(date: date, calendar: calendar)
        }
    }
}

// MARK: - Supporting Types

/// Date preset options
enum DatePreset: String, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case thisWeek = "This Week"
    case lastWeek = "Last Week"
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    case thisYear = "This Year"
    case lastYear = "Last Year"
    
    func isToday(date: Date, calendar: Calendar) -> Bool {
        return calendar.isDate(date, inSameDayAs: Date())
    }
    
    func matches(date: Date, calendar: Calendar) -> Bool {
        let now = Date()
        
        switch self {
        case .today:
            return calendar.isDate(date, inSameDayAs: now)
        case .yesterday:
            return calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now)!)
        case .thisWeek:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .lastWeek:
            let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
            return calendar.isDate(date, equalTo: lastWeek, toGranularity: .weekOfYear)
        case .thisMonth:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .lastMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
            return calendar.isDate(date, equalTo: lastMonth, toGranularity: .month)
        case .thisYear:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        case .lastYear:
            let lastYear = calendar.date(byAdding: .year, value: -1, to: now)!
            return calendar.isDate(date, equalTo: lastYear, toGranularity: .year)
        }
    }
    
    // FIX 3: calendar.dateIntervalOfWeek doesn't exist — use dateInterval(of: .weekOfYear)
    func getDate(calendar: Calendar) -> Date {
        let now = Date()
        
        switch self {
        case .today:
            return now
        case .yesterday:
            return calendar.date(byAdding: .day, value: -1, to: now)!
        case .thisWeek:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .lastWeek:
            let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
            return calendar.dateInterval(of: .weekOfYear, for: lastWeek)?.start ?? now
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .lastMonth:
            return calendar.dateInterval(of: .month, for: calendar.date(byAdding: .month, value: -1, to: now)!)?.start ?? now
        case .thisYear:
            return calendar.dateInterval(of: .year, for: now)?.start ?? now
        case .lastYear:
            return calendar.dateInterval(of: .year, for: calendar.date(byAdding: .year, value: -1, to: now)!)?.start ?? now
        }
    }
}

/// Preset button component
struct PresetButton: View {
    let preset: DatePreset
    let isSelected: Bool
    @Binding var date: Date
    @Environment(\.colorScheme) private var colorScheme
    
    private var calendar: Calendar { Calendar.current }
    
    var body: some View {
        Button(action: {
            date = preset.getDate(calendar: calendar)
        }) {
            Text(LocalizedStringKey(preset.rawValue))
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : (colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5)))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// FIX 4: Preview macro must not contain declarations inside the closure
#Preview {
    CustomDatePickerPreview()
}

private struct CustomDatePickerPreview: View {
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Selected: \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
            Button("Show Date Picker") {}
        }
        .padding()
    }
}

// MARK: - Date Formatting Extension
extension Date {
    func formattedDate(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}
