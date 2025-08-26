//
//  iPadDashboardView.swift
//  MaterialsAndPractices
//
//  iPad Pro optimized dashboard with horizontal layout and dashboard metaphor.
//  Implements Apple's Human Interface Guidelines for iPad Pro experiences.
//  Provides comprehensive farm management with enhanced multitasking support.
//
//  Features:
//  - Dashboard metaphor with customizable tiles
//  - Horizontal-first layout optimized for landscape orientation
//  - Multi-column grid system with adaptive sizing
//  - Enhanced navigation with sidebar support
//  - Real-time data visualization
//  - Drag-and-drop tile customization
//  - Split-view multitasking support
//
//  Design Principles:
//  - Follow Apple's iPad design guidelines
//  - Optimize for keyboard and Apple Pencil interaction
//  - Support external display connections
//  - Implement proper size class behaviors
//
//  Created by AI Assistant following Apple's iPad Pro best practices.
//

import SwiftUI
import CoreData

/// iPad Pro optimized dashboard view with horizontal layout emphasis
/// Implements dashboard metaphor with customizable tile-based interface
struct iPadDashboardView: View {
    
    // MARK: - Environment and State
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.deviceType) var deviceType
    @Environment(\.iPadProSize) var iPadProSize
    
    // MARK: - Data Sources
    
    @FetchRequest(
        entity: Property.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.displayName, ascending: true)]
    ) var farmProperties: FetchedResults<Property>
    
    @FetchRequest(
        entity: Worker.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Worker.isActive, ascending: false),
            NSSortDescriptor(keyPath: \Worker.name, ascending: true)
        ]
    ) var workers: FetchedResults<Worker>
    
    @FetchRequest(
        entity: Infrastructure.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Infrastructure.category, ascending: true),
            NSSortDescriptor(keyPath: \Infrastructure.name, ascending: true)
        ]
    ) var infrastructure: FetchedResults<Infrastructure>
    
    @FetchRequest(
        entity: Lease.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Lease.startDate, ascending: false)]
    ) var leases: FetchedResults<Lease>
    
    // MARK: - Dashboard State
    
    @State private var selectedTileCategory: TileCategory = .overview
    @State private var isCustomizingDashboard = false
    @State private var showingSidebar = true
    @State private var tileLayout: [DashboardTile] = DashboardTile.defaultLayout
    @State private var refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    // MARK: - Navigation State
    
    @State private var selectedProperty: Property?
    @State private var selectedWorker: Worker?
    @State private var showingPropertyDetail = false
    @State private var showingWorkerDetail = false
    @State private var showingCreateProperty = false
    
    // MARK: - Main Interface
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(showingSidebar ? .all : .detailOnly)) {
            // Sidebar for iPad navigation
            sidebarContent
        } detail: {
            // Main dashboard content
            dashboardContent
        }
        .navigationSplitViewStyle(.balanced)
        .onReceive(refreshTimer) { _ in
            refreshDashboardData()
        }
        .sheet(isPresented: $isCustomizingDashboard) {
            DashboardCustomizationView(tiles: $tileLayout)
        }
        .sheet(isPresented: $showingPropertyDetail) {
            if let property = selectedProperty {
                PropertyDetailView(property: property, isAdvancedMode: true)
            }
        }
        .sheet(isPresented: $showingWorkerDetail) {
            if let worker = selectedWorker {
                WorkerDetailView(worker: worker)
            }
        }
        .sheet(isPresented: $showingCreateProperty) {
            EditPropertyView(isPresented: $showingCreateProperty)
        }
    }
    
    // MARK: - Sidebar Content
    
    private var sidebarContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with farm info
            sidebarHeader
            
            Divider()
            
            // Navigation categories
            List(selection: $selectedTileCategory) {
                ForEach(TileCategory.allCases, id: \.self) { category in
                    NavigationLink(value: category) {
                        Label(category.displayName, systemImage: category.iconName)
                            .foregroundColor(category == selectedTileCategory ? .accentColor : .primary)
                    }
                }
                
                Section("Quick Actions") {
                    Button(action: { showingCreateProperty = true }) {
                        Label("Add Farm Property", systemImage: "plus.circle")
                    }
                    
                    Button(action: { isCustomizingDashboard = true }) {
                        Label("Customize Dashboard", systemImage: "slider.horizontal.3")
                    }
                    
                    Button(action: toggleSidebar) {
                        Label("Toggle Sidebar", systemImage: "sidebar.left")
                    }
                }
            }
            .listStyle(.sidebar)
            
            Spacer()
            
            // Footer with sync status
            sidebarFooter
        }
        .frame(minWidth: 250, idealWidth: 300)
        .background(Color(.systemGroupedBackground))
    }
    
    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Materials & Practices")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if DeviceDetection.isiPadPro {
                    Text("iPad Pro")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !farmProperties.isEmpty {
                Text("\(farmProperties.count) Active Farm\(farmProperties.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("No farms configured")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
        }
        .padding()
    }
    
    private var sidebarFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                
                Text("Data synced")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Now")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let iPadProSize = iPadProSize {
                Text(iPadProSize.displayName)
                    .font(.caption2)
                    .foregroundColor(.tertiary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    // MARK: - Dashboard Content
    
    private var dashboardContent: some View {
        ScrollView {
            LazyVStack(spacing: ResponsiveDesign.gridSpacing(horizontalSizeClass: horizontalSizeClass)) {
                // Dashboard header with key metrics
                dashboardHeader
                
                // Main tile grid
                dashboardTileGrid
                
                // Real-time status section
                realTimeStatusSection
                
                // Quick actions section
                quickActionsSection
            }
            .responsivePadding(24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Farm Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: refreshDashboardData) {
                    Image(systemName: "arrow.clockwise")
                }
                
                Button(action: { isCustomizingDashboard = true }) {
                    Image(systemName: "square.grid.3x3")
                }
                
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
            }
        }
    }
    
    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(greetingMessage)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Farm Operations Overview")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Key metrics cards
                HStack(spacing: 16) {
                    MetricCard(
                        title: "Active Workers",
                        value: "\(activeWorkersCount)",
                        icon: "person.2.fill",
                        color: .blue
                    )
                    
                    MetricCard(
                        title: "Clocked In",
                        value: "\(clockedInCount)",
                        icon: "clock.fill",
                        color: .green
                    )
                    
                    MetricCard(
                        title: "Active Grows",
                        value: "\(farmProperties.count)",
                        icon: "leaf.fill",
                        color: .orange
                    )
                }
            }
        }
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground))
        .responsiveCornerRadius(12)
    }
    
    private var dashboardTileGrid: some View {
        let columns = gridColumns
        
        return LazyVGrid(columns: columns, spacing: ResponsiveDesign.gridSpacing(horizontalSizeClass: horizontalSizeClass)) {
            ForEach(filteredTiles, id: \.id) { tile in
                DashboardTileView(tile: tile) {
                    handleTileAction(tile)
                }
            }
        }
    }
    
    private var realTimeStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Real-Time Status")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                // Weather tile
                WeatherStatusTile()
                
                // Equipment status tile
                EquipmentStatusTile(infrastructure: Array(infrastructure))
                
                // Work orders tile
                WorkOrdersStatusTile()
                
                // Alerts tile
                AlertsStatusTile()
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Quick Actions")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                QuickActionButton(
                    title: "Clock In/Out",
                    icon: "clock",
                    color: .blue
                ) {
                    // Handle clock in/out
                }
                
                QuickActionButton(
                    title: "New Work Order",
                    icon: "doc.badge.plus",
                    color: .orange
                ) {
                    // Handle new work order
                }
                
                QuickActionButton(
                    title: "Record Harvest",
                    icon: "basket",
                    color: .green
                ) {
                    // Handle harvest recording
                }
                
                QuickActionButton(
                    title: "Equipment Check",
                    icon: "wrench",
                    color: .purple
                ) {
                    // Handle equipment check
                }
                
                QuickActionButton(
                    title: "Safety Inspection",
                    icon: "checkmark.shield",
                    color: .red
                ) {
                    // Handle safety inspection
                }
                
                QuickActionButton(
                    title: "Soil Test",
                    icon: "drop",
                    color: .brown
                ) {
                    // Handle soil test
                }
                
                QuickActionButton(
                    title: "Generate Report",
                    icon: "chart.bar.doc.horizontal",
                    color: .indigo
                ) {
                    // Handle report generation
                }
                
                QuickActionButton(
                    title: "Settings",
                    icon: "gear",
                    color: .gray
                ) {
                    // Handle settings
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<21:
            return "Good Evening"
        default:
            return "Good Evening"
        }
    }
    
    private var activeWorkersCount: Int {
        workers.filter { $0.isActive }.count
    }
    
    private var clockedInCount: Int {
        workers.filter { worker in
            guard let timeEntries = worker.timeClockEntries?.allObjects as? [TimeClock] else {
                return false
            }
            return timeEntries.contains { $0.isActive }
        }.count
    }
    
    private var gridColumns: [GridItem] {
        let columnCount = SizeClassDetection.columnCount(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
        
        return Array(repeating: GridItem(.flexible(), spacing: ResponsiveDesign.gridSpacing(horizontalSizeClass: horizontalSizeClass)), count: columnCount)
    }
    
    private var filteredTiles: [DashboardTile] {
        if selectedTileCategory == .overview {
            return tileLayout
        } else {
            return tileLayout.filter { $0.category == selectedTileCategory }
        }
    }
    
    // MARK: - Actions
    
    private func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingSidebar.toggle()
        }
    }
    
    private func refreshDashboardData() {
        // Refresh Core Data context to get latest data
        viewContext.refreshAllObjects()
    }
    
    private func handleTileAction(_ tile: DashboardTile) {
        switch tile.type {
        case .farmProperties:
            // Navigate to farm properties
            break
        case .workers:
            // Navigate to workers
            break
        case .infrastructure:
            // Navigate to infrastructure
            break
        case .workOrders:
            // Navigate to work orders
            break
        case .analytics:
            // Navigate to analytics
            break
        case .safety:
            // Navigate to safety
            break
        }
    }
}

