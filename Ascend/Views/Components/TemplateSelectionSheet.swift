import SwiftUI

struct TemplateSelectionSheet: View {
    let templates: [WorkoutTemplate]
    let skillName: String
    let onSelect: (WorkoutTemplate) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if templates.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Text("No Templates")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Create a template first to add this skill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.mutedForeground)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(templates) { template in
                        Button(action: {
                            HapticManager.selection()
                            onSelect(template)
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Text("\(template.exercises.count) exercises")
                                        .font(.system(size: 13))
                                        .foregroundColor(AppColors.mutedForeground)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppColors.primary)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Add to Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

#Preview {
    TemplateSelectionSheet(
        templates: [],
        skillName: "Pull-up",
        onSelect: { _ in }
    )
}

