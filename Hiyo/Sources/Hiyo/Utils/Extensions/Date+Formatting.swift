//
//  Date+Formatting.swift
//  Hiyo
//
//  Date extension methods for display formatting.
//

import Foundation

extension Date {
    /// Formats for conversation list display
    var conversationListFormatted: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            // Today: show time only
            return self.formatted(date: .omitted, time: .shortened)
        } else if calendar.isDateInYesterday(self) {
            // Yesterday
            return "Yesterday"
        } else if calendar.isDate(self, equalTo: now, toGranularity: .weekOfYear) {
            // This week: show day name
            return self.formatted(.dateTime.weekday(.wide))
        } else if calendar.isDate(self, equalTo: now, toGranularity: .year) {
            // This year: show month and day
            return self.formatted(.dateTime.month(.abbreviated).day())
        } else {
            // Different year: show short date
            return self.formatted(.dateTime.month(.abbreviated).day().year(.twoDigits))
        }
    }
    
    /// Formats for message timestamp
    var messageTimestampFormatted: String {
        self.formatted(.dateTime.hour().minute())
    }
    
    /// Formats for detailed info
    var detailedFormatted: String {
        self.formatted(.dateTime.month(.wide).day().year().hour().minute())
    }
    
    /// Formats as ISO 8601 for storage
    var iso8601Formatted: String {
        ISO8601DateFormatter().string(from: self)
    }
    
    /// Relative time description
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Time ago in words
    var timeAgo: String {
        let interval = Date().timeIntervalSince(self)
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let days = hours / 24
        
        switch minutes {
        case 0...1:
            return "Just now"
        case 2...59:
            return "\(minutes)m ago"
        case 60...119:
            return "1h ago"
        case 120...1439:
            return "\(hours)h ago"
        case 1440...2879:
            return "Yesterday"
        default:
            return "\(days)d ago"
        }
    }
    
    /// Checks if date is within the last n days
    func isWithinLastDays(_ days: Int) -> Bool {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        return self >= startDate
    }
    
    /// Start of day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// End of day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: self.startOfDay)!
    }
}

// MARK: - ISO 8601 Parsing

extension Date {
    /// Parses ISO 8601 string
    static func fromISO8601(_ string: String) -> Date? {
        ISO8601DateFormatter().date(from: string)
    }
}

// MARK: - Conversation Grouping

extension Date {
    /// Groups conversations by time period
    var conversationGroup: ConversationGroup {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            return .today
        } else if calendar.isDateInYesterday(self) {
            return .yesterday
        } else if self.isWithinLastDays(7) {
            return .thisWeek
        } else if self.isWithinLastDays(30) {
            return .thisMonth
        } else {
            return .older
        }
    }
    
    enum ConversationGroup: String, CaseIterable {
        case today = "Today"
        case yesterday = "Yesterday"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case older = "Older"
        
        var sortOrder: Int {
            switch self {
            case .today: return 0
            case .yesterday: return 1
            case .thisWeek: return 2
            case .thisMonth: return 3
            case .older: return 4
            }
        }
    }
}