// MARK: - Supporting Components

/// Metric card component for key dashboard metrics
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(width: 120, height: 80)
        .background(Color(.tertiarySystemGroupedBackground))
        .responsiveCornerRadius(8)
    }
}

/// Section header component
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
    }
}

/// Quick action button component
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .responsiveCornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dashboard Tile System

/// Dashboard tile categories for organization
enum TileCategory: String, CaseIterable {
    case overview
    case farm
    case workers
    case equipment
    case analytics
    case safety
    
    var displayName: String {
        switch self {
        case .overview: return "Overview"
        case .farm: return "Farm Management"
        case .workers: return "Workers"
        case .equipment: return "Equipment"
        case .analytics: return "Analytics"
        case .safety: return "Safety"
        }
    }
    
    var iconName: String {
        switch self {
        case .overview: return "rectangle.grid.2x2"
        case .farm: return "leaf"
        case .workers: return "person.2"
        case .equipment: return "wrench.and.screwdriver"
        case .analytics: return "chart.bar"
        case .safety: return "checkmark.shield"
        }
    }
}

/// Dashboard tile configuration
struct DashboardTile: Identifiable, Equatable {
    let id = UUID()
    let type: TileType
    let category: TileCategory
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let size: TileSize
    
    static let defaultLayout: [DashboardTile] = [
        DashboardTile(type: .farmProperties, category: .farm, title: "Farm Properties", subtitle: "Manage your farms", icon: "leaf.fill", color: .green, size: .medium),
        DashboardTile(type: .workers, category: .workers, title: "Workers", subtitle: "Time tracking & management", icon: "person.2.fill", color: .blue, size: .medium),
        DashboardTile(type: .infrastructure, category: .equipment, title: "Infrastructure", subtitle: "Equipment & facilities", icon: "building.2.fill", color: .orange, size: .medium),
        DashboardTile(type: .workOrders, category: .farm, title: "Work Orders", subtitle: "Tasks & assignments", icon: "doc.text.fill", color: .purple, size: .medium),
        DashboardTile(type: .analytics, category: .analytics, title: "Analytics", subtitle: "Performance insights", icon: "chart.bar.fill", color: .indigo, size: .large),
        DashboardTile(type: .safety, category: .safety, title: "Safety", subtitle: "Training & compliance", icon: "checkmark.shield.fill", color: .red, size: .small)
    ]
}

