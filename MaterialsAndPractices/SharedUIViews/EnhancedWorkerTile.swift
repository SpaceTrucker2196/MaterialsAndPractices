//
//  EnhancedWorkerTile.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 8/30/25.
//

import SwiftUICore
import SwiftUI

/// Enhanced worker tile with long press gesture for time clock management
struct EnhancedWorkerTile: View {
    let worker: Worker
    @Environment(\.managedObjectContext) private var viewContext

    // State for clock management
    @State private var isClockedIn = false
    @State private var todayHoursWorked: Double = 0
    @State private var showingClockActionSheet = false

    var body: some View {
        NavigationLink(destination: WorkerDetailView(worker: worker)) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                workerHeaderSection
                workerInfoSection
                timeTrackingSection
                statusIndicatorsSection
            }
            .padding(AppTheme.Spacing.medium)
            .frame(height: DeviceDetection.isiPad ? 240 : 120)
            .background(workerBackgroundColor)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(workerBorderOverlay)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.5) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            showingClockActionSheet = true
        }
        .actionSheet(isPresented: $showingClockActionSheet) {
            clockActionSheet
        }
        .onAppear {
            loadWorkerTimeData()
        }
    }

    // MARK: - UI Sections

    private var workerHeaderSection: some View {
        HStack {
            if let profileImage = ImageUtilities.loadWorkerProfileImage(for: worker) {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: DeviceDetection.isiPad ? 60 : 40,
                           height: DeviceDetection.isiPad ? 60 : 40)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(AppTheme.Colors.backgroundSecondary)
                    .frame(width: DeviceDetection.isiPad ? 60 : 40,
                           height: DeviceDetection.isiPad ? 60 : 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(DeviceDetection.isiPad ? .title2 : .caption)
                            .foregroundColor(AppTheme.Colors.primary)
                    )
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                Circle()
                    .fill(clockStatusColor)
                    .frame(width: 12, height: 12)

                if DeviceDetection.isiPad {
                    Text(isClockedIn ? "Active" : "Idle")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(clockStatusColor)
                }
            }
        }
    }

    private var workerInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            Text(worker.name ?? "Unknown Worker")
                .font(DeviceDetection.isiPad ? AppTheme.Typography.headlineMedium : AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(DeviceDetection.isiPad ? 2 : 1)

            if let position = worker.position {
                Text(position)
                    .font(DeviceDetection.isiPad ? AppTheme.Typography.bodyMedium : AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    private var timeTrackingSection: some View {
        Group {
            if DeviceDetection.isiPad {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text("Today")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        Text("\(todayHoursWorked, specifier: "%.1f") hrs")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    if isClockedIn {
                        Text("Working")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.Colors.success)
                            .cornerRadius(AppTheme.CornerRadius.small)
                    }
                }
            }
        }
    }

    private var statusIndicatorsSection: some View {
        Group {
            if !DeviceDetection.isiPad {
                HStack {
                    Text("\(todayHoursWorked, specifier: "%.1f") hrs today")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Spacer()

                    Text(isClockedIn ? "Working" : "Available")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(clockStatusColor)
                }
            }
        }
    }

    private var clockActionSheet: ActionSheet {
        ActionSheet(
            title: Text(worker.name ?? "Worker"),
            message: Text(isClockedIn ? "Clock out this worker?" : "Clock in this worker?"),
            buttons: [
                .default(Text(isClockedIn ? "Clock Out" : "Clock In")) {
                    toggleClockStatus()
                },
                .cancel()
            ]
        )
    }

    private var clockStatusColor: Color {
        isClockedIn ? AppTheme.Colors.success : AppTheme.Colors.textSecondary
    }

    private var workerBackgroundColor: Color {
        isClockedIn ? AppTheme.Colors.success.opacity(0.05) : AppTheme.Colors.backgroundSecondary
    }

    private var workerBorderOverlay: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
            .stroke(
                isClockedIn ? AppTheme.Colors.success.opacity(0.3) : Color.clear,
                lineWidth: isClockedIn ? 2 : 0
            )
    }

    private func loadWorkerTimeData() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        if let timeEntries = worker.timeClockEntries?.allObjects as? [TimeClock] {
            isClockedIn = timeEntries.contains {
                guard let entryDate = $0.date,
                      entryDate >= today && entryDate < tomorrow else { return false }
                return $0.isActive
            }

            let todayEntries = timeEntries.filter {
                guard let entryDate = $0.date else { return false }
                return entryDate >= today && entryDate < tomorrow
            }

            todayHoursWorked = todayEntries.reduce(0) { $0 + $1.hoursWorked }
        }

        if worker.profilePhotoData == nil {
            ImageUtilities.generateProfilePhotoDataIfNeeded(for: worker, context: viewContext)
        }
    }

    private func toggleClockStatus() {
        isClockedIn ? clockOut() : clockIn()
    }

    private func clockIn() {
        let newEntry = TimeClock(context: viewContext)
        newEntry.id = UUID()
        newEntry.worker = worker
        newEntry.date = Date()
        newEntry.clockInTime = Date()
        newEntry.isActive = true

        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear, .year], from: Date())
        newEntry.weekNumber = Int16(components.weekOfYear ?? 1)
        newEntry.year = Int16(components.year ?? calendar.component(.year, from: Date()))

        do {
            try viewContext.save()
            loadWorkerTimeData()
        } catch {
            print("Error clocking in worker: \(error)")
        }
    }

    private func clockOut() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        if let timeEntries = worker.timeClockEntries?.allObjects as? [TimeClock],
           let activeEntry = timeEntries.first(where: {
               guard let entryDate = $0.date,
                     entryDate >= today && entryDate < tomorrow else { return false }
               return $0.isActive
           }) {

            activeEntry.clockOutTime = Date()
            activeEntry.isActive = false

            if let clockInTime = activeEntry.clockInTime,
               let clockOutTime = activeEntry.clockOutTime {
                let hoursWorked = clockOutTime.timeIntervalSince(clockInTime) / 3600
                activeEntry.hoursWorked = hoursWorked
            }

            do {
                try viewContext.save()
                loadWorkerTimeData()
            } catch {
                print("Error clocking out worker: \(error)")
            }
        }
    }
}
