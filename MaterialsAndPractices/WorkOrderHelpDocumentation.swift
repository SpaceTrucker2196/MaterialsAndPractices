import SwiftUI

struct WorkOrderHelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: HelpSection? = .overview

    var body: some View {
        NavigationSplitView {
            List(HelpSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            .navigationTitle("Help Topics")
        } detail: {
            if let selected = selectedSection {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                        selected.content
                    }
                    .padding()
                    .navigationTitle(selected.rawValue)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Done") {
                                dismiss()
                            }
                        }
                    }
                }
                .background(AppTheme.Colors.backgroundPrimary)
            } else {
                Text("Select a help topic")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .font(AppTheme.Typography.bodyMedium)
            }
        }
    }
}
