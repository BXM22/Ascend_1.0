import XCTest
@testable import Ascend

final class JSONExerciseImporterTests: XCTestCase {
    
    func testDecodeSampleJSON() throws {
        // Given a minimal JSON snippet from the bundled structure
        let json = """
        {
          "push": {
            "chest": [
              {
                "name": "Barbell Bench Press",
                "equipment": "barbell",
                "type": "compound",
                "primary_muscles": ["chest", "triceps", "front_delts"]
              }
            ]
          },
          "pull": {},
          "legs": {},
          "cardio": [
            {
              "name": "Walking",
              "equipment": "bodyweight",
              "type": "endurance",
              "primary_muscles": ["legs"]
            }
          ],
          "stretches": [
            {
              "name": "Chest Opener",
              "equipment": "bodyweight",
              "type": "static",
              "muscles_stretched": ["chest", "front_delts"]
            }
          ]
        }
        """
        
        let data = Data(json.utf8)
        
        // When
        let exercises = try JSONExerciseImporter.shared.decode(from: data)
        
        // Then
        XCTAssertGreaterThanOrEqual(exercises.count, 3, "Expected at least 3 exercises from sample JSON")
        
        let names = exercises.map { $0.name }
        XCTAssertTrue(names.contains("Barbell Bench Press"))
        XCTAssertTrue(names.contains("Walking"))
        XCTAssertTrue(names.contains("Chest Opener"))
        
        // Validate some mappings
        let bench = exercises.first { $0.name == "Barbell Bench Press" }
        XCTAssertEqual(bench?.category, "Chest")
        XCTAssertEqual(bench?.muscleGroup, "Chest")
        XCTAssertEqual(bench?.equipment, "Barbell")
        
        let walking = exercises.first { $0.name == "Walking" }
        XCTAssertEqual(walking?.category, "Cardio")
        
        let stretch = exercises.first { $0.name == "Chest Opener" }
        XCTAssertEqual(stretch?.category, "Stretching")
    }
}




