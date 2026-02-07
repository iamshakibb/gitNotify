import Foundation

// MARK: - Date Extensions

extension Date {
    /// Returns a human-readable relative time string
    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Returns a formatted date string for display
    var formattedString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Check if date is within the last N minutes
    func isWithinLastMinutes(_ minutes: Int) -> Bool {
        let cutoff = Date().addingTimeInterval(-TimeInterval(minutes * 60))
        return self > cutoff
    }
    
    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
}

// MARK: - ISO8601 Parsing

extension Date {
    /// Parse ISO8601 date string (handles both with and without fractional seconds)
    static func fromISO8601(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        
        // Try with fractional seconds first
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return date
        }
        
        // Fallback to without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
    
    /// Convert to ISO8601 string
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: self)
    }
}
