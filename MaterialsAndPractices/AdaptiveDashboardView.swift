//
//  AdaptiveDashboardView.swift
//  MaterialsAndPractices
//
//  Adaptive dashboard view that provides hybrid iOS/iPadOS experience.
//  Automatically switches between iPhone compact layout and iPad dashboard layout.
//  Implements Apple's adaptive design guidelines for universal apps.
//
//  Features:
//  - Automatic device detection and layout switching
//  - Size class responsive design
//  - Shared data and business logic
//  - Consistent navigation patterns
//  - Optimized for each platform's strengths
//
//  Design Philosophy:
//  - iPhone: Tab-based navigation with focused, single-column layouts
//  - iPad: Sidebar navigation with multi-column dashboard layouts
//  - Universal: Shared components and consistent data presentation
//
//  Created by AI Assistant following Apple's Universal App best practices.
//

import SwiftUI
import CoreData

/// Adaptive dashboard that provides optimal experience across all device types
/// Automatically switches between compact (iPhone) and regular (iPad) layouts
struct AdaptiveDashboardView: View {
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.deviceType) var deviceType
    
    // MARK: - State Management
    
    @State private var selectedTab: TabItem = .dashboard
    @State private var showingSidebar = true
    
    // MARK: - Main Interface
    
    var body: some View {
        Group {
            if shouldUseiPadLayout {
                // iPad optimized layout with sidebar
                iPadLayout
            } else {
                // iPhone optimized layout with tab bar
                iPhoneLayout
            }
        }
        .onAppear {
            configureForCurrentDevice()
        }
        .onChange(of: horizontalSizeClass) { _, _ in
            configureForCurrentDevice()
        }
    }
    
    // MARK: - iPad Layout
    
    private var iPadLayout: some View {
        iPadDashboardView()
            .environment(\.managedObjectContext, viewContext)
    }
    
    // MARK: - iPhone Layout
    
    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            CompactDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "rectangle.grid.2x2")
                }
                .tag(TabItem.dashboard)
            
            // Farm Tab
            NavigationStack {
                FarmDashboardView()
            }
            .tabItem {
                Label("Farm", systemImage: "leaf")
            }
            .tag(TabItem.farm)
            
            // Workers Tab
            NavigationStack {
                WorkerListView()
            }
            .tabItem {
                Label("Workers", systemImage: "person.2")
            }
            .tag(TabItem.workers)
            
            // Equipment Tab
            NavigationStack {
                InfrastructureManagementView()
            }
            .tabItem {
                Label("Equipment", systemImage: "wrench.and.screwdriver")
            }
            .tag(TabItem.equipment)
            
            // More Tab
            NavigationStack {
                MoreView()
            }
            .tabItem {
                Label("More", systemImage: "ellipsis.circle")
            }
            .tag(TabItem.more)
        }
        .accentColor(AppTheme.Colors.primary)
    }
    
    // MARK: - Computed Properties
    
    /// Determine if we should use iPad layout based on size class and device
    private var shouldUseiPadLayout: Bool {
        // Use iPad layout for regular size class or explicitly iPad devices
        return SizeClassDetection.isRegular(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        ) || DeviceDetection.isiPad
    }
    
    // MARK: - Configuration
    
    private func configureForCurrentDevice() {
        // Configure sidebar visibility for iPad
        if DeviceDetection.isiPad {
            showingSidebar = horizontalSizeClass == .regular
        } else {
            showingSidebar = false
        }
    }
}

// MARK: - Tab Navigation

/// Tab items for iPhone navigation
enum TabItem: String, CaseIterable {
    case dashboard
    case farm
    case workers
    case equipment
    case more
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .farm: return "Farm"
        case .workers: return "Workers"
        case .equipment: return "Equipment"
        case .more: return "More"
        }
    }
    
    var iconName: String {
        switch self {
        case .dashboard: return "rectangle.grid.2x2"
        case .farm: return "leaf"
        case .workers: return "person.2"
        case .equipment: return "wrench.and.screwdriver"
        case .more: return "ellipsis.circle"
        }
    }
}

// MARK: - Compact Dashboard for iPhone

