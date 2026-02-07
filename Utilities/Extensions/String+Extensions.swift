import Foundation

// MARK: - String Extensions

extension String {
    /// Truncate string to specified length with ellipsis
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count <= length {
            return self
        }
        return String(self.prefix(length)) + trailing
    }
    
    /// Remove leading and trailing whitespace and newlines
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Check if string is a valid GitHub PAT format
    var isValidGitHubToken: Bool {
        // Classic PAT: ghp_xxxx (40+ chars total)
        let classicPattern = "^ghp_[a-zA-Z0-9]{36,}$"
        
        // Fine-grained PAT: github_pat_xxxx
        let fineGrainedPattern = "^github_pat_[a-zA-Z0-9_]{22,}$"
        
        let classicRegex = try? NSRegularExpression(pattern: classicPattern)
        let fineGrainedRegex = try? NSRegularExpression(pattern: fineGrainedPattern)
        
        let range = NSRange(self.startIndex..., in: self)
        
        let isClassic = classicRegex?.firstMatch(in: self, range: range) != nil
        let isFineGrained = fineGrainedRegex?.firstMatch(in: self, range: range) != nil
        
        // Also accept legacy 40-char hex tokens
        let isLegacy = self.count == 40 && self.allSatisfy { $0.isHexDigit }
        
        return isClassic || isFineGrained || isLegacy
    }
    
    /// Mask token for display (show first 4 and last 4 chars)
    var maskedToken: String {
        guard count > 12 else {
            return String(repeating: "*", count: count)
        }
        
        let prefix = String(self.prefix(4))
        let suffix = String(self.suffix(4))
        let middleCount = count - 8
        let middle = String(repeating: "*", count: min(middleCount, 20))
        
        return "\(prefix)\(middle)\(suffix)"
    }
}

// MARK: - URL Helpers

extension String {
    /// Convert GitHub API URL to web URL
    var githubWebURL: String? {
        guard self.contains("api.github.com") else {
            return self
        }
        
        return self
            .replacingOccurrences(of: "api.github.com/repos", with: "github.com")
            .replacingOccurrences(of: "/pulls/", with: "/pull/")
    }
}
