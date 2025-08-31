import SwiftUI
import CoreData

/// Comprehensive farm staff view showing all workers with position grouping and enhanced interactions
struct FarmStaffView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Worker data fetching
    @FetchRequest(
        entity: Worker.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Worker.isActive, ascending: false),
            NSSortDescriptor(keyPath: \Worker.position, ascending: true),
            NSSortDescriptor(keyPath: \Worker.name, ascending: true)
        ]
    ) var allWorkers: FetchedResults<Worker>

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    ForEach(groupedWorkersByPosition.keys.sorted(), id: \.self) { position in
                        if let workers = groupedWorkersByPosition[position] {
                            WorkerPositionSection(position: position, workers: workers)
                        }
                    }
                }
                .padding(AppTheme.Spacing.medium)
            }
            .navigationTitle("Farm Staff")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CreateWorkerView(isPresented: .constant(false))) {
                        Image(systemName: "plus")
                            .font(AppTheme.Typography.bodyMedium)
                    }
                }
            }
        }
    }

    /// Group workers by their position
    private var groupedWorkersByPosition: [String: [Worker]] {
        let activeWorkers = allWorkers.filter { $0.isActive }
        return Dictionary(grouping: activeWorkers) { worker in
            worker.position?.isEmpty == false ? worker.position! : "General"
        }
    }
}

/// Section view for displaying workers in a specific position
private struct WorkerPositionSection: View {
    let position: String
    let workers: [Worker]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(position)
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                Text("\(workers.count) worker\(workers.count == 1 ? "" : "s")")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            LazyVGrid(columns: responsiveGridColumns, spacing: AppTheme.Spacing.medium) {
                ForEach(workers, id: \.id) { worker in
                    EnhancedWorkerTile(worker: worker)
                }
            }
        }
    }

    private var responsiveGridColumns: [GridItem] {
        let columnCount = DeviceDetection.isiPad ? 2 : 2
        return Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.medium), count: columnCount)
    }
}
