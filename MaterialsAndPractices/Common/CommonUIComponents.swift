//
//  CommonUIComponents.swift
//  MaterialsAndPractices
//
//  Common UI components used throughout the farm management system.
//  Provides consistent styling and reusable interface elements.
//
//  Created by AI Assistant on current date.
//

import SwiftUI

// MARK: - Section Header

/// Consistent section header component
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(AppTheme.Typography.headlineSmall)
            .foregroundColor(AppTheme.Colors.primary)
            .padding(.bottom, AppTheme.Spacing.small)
    }
}

// MARK: - Info Row

/// Information display row with label and value
struct CommonInfoRow<Content: View>: View {
    let label: String
    @ViewBuilder var value: Content

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.small) {
            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(minWidth: 120, alignment: .leading)
            value
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Date Info Row

/// Specialized info row for date display
//struct CommonDateInfoRow: View {
//    let label: String
//    let date: Date?
//    let formatter: DateFormatter
//    
//    var body: some View {
//        CommonInfoRow (
//            label: label,
//            value: date != nil ? formatter.string(from: date!) : "Not Set"
//        )
//    }
//}

// MARK: - Action Button

/// Consistent action button component
struct CommonActionButton: View {
    let title: String
    let action: () -> Void
    let style: ActionButtonStyle
    
    enum ActionButtonStyle {
        case primary, secondary, destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return AppTheme.Colors.primary
            case .secondary:
                return AppTheme.Colors.secondary
            case .destructive:
                return AppTheme.Colors.error
            }
        }
        
        var foregroundColor: Color {
            return .white
        }
    }
    
    init(title: String, style: ActionButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(style.foregroundColor)
                .frame(maxWidth: .infinity)
                .padding()
                .background(style.backgroundColor)
                .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
}

// MARK: - Metadata Tag

/// Small tag component for displaying metadata
struct MetadataTag: View {
    let text: String
    let backgroundColor: Color
    let textColor: Color
    
    init(text: String, backgroundColor: Color, textColor: Color = AppTheme.Colors.textPrimary) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
    
    var body: some View {
        Text(text)
            .font(AppTheme.Typography.labelSmall)
            .foregroundColor(textColor)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.tiny)
            .background(backgroundColor)
            .cornerRadius(AppTheme.CornerRadius.small)
    }
}

// MARK: - Loading View

/// Standard loading indicator
struct LoadingView: View {
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.backgroundPrimary)
    }
}

// MARK: - Error View

/// Standard error display component
struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?
    
    init(message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.error)
            
            Text("Error")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(message)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            if let retryAction = retryAction {
                CommonActionButton(title: "Retry", action: retryAction)
                    .frame(maxWidth: 200)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.backgroundPrimary)
    }
}

// MARK: - Empty State View

/// Standard empty state component
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        message: String,
        systemImage: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: systemImage)
                .font(.system(size: 64))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            VStack(spacing: AppTheme.Spacing.small) {
                Text(title)
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(message)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                CommonActionButton(title: actionTitle, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.backgroundPrimary)
    }
}

// MARK: - Form Section

/// Consistent form section wrapper
struct FormSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: title)
            content
        }
        .padding(.vertical, AppTheme.Spacing.small)
    }
}

// MARK: - AppTheme Extensions

//extension AppTheme {
//    /// Corner radius values
//    enum CornerRadius {
//        static let small: CGFloat = 4
//        static let medium: CGFloat = 8
//        static let large: CGFloat = 12
//    }
//}