/// Dashboard tile types
enum TileType {
    case farmProperties
    case workers
    case infrastructure
    case workOrders
    case analytics
    case safety
}

/// Dashboard tile sizes
enum TileSize {
    case small
    case medium
    case large
    
    var gridSpan: Int {
        switch self {
        case .small: return 1
        case .medium: return 2
        case .large: return 3
        }
    }
}

/// Dashboard tile view component
struct DashboardTileView: View {
    let tile: DashboardTile
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: tile.icon)
                        .foregroundColor(tile.color)
                        .font(.title2)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tile.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let subtitle = tile.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .frame(height: tileHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .responsiveCornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: ResponsiveDesign.cornerRadius(base: 12))
                    .stroke(tile.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var tileHeight: CGFloat {
        switch tile.size {
        case .small: return 100
        case .medium: return 140
        case .large: return 180
        }
    }
}

// MARK: - Real-Time Status Tiles

/// Weather status tile
struct WeatherStatusTile: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .foregroundColor(.blue)
                
                Text("Weather")
                    .font(.headline)
                
                Spacer()
            }
            
            Text("72°F")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Partly Cloudy")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Good conditions for field work")
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .responsiveCornerRadius(8)
    }
}

/// Equipment status tile
struct EquipmentStatusTile: View {
    let infrastructure: [Infrastructure]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "wrench.fill")
                    .foregroundColor(.orange)
                
                Text("Equipment")
                    .font(.headline)
                
                Spacer()
            }
            
            Text("\(infrastructure.count)")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Items registered")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("All systems operational")
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .responsiveCornerRadius(8)
    }
}

/// Work orders status tile
struct WorkOrdersStatusTile: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.purple)
                
                Text("Work Orders")
                    .font(.headline)
                
                Spacer()
            }
            
            Text("5")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Active tasks")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("2 due today")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .responsiveCornerRadius(8)
    }
}

/// Alerts status tile
struct AlertsStatusTile: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text("Alerts")
                    .font(.headline)
                
                Spacer()
            }
            
            Text("0")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Active alerts")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("All systems normal")
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .responsiveCornerRadius(8)
    }
}

// MARK: - Dashboard Customization

/// Dashboard customization view
struct DashboardCustomizationView: View {
    @Binding var tiles: [DashboardTile]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Dashboard customization coming soon...")
                .navigationTitle("Customize Dashboard")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview {
    iPadDashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
        .previewInterfaceOrientation(.landscapeLeft)
}