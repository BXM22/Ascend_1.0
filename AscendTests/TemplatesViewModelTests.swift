import XCTest
@testable import Ascend

final class TemplatesViewModelTests: XCTestCase {
    var viewModel: TemplatesViewModel!
    var workoutViewModel: WorkoutViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = TemplatesViewModel()
        workoutViewModel = WorkoutViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        workoutViewModel = nil
        super.tearDown()
    }
    
    // MARK: - Template Management Tests
    
    func testLoadSampleTemplates() {
        // Given/When
        // Templates are loaded in init
        
        // Then
        XCTAssertGreaterThan(viewModel.templates.count, 0)
        XCTAssertTrue(viewModel.templates.contains { $0.name == "Push Day" })
        XCTAssertTrue(viewModel.templates.contains { $0.name == "Pull Day" })
        XCTAssertTrue(viewModel.templates.contains { $0.name == "Leg Day" })
    }
    
    func testCreateTemplate() {
        // Given
        let initialCount = viewModel.templates.count
        
        // When
        viewModel.createTemplate()
        
        // Then
        XCTAssertTrue(viewModel.showCreateTemplate)
        XCTAssertNil(viewModel.editingTemplate)
    }
    
    func testEditTemplate() {
        // Given
        let template = viewModel.templates.first!
        
        // When
        viewModel.editTemplate(template)
        
        // Then
        XCTAssertTrue(viewModel.showEditTemplate)
        XCTAssertEqual(viewModel.editingTemplate?.id, template.id)
    }
    
    func testSaveTemplate_NewTemplate() {
        // Given
        let initialCount = viewModel.templates.count
        let newTemplate = WorkoutTemplate(
            name: "New Workout",
            exercises: ["Exercise 1", "Exercise 2"],
            estimatedDuration: 45
        )
        
        // When
        viewModel.saveTemplate(newTemplate)
        
        // Then
        XCTAssertEqual(viewModel.templates.count, initialCount + 1)
        XCTAssertTrue(viewModel.templates.contains { $0.id == newTemplate.id })
        XCTAssertFalse(viewModel.showCreateTemplate)
        XCTAssertNil(viewModel.editingTemplate)
    }
    
    func testSaveTemplate_UpdateExisting() {
        // Given
        let template = viewModel.templates.first!
        let updatedTemplate = WorkoutTemplate(
            id: template.id,
            name: "Updated Name",
            exercises: template.exercises,
            estimatedDuration: template.estimatedDuration
        )
        viewModel.editTemplate(template)
        
        // When
        viewModel.saveTemplate(updatedTemplate)
        
        // Then
        let savedTemplate = viewModel.templates.first { $0.id == template.id }
        XCTAssertNotNil(savedTemplate)
        XCTAssertEqual(savedTemplate?.name, "Updated Name")
        XCTAssertFalse(viewModel.showEditTemplate)
        XCTAssertNil(viewModel.editingTemplate)
    }
    
    func testDeleteTemplate() {
        // Given
        let template = viewModel.templates.first!
        let initialCount = viewModel.templates.count
        
        // When
        viewModel.deleteTemplate(template)
        
        // Then
        XCTAssertEqual(viewModel.templates.count, initialCount - 1)
        XCTAssertFalse(viewModel.templates.contains { $0.id == template.id })
    }
    
    func testStartTemplate() {
        // Given
        let template = viewModel.templates.first!
        XCTAssertNil(workoutViewModel.currentWorkout)
        
        // When
        viewModel.startTemplate(template, workoutViewModel: workoutViewModel)
        
        // Then
        XCTAssertNotNil(workoutViewModel.currentWorkout)
        XCTAssertEqual(workoutViewModel.currentWorkout?.name, template.name)
        XCTAssertEqual(workoutViewModel.currentWorkout?.exercises.count, template.exercises.count)
    }
    
    func testTemplateProperties() {
        // Given
        let template = viewModel.templates.first!
        
        // When/Then
        XCTAssertFalse(template.name.isEmpty)
        XCTAssertGreaterThan(template.exercises.count, 0)
        XCTAssertGreaterThan(template.estimatedDuration, 0)
    }
}













