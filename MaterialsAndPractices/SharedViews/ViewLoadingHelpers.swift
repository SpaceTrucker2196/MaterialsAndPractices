//
//  ViewLoadingHelpers.swift
//  MaterialsAndPractices
//
//  Helper utilities to ensure proper view loading and Core Data relationship handling
//  Addresses issues with views loading empty or not responding to Core Data updates
//

import SwiftUI
import CoreData

// MARK: - Core Data Relationship Prefetching

extension NSManagedObjectContext {
    /// Ensures relationships are prefetched to prevent view loading issues
    func prefetchRelationships<T: NSManagedObject>(for objects: [T], keyPaths: [String]) {
        for object in objects {
            for keyPath in keyPaths {
                _ = object.value(forKeyPath: keyPath)
            }
        }
    }
}

// MARK: - Field Data Loading Helper

struct FieldDataLoader {
    static func ensureFieldDataLoaded(_ field: Field, in context: NSManagedObjectContext) {
        // Ensure field is not a fault
        if field.isFault {
            context.refresh(field, mergeChanges: true)
        }
        
        // Force load critical properties
        _ = field.name
        _ = field.acres
        _ = field.hasDrainTile
        _ = field.slope
        _ = field.soilType
        _ = field.soilMapUnits
        _ = field.inspectionStatus
        _ = field.nextInspectionDue
        _ = field.notes
        
        // Force load relationships
        _ = field.property
        _ = field.grows
        _ = field.soilTests
        _ = field.wells
        
        // Force load nested relationships for grows
        if let grows = field.grows?.allObjects as? [Grow] {
            context.prefetchRelationships(for: grows, keyPaths: ["workOrders", "harvests", "cropAmendment"])
        }
    }
    
    static func prefetchFieldForNavigation(_ fieldID: UUID, in context: NSManagedObjectContext) -> Field? {
        let fetchRequest: NSFetchRequest<Field> = Field.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", fieldID as CVarArg)
        fetchRequest.relationshipKeyPathsForPrefetching = [
            "property",
            "grows",
            "soilTests", 
            "wells",
            "grows.workOrders",
            "grows.harvests",
            "grows.cropAmendment"
        ]
        
        do {
            let results = try context.fetch(fetchRequest)
            if let field = results.first {
                ensureFieldDataLoaded(field, in: context)
                return field
            }
        } catch {
            print("Error prefetching field: \(error)")
        }
        
        return nil
    }
}

// MARK: - Property Data Loading Helper

struct PropertyDataLoader {
    static func ensurePropertyDataLoaded(_ property: Property, in context: NSManagedObjectContext) {
        // Ensure property is not a fault
        if property.isFault {
            context.refresh(property, mergeChanges: true)
        }
        
        // Force load critical properties
        _ = property.displayName
        _ = property.totalAcres
        _ = property.tillableAcres
        _ = property.county
        _ = property.state
        _ = property.hasIrrigation
        
        // Force load relationships
        _ = property.fields
        _ = property.infrastructure
        _ = property.leases
        
        // Force load field relationships
        if let fields = property.fields?.allObjects as? [Field] {
            for field in fields.prefix(10) { // Limit to prevent performance issues
                FieldDataLoader.ensureFieldDataLoaded(field, in: context)
            }
        }
    }
}

// MARK: - View Loading State Manager

@MainActor
class ViewLoadingStateManager: ObservableObject {
    @Published var isLoading = false
    @Published var hasError = false
    @Published var errorMessage: String?
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    func setError(_ error: Error) {
        hasError = true
        errorMessage = error.localizedDescription
        isLoading = false
    }
    
    func clearError() {
        hasError = false
        errorMessage = nil
    }
    
    func reset() {
        isLoading = false
        hasError = false
        errorMessage = nil
    }
}

// MARK: - Enhanced View Modifiers

struct DataLoadingViewModifier: ViewModifier {
    let isLoading: Bool
    let hasError: Bool
    let errorMessage: String?
    let retryAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isLoading ? 0.5 : 1.0)
                .disabled(isLoading)
            
            if isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.2)
            }
            
            if hasError {
                VStack(spacing: AppTheme.Spacing.medium) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(AppTheme.Colors.error)
                    
                    Text("Data Loading Error")
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let retryAction = retryAction {
                        Button("Retry", action: retryAction)
                            .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(AppTheme.Colors.backgroundPrimary)
                .cornerRadius(AppTheme.CornerRadius.large)
                .shadow(radius: AppTheme.CornerRadius.medium)
            }
        }
    }
}

extension View {
    func dataLoadingState(
        isLoading: Bool,
        hasError: Bool = false,
        errorMessage: String? = nil,
        retryAction: (() -> Void)? = nil
    ) -> some View {
        modifier(DataLoadingViewModifier(
            isLoading: isLoading,
            hasError: hasError,
            errorMessage: errorMessage,
            retryAction: retryAction
        ))
    }
}

// MARK: - Core Data Context Extension for View Loading

extension NSManagedObjectContext {
    /// Performs a fetch request with relationship prefetching for better view loading
    func fetchWithPrefetching<T: NSManagedObject>(
        _ request: NSFetchRequest<T>,
        relationshipKeyPaths: [String] = []
    ) throws -> [T] {
        request.relationshipKeyPathsForPrefetching = relationshipKeyPaths
        return try fetch(request)
    }
    
    /// Ensures an object and its relationships are fully loaded
    func fullyLoad<T: NSManagedObject>(_ object: T, relationshipKeyPaths: [String] = []) {
        if object.isFault {
            refresh(object, mergeChanges: true)
        }
        
        for keyPath in relationshipKeyPaths {
            _ = object.value(forKeyPath: keyPath)
        }
    }
}