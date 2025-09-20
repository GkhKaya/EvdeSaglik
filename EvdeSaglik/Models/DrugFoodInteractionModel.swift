import Foundation

struct DrugFoodInteractionModel: Codable, Identifiable {
    let id: String
    let userId: String
    let drugName: String
    let foodName: String
    let interactionResult: String
    let timestamp: Date
    let userSummary: String

    init(id: String = UUID().uuidString, userId: String, drugName: String, foodName: String, interactionResult: String, userSummary: String) {
        self.id = id
        self.userId = userId
        self.drugName = drugName
        self.foodName = foodName
        self.interactionResult = interactionResult
        self.timestamp = Date()
        self.userSummary = userSummary
    }
}
