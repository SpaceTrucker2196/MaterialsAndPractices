//
//  InspectionCreationSupportingViews.swift
//  MaterialsAndPractices
//
//  Supporting UI components for the inspection creation workflow.
//  Provides reusable cards, selection rows, and specialized views
//  for each step of the inspection creation process.
//
//  Created by GitHub Copilot on 12/19/24.
//

import SwiftUI

// MARK: - Step Header

/// Header component for workflow steps
struct StepHeader: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(title)
                .font(AppTheme.Typography.displaySmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(description)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Template Selection

/// Card for selecting working templates
struct WorkingTemplateSelectionCard: View {
    let template: WorkingTemplateData
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Selection indicator
                Circle()
                    .fill(isSelected ? AppTheme.Colors.primary : Color.clear)
                    .stroke(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(AppTheme.Colors.primary)
                            .frame(width: 10, height: 10)
                            .opacity(isSelected ? 1 : 0)
                    )
                
                // Template info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(template.name)
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(template.description)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Label("\(template.itemCount) items", systemImage: "list.bullet")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        
                        Spacer()
                        
                        Text(template.category.displayName)
                            .font(AppTheme.Typography.labelTiny)
                            .foregroundColor(AppTheme.Colors.primary)
                            .padding(.horizontal, AppTheme.Spacing.small)
                            .padding(.vertical, 2)
                            .background(AppTheme.Colors.primary.opacity(0.1))
                            .cornerRadius(AppTheme.CornerRadius.tiny)
                    }
                }
            }
            .padding()
            .background(isSelected ? AppTheme.Colors.primary.opacity(0.1) : AppTheme.Colors.backgroundPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Empty state for working templates
struct EmptyWorkingTemplatesView: View {
    let onCreateTemplate: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text("No Working Templates")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Create a working template from the inspection catalog to get started")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Browse Catalog") {
                onCreateTemplate()
            }
            .font(AppTheme.Typography.bodyMedium)
            .foregroundColor(.white)
            .padding()
            .background(AppTheme.Colors.primary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Time Selection

/// Card for selecting inspection time
struct TimeSelectionCard: View {
    let time: InspectionTime
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: timeIcon(for: time))
                    .font(.title)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.primary)
                
                VStack(spacing: AppTheme.Spacing.tiny) {
                    Text(time.rawValue)
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
                    
                    Text(time.timeRange)
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : AppTheme.Colors.textSecondary)
                }
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.backgroundPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary, lineWidth: 1)
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func timeIcon(for time: InspectionTime) -> String {
        switch time {
        case .morning: return "sunrise.fill"
        case .evening: return "sun.max.fill"
        case .night: return "moon.fill"
        }
    }
}

/// Chip for selecting inspection frequency
struct FrequencySelectionChip: View {
    let frequency: InspectionFrequency
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.tiny) {
                Image(systemName: frequency.icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.primary)
                
                Text(frequency.rawValue)
                    .font(AppTheme.Typography.labelSmall)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
            }
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.tiny)
            .background(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Selection

/// Card for selecting inspection category
struct CategorySelectionCard: View {
    let category: InspectionCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: category.icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.primary)
                
                Text(category.displayName)
                    .font(AppTheme.Typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.backgroundPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary, lineWidth: 1)
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Entity Selection

/// Card for selecting farm entities
struct EntitySelectionCard: View {
    let entity: EntitySelectionData
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Selection indicator
                Circle()
                    .fill(isSelected ? AppTheme.Colors.primary : Color.clear)
                    .stroke(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(AppTheme.Colors.primary)
                            .frame(width: 10, height: 10)
                            .opacity(isSelected ? 1 : 0)
                    )
                
                // Entity icon
                Image(systemName: entityIcon(for: entity.entityType))
                    .font(.title2)
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .cornerRadius(AppTheme.CornerRadius.small)
                
                // Entity info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(entity.name)
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("\(entity.entityType) • \(entity.farmName)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding()
            .background(isSelected ? AppTheme.Colors.primary.opacity(0.1) : AppTheme.Colors.backgroundPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func entityIcon(for entityType: String) -> String {
        switch entityType {
        case "Grow": return "leaf.fill"
        case "Infrastructure": return "building.2.fill"
        case "Field": return "map.fill"
        case "Farm": return "house.fill"
        default: return "questionmark.circle.fill"
        }
    }
}

/// Empty state for entities
struct EmptyEntityStateView: View {
    let category: InspectionCategory
    let onCreateEntity: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: category.icon)
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text("No \(category.displayName) Available")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Create a \(category.displayName.lowercased()) to perform inspections on")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Create \(category.displayName)") {
                onCreateEntity()
            }
            .font(AppTheme.Typography.bodyMedium)
            .foregroundColor(.white)
            .padding()
            .background(AppTheme.Colors.primary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Inspector Selection

/// Row for selecting individual inspectors
struct InspectorSelectionRow: View {
    let inspector: InspectorData
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Selection checkbox
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary)
                
                // Inspector info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(inspector.name)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !inspector.certifications.isEmpty {
                        Text(inspector.certifications.joined(separator: ", "))
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // Inspector capability indicator
                if inspector.canInspect {
                    Image(systemName: "eye.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.compliance)
                }
            }
            .padding()
            .background(isSelected ? AppTheme.Colors.primary.opacity(0.1) : AppTheme.Colors.backgroundPrimary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Row for selecting work teams
struct TeamSelectionRow: View {
    let team: WorkTeamData
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Selection indicator
                Circle()
                    .fill(isSelected ? AppTheme.Colors.primary : Color.clear)
                    .stroke(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(AppTheme.Colors.primary)
                            .frame(width: 10, height: 10)
                            .opacity(isSelected ? 1 : 0)
                    )
                
                // Team icon
                Image(systemName: "person.3.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.Colors.secondary)
                
                // Team info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(team.name)
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("\(team.qualifiedMembers.count) qualified inspectors")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Team inspector indicators
                HStack(spacing: 2) {
                    ForEach(0..<min(team.qualifiedMembers.count, 3), id: \.self) { _ in
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                            .foregroundColor(AppTheme.Colors.compliance)
                    }
                    if team.qualifiedMembers.count > 3 {
                        Text("+\(team.qualifiedMembers.count - 3)")
                            .font(AppTheme.Typography.labelTiny)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
            }
            .padding()
            .background(isSelected ? AppTheme.Colors.primary.opacity(0.1) : AppTheme.Colors.backgroundPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Review Section

/// Section component for the review step
struct ReviewSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(title)
                .font(AppTheme.Typography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            content()
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}