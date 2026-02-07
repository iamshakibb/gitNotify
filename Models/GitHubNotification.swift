import Foundation
import GRDB

// MARK: - GitHub Notification Model

/// Represents a GitHub notification from the API
struct GitHubNotification: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let repositoryFullName: String
    let repositoryOwnerAvatarURL: String?
    let subjectTitle: String
    let subjectType: SubjectType
    let subjectURL: String?
    let reason: NotificationReason
    var unread: Bool
    let updatedAt: Date
    let lastReadAt: Date?
    
    /// Computed HTML URL for opening in browser
    var htmlURL: String? {
        guard let subjectURL = subjectURL else { return nil }
        
        // Convert API URL to web URL
        // e.g., https://api.github.com/repos/owner/repo/issues/123
        // to https://github.com/owner/repo/issues/123
        return subjectURL
            .replacingOccurrences(of: "api.github.com/repos", with: "github.com")
            .replacingOccurrences(of: "/pulls/", with: "/pull/")
    }
    
    /// Computed category based on notification reason
    var category: NotificationCategory {
        switch reason {
        case .mention, .teamMention:
            return .mentioned
        case .assign, .reviewRequested, .approvalRequested:
            return .assignedTask
        case .comment, .author:
            return .comments
        default:
            return .all
        }
    }
    
    /// Display-friendly time ago string
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
}

// MARK: - Subject Type

enum SubjectType: String, Codable, CaseIterable {
    case issue = "Issue"
    case pullRequest = "PullRequest"
    case commit = "Commit"
    case release = "Release"
    case discussion = "Discussion"
    case repositoryVulnerabilityAlert = "RepositoryVulnerabilityAlert"
    case checkSuite = "CheckSuite"
    case unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = SubjectType(rawValue: rawValue) ?? .unknown
    }
    
    var icon: String {
        switch self {
        case .issue:
            return "exclamationmark.circle"
        case .pullRequest:
            return "arrow.triangle.pull"
        case .commit:
            return "point.filled.topleft.down.curvedto.point.bottomright.up"
        case .release:
            return "tag"
        case .discussion:
            return "bubble.left.and.bubble.right"
        case .repositoryVulnerabilityAlert:
            return "exclamationmark.shield"
        case .checkSuite:
            return "checkmark.circle"
        case .unknown:
            return "bell"
        }
    }
    
    var displayName: String {
        switch self {
        case .issue:
            return "Issue"
        case .pullRequest:
            return "Pull Request"
        case .commit:
            return "Commit"
        case .release:
            return "Release"
        case .discussion:
            return "Discussion"
        case .repositoryVulnerabilityAlert:
            return "Security Alert"
        case .checkSuite:
            return "Check Suite"
        case .unknown:
            return "Notification"
        }
    }
}

// MARK: - Notification Reason

enum NotificationReason: String, Codable, CaseIterable {
    case assign
    case author
    case comment
    case ciActivity = "ci_activity"
    case invitation
    case manual
    case mention
    case reviewRequested = "review_requested"
    case securityAlert = "security_alert"
    case stateChange = "state_change"
    case subscribed
    case teamMention = "team_mention"
    case approvalRequested = "approval_requested"
    case memberFeatureRequested = "member_feature_requested"
    case unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = NotificationReason(rawValue: rawValue) ?? .unknown
    }
    
    var displayName: String {
        switch self {
        case .assign:
            return "Assigned"
        case .author:
            return "Author"
        case .comment:
            return "Commented"
        case .ciActivity:
            return "CI Activity"
        case .invitation:
            return "Invitation"
        case .manual:
            return "Subscribed"
        case .mention:
            return "Mentioned"
        case .reviewRequested:
            return "Review Requested"
        case .securityAlert:
            return "Security Alert"
        case .stateChange:
            return "State Changed"
        case .subscribed:
            return "Watching"
        case .teamMention:
            return "Team Mentioned"
        case .approvalRequested:
            return "Approval Requested"
        case .memberFeatureRequested:
            return "Feature Requested"
        case .unknown:
            return "Notification"
        }
    }
}

// MARK: - Notification Category

enum NotificationCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case mentioned = "Mentioned"
    case assignedTask = "Assigned"
    case comments = "Comments"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all:
            return "bell.fill"
        case .mentioned:
            return "at"
        case .assignedTask:
            return "person.fill.checkmark"
        case .comments:
            return "bubble.left.fill"
        }
    }
}

