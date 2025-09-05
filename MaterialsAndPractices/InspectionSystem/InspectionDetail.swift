import SwiftUI
import CoreData

/// A detailed view for a single farm inspection record
struct InspectionDetailView: View {
    let inspection: Inspection

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                SectionHeader(title: "Inspection Summary")

                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    InfoBlock(label: "Inspection Type") {
                        Text(inspection.inspectionType ?? "Unknown")
                    }

                    InfoBlock(label: "Inspector") {
                        Text(inspection.inspectorName ?? "Unknown")
                    }

                    InfoBlock(label: "Scheduled Date") {
                        if let scheduled = inspection.scheduledDate {
                            Text(scheduled.formatted(date: .long, time: .omitted))
                        } else {
                            Text("Not Scheduled")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }

                    InfoBlock(label: "Completed Date") {
                        if let completed = inspection.completedDate {
                            Text(completed.formatted(date: .long, time: .omitted))
                        } else {
                            Text("Not Completed")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }

                    InfoBlock(label: "Status") {
                        Text(inspection.status?.capitalized ?? "Unknown")
                            .foregroundColor(statusColor)
                    }

                    if let notes = inspection.notes, !notes.isEmpty {
                        InfoBlock(label: "Notes") {
                            Text(notes)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Inspection Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusColor: Color {
        switch inspection.status?.lowercased() {
        case "completed": return AppTheme.Colors.success
        case "scheduled": return AppTheme.Colors.primary
        case "cancelled": return AppTheme.Colors.error
        case "in progress": return AppTheme.Colors.warning
        default: return AppTheme.Colors.textSecondary
        }
    }
}