/// Compact dashboard view optimized for iPhone
struct CompactDashboardView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
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
            NSSortDescriptor(keyPath: \Infrastructure.name, ascending: true)
        ]
    ) var infrastructure: FetchedResults<Infrastructure>
    
    @State private var showingCreateProperty = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header with key metrics
                    compactHeaderSection
                    
                    // Quick stats cards
                    quickStatsSection
                    
                    // Recent activity
                    recentActivitySection
                    
                    // Quick actions
                    quickActionsSection
                }
                .responsivePadding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateProperty = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateProperty) {
                EditPropertyView(isPresented: $showingCreateProperty)
            }
        }
    }
    
    private var compactHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingMessage)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Farm Overview")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Weather widget
                CompactWeatherWidget()
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .responsiveCornerRadius(12)
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.headline)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                CompactStatCard(
                    title: "Active Farms",
                    value: "\(farmProperties.count)",
                    icon: "leaf.fill",
                    color: .green
                )
                
                CompactStatCard(
                    title: "Workers",
                    value: "\(activeWorkersCount)",
                    icon: "person.2.fill",
                    color: .blue
                )
                
                CompactStatCard(
                    title: "Equipment",
                    value: "\(infrastructure.count)",
                    icon: "wrench.fill",
                    color: .orange
                )
                
                CompactStatCard(
                    title: "Clocked In",
                    value: "\(clockedInCount)",
                    icon: "clock.fill",
                    color: .purple
                )
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink("See All") {
                    ActivityLogView()
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 4)
            
            LazyVStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    RecentActivityRow(
                        icon: "clock",
                        title: "Worker clocked in",
                        subtitle: "John Doe started work",
                        time: "2 hours ago",
                        color: .blue
                    )
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .responsiveCornerRadius(12)
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                CompactActionButton(
                    title: "Clock In/Out",
                    icon: "clock",
                    color: .blue
                ) {
                    // Handle clock action
                }
                
                CompactActionButton(
                    title: "New Work Order",
                    icon: "doc.badge.plus",
                    color: .orange
                ) {
                    // Handle work order
                }
                
                CompactActionButton(
                    title: "Record Harvest",
                    icon: "basket",
                    color: .green
                ) {
                    // Handle harvest
                }
                
                CompactActionButton(
                    title: "Equipment Check",
                    icon: "wrench",
                    color: .purple
                ) {
                    // Handle equipment
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Good Evening"
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
}

// MARK: - Compact Components

/// Compact weather widget for iPhone
struct CompactWeatherWidget: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "cloud.sun.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text("72°F")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            Text("Partly Cloudy")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.tertiarySystemGroupedBackground))
        .responsiveCornerRadius(6)
    }
}

/// Compact stat card for iPhone dashboard
struct CompactStatCard: View {
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
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(height: 80)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .responsiveCornerRadius(8)
    }
}

/// Recent activity row for iPhone
struct RecentActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
                .frame(width: 20, height: 20)
                .background(color.opacity(0.1))
                .responsiveCornerRadius(4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

/// Compact action button for iPhone
struct CompactActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .responsiveCornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - More View for iPhone

/// More view for additional navigation options on iPhone
struct MoreView: View {
    var body: some View {
        List {
            Section("Management") {
                NavigationLink(destination: Text("Analytics")) {
                    Label("Analytics", systemImage: "chart.bar")
                }
                
                NavigationLink(destination: Text("Reports")) {
                    Label("Reports", systemImage: "doc.text")
                }
                
                NavigationLink(destination: Text("Settings")) {
                    Label("Settings", systemImage: "gear")
                }
            }
            
            Section("Safety & Compliance") {
                NavigationLink(destination: Text("Safety Training")) {
                    Label("Safety Training", systemImage: "checkmark.shield")
                }
                
                NavigationLink(destination: Text("Inspections")) {
                    Label("Inspections", systemImage: "list.clipboard")
                }
                
                NavigationLink(destination: Text("Certifications")) {
                    Label("Certifications", systemImage: "rosette")
                }
            }
            
            Section("Tools") {
                NavigationLink(destination: Text("Soil Testing")) {
                    Label("Soil Testing", systemImage: "drop")
                }
                
                NavigationLink(destination: Text("Weather")) {
                    Label("Weather", systemImage: "cloud.sun")
                }
                
                NavigationLink(destination: Text("Calendar")) {
                    Label("Calendar", systemImage: "calendar")
                }
            }
        }
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.large)
    }
}

/// Activity log view
struct ActivityLogView: View {
    var body: some View {
        Text("Activity Log")
            .navigationTitle("Recent Activity")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview("iPhone") {
    AdaptiveDashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .previewDevice("iPhone 15 Pro")
}

#Preview("iPad") {
    AdaptiveDashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
        .previewInterfaceOrientation(.landscapeLeft)
}