import SwiftUI

// MARK: - Swipe Actions Modifier
/// Adds horizontal swipe actions to a view (similar to List swipe actions but for custom views)
struct SwipeActionsModifier: ViewModifier {
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    @GestureState private var dragOffset: CGFloat = 0
    
    let leadingActions: [SwipeAction]
    let trailingActions: [SwipeAction]
    let threshold: CGFloat = 60
    
    struct SwipeAction: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let color: Color
        let action: () -> Void
        var isDestructive: Bool = false
    }
    
    func body(content: Content) -> some View {
        ZStack {
            // Background actions
            HStack(spacing: 0) {
                // Leading actions (shown when swiping right)
                if !leadingActions.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(leadingActions) { action in
                            actionButton(for: action)
                        }
                    }
                    .padding(.leading, 8)
                    .frame(maxWidth: max(0, offset), alignment: .leading)
                    .opacity(offset > 0 ? 1 : 0)
                }
                
                Spacer()
                
                // Trailing actions (shown when swiping left)
                if !trailingActions.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(trailingActions) { action in
                            actionButton(for: action)
                        }
                    }
                    .padding(.trailing, 8)
                    .frame(maxWidth: max(0, -offset), alignment: .trailing)
                    .opacity(offset < 0 ? 1 : 0)
                }
            }
            
            // Main content
            content
                .offset(x: offset + dragOffset)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .updating($dragOffset) { value, state, _ in
                            // Only allow horizontal swipes
                            if abs(value.translation.width) > abs(value.translation.height) {
                                let dragAmount = value.translation.width
                                
                                // Limit drag based on available actions
                                if dragAmount > 0 && leadingActions.isEmpty {
                                    state = 0
                                } else if dragAmount < 0 && trailingActions.isEmpty {
                                    state = 0
                                } else {
                                    // Apply resistance at edges
                                    let resistance = isSwiped ? 1.0 : 0.7
                                    state = dragAmount * resistance
                                }
                            }
                        }
                        .onEnded { value in
                            handleDragEnd(value)
                        }
                )
                .animation(AppAnimations.smooth, value: offset)
        }
        .clipped()
    }
    
    private func actionButton(for action: SwipeAction) -> some View {
        Button {
            // Reset swipe state and perform action
            withAnimation(AppAnimations.smooth) {
                offset = 0
                isSwiped = false
            }
            // Delay action slightly for visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                action.action()
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: action.icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(action.title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(width: 56, height: 56)
            .background(action.color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(action.title)
    }
    
    private func handleDragEnd(_ value: DragGesture.Value) {
        let dragAmount = value.translation.width
        let velocity = value.predictedEndLocation.x - value.location.x
        
        // Determine if we should snap to open or closed
        if dragAmount > 0 && !leadingActions.isEmpty {
            // Swiping right
            if dragAmount > threshold || velocity > 100 {
                offset = threshold
                isSwiped = true
            } else {
                offset = 0
                isSwiped = false
            }
        } else if dragAmount < 0 && !trailingActions.isEmpty {
            // Swiping left
            if dragAmount < -threshold || velocity < -100 {
                offset = -threshold
                isSwiped = true
            } else {
                offset = 0
                isSwiped = false
            }
        } else {
            offset = 0
            isSwiped = false
        }
    }
}

extension View {
    /// Adds swipe actions to a view
    func swipeActions(
        leading: [SwipeActionsModifier.SwipeAction] = [],
        trailing: [SwipeActionsModifier.SwipeAction] = []
    ) -> some View {
        modifier(SwipeActionsModifier(leadingActions: leading, trailingActions: trailing))
    }
    
    /// Convenience method for adding just a delete swipe action
    func swipeToDelete(
        showConfirmation: Binding<Bool>? = nil,
        onDelete: @escaping () -> Void
    ) -> some View {
        swipeActions(
            trailing: [
                SwipeActionsModifier.SwipeAction(
                    icon: "trash.fill",
                    title: "Delete",
                    color: AppColors.destructive,
                    action: {
                        if let showConfirmation = showConfirmation {
                            showConfirmation.wrappedValue = true
                        } else {
                            onDelete()
                        }
                    },
                    isDestructive: true
                )
            ]
        )
    }
}

// MARK: - Exercise Card Swipe Actions Helper
/// Provides standard swipe actions for exercise cards
struct ExerciseCardSwipeActions {
    static func deleteAction(
        exerciseName: String,
        hasSets: Bool,
        onConfirmNeeded: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> SwipeActionsModifier.SwipeAction {
        SwipeActionsModifier.SwipeAction(
            icon: "trash.fill",
            title: "Delete",
            color: AppColors.destructive,
            action: {
                HapticManager.impact(style: .medium)
                if hasSets {
                    onConfirmNeeded()
                } else {
                    onDelete()
                }
            },
            isDestructive: true
        )
    }
    
    static func moveAction(
        direction: MoveDirection,
        onMove: @escaping () -> Void
    ) -> SwipeActionsModifier.SwipeAction {
        SwipeActionsModifier.SwipeAction(
            icon: direction == .earlier ? "arrow.left" : "arrow.right",
            title: direction == .earlier ? "Earlier" : "Later",
            color: AppColors.primary,
            action: {
                HapticManager.impact(style: .light)
                onMove()
            }
        )
    }
    
    enum MoveDirection {
        case earlier, later
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("Swipe me left!")
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .swipeToDelete {
                print("Deleted!")
            }
        
        Text("Swipe me either way!")
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .swipeActions(
                leading: [
                    SwipeActionsModifier.SwipeAction(
                        icon: "star.fill",
                        title: "Favorite",
                        color: .yellow,
                        action: { print("Favorited!") }
                    )
                ],
                trailing: [
                    SwipeActionsModifier.SwipeAction(
                        icon: "trash.fill",
                        title: "Delete",
                        color: .red,
                        action: { print("Deleted!") },
                        isDestructive: true
                    )
                ]
            )
    }
    .padding()
    .background(AppColors.background)
}
