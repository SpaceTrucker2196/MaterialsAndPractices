//
//  DemoPreview.swift
//  MaterialsAndPractices
//
//  Demo preview to showcase the iPad Pro dashboard implementation
//  Shows the adaptive design switching between iPhone and iPad layouts
//

import SwiftUI

struct DemoPreview: View {
    var body: some View {
        VStack {
            Text("Materials & Practices")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Text("iPad Pro Dashboard Implementation")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Demo of responsive design
            HStack(spacing: 40) {
                // iPhone Layout Preview
                VStack {
                    Text("iPhone Experience")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    RoundedRectangle(cornerRadius: 25)
                        .frame(width: 180, height: 320)
                        .foregroundColor(.black)
                        .overlay(
                            VStack {
                                // Status bar
                                Rectangle()
                                    .frame(height: 30)
                                    .foregroundColor(.clear)
                                
                                // Content area with tabs
                                VStack(spacing: 20) {
                                    Text("Dashboard")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                    
                                    // Compact cards
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                        ForEach(0..<4, id: \.self) { _ in
                                            RoundedRectangle(cornerRadius: 4)
                                                .frame(height: 40)
                                                .foregroundColor(.blue.opacity(0.3))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                                
                                Spacer()
                                
                                // Tab bar
                                HStack {
                                    ForEach(0..<5, id: \.self) { _ in
                                        Circle()
                                            .frame(width: 6, height: 6)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                                .padding(.bottom, 20)
                            }
                        )
                }
                
                // iPad Layout Preview
                VStack {
                    Text("iPad Pro Experience")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    RoundedRectangle(cornerRadius: 15)
                        .frame(width: 320, height: 240)
                        .foregroundColor(.black)
                        .overlay(
                            HStack(spacing: 0) {
                                // Sidebar
                                VStack(alignment: .leading) {
                                    Text("Dashboard")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                        .padding(.top, 16)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(0..<4, id: \.self) { _ in
                                            RoundedRectangle(cornerRadius: 2)
                                                .frame(width: 60, height: 4)
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                    }
                                    .padding(.top, 8)
                                    
                                    Spacer()
                                }
                                .frame(width: 80)
                                .background(Color.black.opacity(0.3))
                                
                                // Main content area
                                VStack {
                                    // Header
                                    HStack {
                                        Text("Farm Operations")
                                            .foregroundColor(.white)
                                            .font(.caption)
                                        Spacer()
                                    }
                                    .padding(.top, 16)
                                    .padding(.horizontal, 16)
                                    
                                    // Dashboard tiles
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                        ForEach(0..<6, id: \.self) { index in
                                            RoundedRectangle(cornerRadius: 6)
                                                .frame(height: 50)
                                                .foregroundColor(
                                                    [Color.green, .blue, .orange, .purple, .indigo, .red][index].opacity(0.3)
                                                )
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    
                                    Spacer()
                                }
                            }
                        )
                }
            }
            
            Spacer()
            
            // Features list
            VStack(alignment: .leading, spacing: 8) {
                Text("✅ Clean Architecture Implementation")
                Text("✅ iPad Pro Dashboard with Sidebar Navigation")
                Text("✅ Adaptive Layouts for iPhone and iPad")
                Text("✅ Device Detection & Responsive Design")
                Text("✅ Apple Best Practices Implementation")
            }
            .font(.subheadline)
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview {
    DemoPreview()
}