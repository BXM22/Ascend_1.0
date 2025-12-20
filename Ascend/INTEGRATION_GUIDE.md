# Templates View Redesign - Integration Guide

## Quick Start

### To Use the Redesigned Templates View

**Option 1: Direct Replacement** (Recommended for full redesign)
```swift
// In your ContentView or main tab view:
TemplatesView_Redesigned(
    viewModel: templatesViewModel,
    workoutViewModel: workoutViewModel,
    programViewModel: programViewModel,
    onStartTemplate: {
        selectedTab = .workout
    },
    onSettings: {
        showSettings = true
    }
)
```

**Option 2: Rename and Replace**
1. Open `TemplatesView_Redesigned.swift`
2. Find: `struct TemplatesView_Redesigned:`
3. Replace with: `struct TemplatesView:`
4. Rename the file to `TemplatesView.swift` (overwriting the old one)
5. Move old `TemplatesView.swift` to `TemplatesView_Legacy.swift` as backup

---

## What's Included

### New Files
1. **TemplateDetailView.swift** - Preview sheet for templates
2. **TemplateFilterSheet.swift** - Advanced filtering interface
3. **TemplatesView_Redesigned.swift** - Complete redesigned main view
4. **TEMPLATES_REDESIGN.md** - Full documentation (this file's sibling)

### Key Features
- ✅ Swipe to delete (trailing) and duplicate (leading)
- ✅ Tap card to preview in medium detent sheet
- ✅ Segmented control: Programs | Skills | Templates
- ✅ Advanced filtering (intensity, duration, muscle groups, type)
- ✅ Multi-select mode for bulk delete
- ✅ Grouped view option (by muscle group)
- ✅ Enhanced empty states with CTAs
- ✅ Floating add button
- ✅ Streamlined header (consolidated settings)
- ✅ Improved accessibility labels

---

## Migration Steps

### Step 1: Backup Current Implementation
```bash
cd /Users/brennenmeregillano/Desktop/Ascend/Ascend/Views
cp TemplatesView.swift TemplatesView_Backup_$(date +%Y%m%d).swift
```

### Step 2: Test New Components Independently
```swift
// Test TemplateDetailView
struct TestDetailView: View {
    var body: some View {
        TemplateDetailView(
            template: sampleTemplate,
            onStart: { print("Start") },
            onEdit: { print("Edit") },
            onDuplicate: { print("Duplicate") },
            onDelete: { print("Delete") }
        )
    }
}

// Test TemplateFilterSheet
struct TestFilterView: View {
    @State private var filters = TemplateFilters()
    
    var body: some View {
        Button("Show Filters") {
            showFilterSheet = true
        }
        .sheet(isPresented: $showFilterSheet) {
            TemplateFilterSheet(filters: $filters)
        }
    }
}
```

### Step 3: Switch to Redesigned View
In your main `ContentView.swift` or wherever `TemplatesView` is used:

```swift
// OLD:
TemplatesView(
    viewModel: templatesViewModel,
    workoutViewModel: workoutViewModel,
    programViewModel: programViewModel,
    onStartTemplate: { selectedTab = .workout },
    onSettings: { showSettings = true }
)

// NEW:
TemplatesView_Redesigned(
    viewModel: templatesViewModel,
    workoutViewModel: workoutViewModel,
    programViewModel: programViewModel,
    onStartTemplate: { selectedTab = .workout },
    onSettings: { showSettings = true }
)
```

### Step 4: Test All Features
Use the testing checklist in `TEMPLATES_REDESIGN.md` under "Testing Checklist"

### Step 5: Monitor Performance
```swift
// Add to TemplatesView_Redesigned if needed:
.task {
    print("Templates loaded: \(filteredTemplates.count)")
    print("Filter active: \(filters.isActive)")
}
```

---

## Troubleshooting

### Issue: Swipe actions not working
**Solution:** Ensure you're using iOS 15+ and swipeActions are applied to the correct view:
```swift
RedesignedTemplateCard(...)
    .swipeActions(edge: .trailing) { ... }
    .swipeActions(edge: .leading) { ... }
    .padding(.horizontal, AppSpacing.lg)  // Must be AFTER swipeActions
```

### Issue: Detail sheet not presenting
**Solution:** Check that `selectedTemplate` is properly set:
```swift
.sheet(isPresented: $showDetailSheet) {
    if let template = selectedTemplate {  // Must unwrap optional
        TemplateDetailView(...)
    }
}
```

### Issue: Filter not applying
**Solution:** Verify `TemplateFilters.matches()` logic matches your data:
```swift
// Check console:
print("Filter active: \(filters.isActive)")
print("Templates before filter: \(viewModel.templates.count)")
print("Templates after filter: \(filteredTemplates.count)")
```

### Issue: Segmented control not switching
**Solution:** Ensure animations are enabled and state is properly bound:
```swift
Picker("Content", selection: $selectedSegment) { ... }
    .pickerStyle(SegmentedPickerStyle())
// Check:
.animation(.easeInOut(duration: 0.3), value: selectedSegment)
```

### Issue: Multi-select mode stuck
**Solution:** Add debug button to reset state:
```swift
#if DEBUG
Button("Reset Multi-Select") {
    isMultiSelectMode = false
    selectedTemplates.removeAll()
}
#endif
```

---

## Customization

### Change Swipe Action Colors
```swift
// In RedesignedTemplateCard swipeActions:
.swipeActions(edge: .leading) {
    Button { ... } label: { ... }
        .tint(.blue)  // Change from AppColors.accent
}
```

### Adjust Segment Order
```swift
enum ContentSegment: String, CaseIterable {
    case templates = "Templates"  // Show templates first
    case programs = "Programs"
    case skills = "Skills"
}
```

### Modify Empty State Messages
```swift
// In EnhancedEmptyState:
Text(hasSearchText ? 
     "Custom message for no results" :
     "Custom message for empty state")
```

### Change Filter Categories
```swift
// In TemplateFilterSheet, add new muscle group:
ForEach(["Chest", "Back", "Legs", "Arms", "Core", "Cardio", "Shoulders"], id: \.self) { group in
    FilterToggle(...)
}
```

---

## Performance Tips

### For Large Template Lists (100+)
```swift
// Already implemented in redesign:
// 1. LazyVStack for lazy loading ✅
// 2. Debounced search (300ms) ✅
// 3. Conditional rendering based on segment ✅

// Optional: Add virtualization limit
private var displayedTemplates: [WorkoutTemplate] {
    Array(filteredTemplates.prefix(50))  // Show first 50
}
```

### Optimize Search
```swift
// Move filtering to background queue:
private func filterTemplatesAsync() async {
    let searchText = debouncedSearchText
    let templates = viewModel.templates
    
    let filtered = await Task.detached {
        templates.filter { template in
            // Filtering logic
        }
    }.value
    
    await MainActor.run {
        self.filteredTemplatesCache = filtered
    }
}
```

---

## Accessibility Enhancements

### Enable Dynamic Type (Future)
```swift
Text(template.name)
    .font(AppTypography.heading3)
    .dynamicTypeSize(...<= .xxxLarge)  // Clamp max size
```

### Add Reduce Motion Support (Future)
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

.animation(
    reduceMotion ? nil : .easeInOut(duration: 0.3),
    value: selectedSegment
)
```

### Custom VoiceOver Rotor (Future)
```swift
.accessibilityRotor("Templates") {
    ForEach(filteredTemplates) { template in
        AccessibilityRotorEntry(template.name, id: template.id) {
            // Navigate to template
        }
    }
}
```

---

## FAQ

**Q: Can I use parts of the redesign without the full thing?**
A: Yes! The components are modular:
- Use `TemplateDetailView` alone for previews
- Use `TemplateFilterSheet` alone for filtering
- Add swipe actions to existing cards
- Use `EnhancedEmptyState` in current view

**Q: Will this break existing workout data?**
A: No. The redesign only changes UI/UX, not data models. All `WorkoutTemplate` data is preserved.

**Q: How do I revert if something breaks?**
A: Simply switch back to `TemplatesView` (or rename your backup file back).

**Q: Does this work on iPad?**
A: Yes, but may need layout tweaks for larger screens. Consider adding:
```swift
.frame(maxWidth: 600)  // Limit width on iPad
.padding(.horizontal, isIPad ? 40 : 0)
```

**Q: Can users customize swipe actions?**
A: Not in current implementation. To add:
```swift
// In SettingsManager:
@Published var swipeToDeleteEnabled = true
@Published var swipeLeadingAction: SwipeAction = .duplicate

// Then conditionally show swipeActions
```

---

## Support

For issues or questions:
1. Check `TEMPLATES_REDESIGN.md` for detailed documentation
2. Review testing checklist for common issues
3. Check console logs for debug output
4. Compare with `TemplatesView_Legacy.swift` if available

---

## Next Steps

After successful integration:
1. Gather user feedback
2. Monitor crash reports
3. Track performance metrics
4. Implement Phase 2 features:
   - Dynamic Type support
   - Reduce Motion support
   - Template tags/favorites
   - Drag-to-reorder
   - Template sharing

Good luck with the redesign! 🎉
