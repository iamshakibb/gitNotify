import SwiftUI

// MARK: - Token Input View

/// Initial setup screen for entering GitHub token
struct TokenInputView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var isSecure = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Welcome to GitNotify")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enter your GitHub Personal Access Token\nto get started.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)
            
            // Token Input
            VStack(alignment: .leading, spacing: 8) {
                Text("GitHub Token")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                HStack {
                    Group {
                        if isSecure {
                            SecureField("ghp_xxxx...", text: $authVM.tokenInput)
                        } else {
                            TextField("ghp_xxxx...", text: $authVM.tokenInput)
                        }
                    }
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    
                    Button(action: { isSecure.toggle() }) {
                        Image(systemName: isSecure ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(isSecure ? "Show token" : "Hide token")
                }
                .padding(12)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
            .padding(.horizontal, 32)
            
            // Error message
            if let error = authVM.error {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text(error.errorDescription ?? "An error occurred")
                        .foregroundColor(.red)
                }
                .font(.caption)
                .padding(.top, 12)
            }
            
            // Required scope info
            VStack(spacing: 4) {
                Text("Required scope: ")
                    .foregroundColor(.secondary)
                + Text("notifications")
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .font(.caption)
            .padding(.top, 16)
            
            // Create token link
            Button(action: { authVM.openTokenCreationPage() }) {
                HStack(spacing: 4) {
                    Text("Create a new token on GitHub")
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundColor(.accentColor)
            .padding(.top, 8)
            
            Spacer()
            
            // Connect button
            Button(action: {
                Task {
                    await authVM.authenticate()
                }
            }) {
                HStack {
                    if authVM.isValidating {
                        ProgressView()
                            .scaleEffect(0.7)
                            .progressViewStyle(.circular)
                    }
                    
                    Text(authVM.isValidating ? "Validating..." : "Connect GitHub")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(buttonBackground)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(authVM.tokenInput.isEmpty || authVM.isValidating)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var buttonBackground: some ShapeStyle {
        if authVM.tokenInput.isEmpty || authVM.isValidating {
            return AnyShapeStyle(Color.accentColor.opacity(0.5))
        }
        return AnyShapeStyle(Color.accentColor)
    }
}

// MARK: - Preview

#Preview {
    TokenInputView()
        .environmentObject(AuthViewModel())
        .frame(width: 400, height: 520)
}