// MARK: - GRDB Database Support

extension GitHubNotification: FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "notifications" }
    
    enum Columns: String, ColumnExpression {
        case id
        case repositoryFullName = "repository_full_name"
        case repositoryOwnerAvatarURL = "repository_owner_avatar_url"
        case subjectTitle = "subject_title"
        case subjectType = "subject_type"
        case subjectURL = "subject_url"
        case reason
        case unread
        case updatedAt = "updated_at"
        case lastReadAt = "last_read_at"
    }
    
    init(row: Row) throws {
        id = row[Columns.id]
        repositoryFullName = row[Columns.repositoryFullName]
        repositoryOwnerAvatarURL = row[Columns.repositoryOwnerAvatarURL]
        subjectTitle = row[Columns.subjectTitle]
        subjectType = SubjectType(rawValue: row[Columns.subjectType]) ?? .unknown
        subjectURL = row[Columns.subjectURL]
        reason = NotificationReason(rawValue: row[Columns.reason]) ?? .unknown
        unread = row[Columns.unread]
        updatedAt = row[Columns.updatedAt]
        lastReadAt = row[Columns.lastReadAt]
    }
    
    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.repositoryFullName] = repositoryFullName
        container[Columns.repositoryOwnerAvatarURL] = repositoryOwnerAvatarURL
        container[Columns.subjectTitle] = subjectTitle
        container[Columns.subjectType] = subjectType.rawValue
        container[Columns.subjectURL] = subjectURL
        container[Columns.reason] = reason.rawValue
        container[Columns.unread] = unread
        container[Columns.updatedAt] = updatedAt
        container[Columns.lastReadAt] = lastReadAt
    }
}

// MARK: - GitHub API Response DTOs

/// DTO for decoding GitHub API notification response
struct GitHubNotificationDTO: Codable {
    let id: String
    let repository: Repository
    let subject: Subject
    let reason: String
    let unread: Bool
    let updatedAt: String
    let lastReadAt: String?
    let url: String
    
    private enum CodingKeys: String, CodingKey {
        case id, repository, subject, reason, unread, url
        case updatedAt = "updated_at"
        case lastReadAt = "last_read_at"
    }
    
    struct Repository: Codable {
        let id: Int
        let fullName: String
        let owner: Owner
        let htmlUrl: String
        
        private enum CodingKeys: String, CodingKey {
            case id
            case fullName = "full_name"
            case owner
            case htmlUrl = "html_url"
        }
        
        struct Owner: Codable {
            let login: String
            let avatarUrl: String
            
            private enum CodingKeys: String, CodingKey {
                case login
                case avatarUrl = "avatar_url"
            }
        }
    }
    
    struct Subject: Codable {
        let title: String
        let url: String?
        let latestCommentUrl: String?
        let type: String
        
        private enum CodingKeys: String, CodingKey {
            case title, url, type
            case latestCommentUrl = "latest_comment_url"
        }
    }
    
    /// Convert DTO to domain model
    func toDomainModel() -> GitHubNotification? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try parsing with fractional seconds first, then without
        var parsedUpdatedAt = dateFormatter.date(from: updatedAt)
        if parsedUpdatedAt == nil {
            dateFormatter.formatOptions = [.withInternetDateTime]
            parsedUpdatedAt = dateFormatter.date(from: updatedAt)
        }
        
        guard let updatedAtDate = parsedUpdatedAt else {
            return nil
        }
        
        var parsedLastReadAt: Date? = nil
        if let lastRead = lastReadAt {
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            parsedLastReadAt = dateFormatter.date(from: lastRead)
            if parsedLastReadAt == nil {
                dateFormatter.formatOptions = [.withInternetDateTime]
                parsedLastReadAt = dateFormatter.date(from: lastRead)
            }
        }
        
        return GitHubNotification(
            id: id,
            repositoryFullName: repository.fullName,
            repositoryOwnerAvatarURL: repository.owner.avatarUrl,
            subjectTitle: subject.title,
            subjectType: SubjectType(rawValue: subject.type) ?? .unknown,
            subjectURL: subject.url,
            reason: NotificationReason(rawValue: reason) ?? .unknown,
            unread: unread,
            updatedAt: updatedAtDate,
            lastReadAt: parsedLastReadAt
        )
    }
}
