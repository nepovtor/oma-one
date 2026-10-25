import Foundation

// A single persisted record feeds the four local checks in the shelf journey.
// These values are user-entered. Product names and prices are demo catalog data.
enum ShelfSurface: String, Codable, CaseIterable {
    case unknown, concrete, drywall, wood

    var title: String {
        switch self {
        case .unknown: "Не знаю"
        case .concrete: "Бетон"
        case .drywall: "Гипсокартон"
        case .wood: "Дерево"
        }
    }
}

enum ShelfFastener: String, Codable, CaseIterable {
    case none, concreteAnchor, drywallAnchor, woodScrew

    var title: String {
        switch self {
        case .none: "Не выбран"
        case .concreteAnchor: "Дюбель для бетона · демо"
        case .drywallAnchor: "Анкер для гипсокартона · демо"
        case .woodScrew: "Крепёж для дерева · вне демо-каталога"
        }
    }

    var engineID: String {
        switch self {
        case .none: "unknown"
        case .concreteAnchor: "concrete-anchor"
        case .drywallAnchor: "drywall-anchor"
        case .woodScrew: "wood-screw"
        }
    }
}

enum ShelfReadiness: String {
    case incomplete, blocked, review, candidate
}

struct ShelfProjectData: Codable, Equatable, Identifiable {
    var id = UUID()
    var wall: ShelfSurface = .unknown
    var shelfWeightKg: Double = 0
    var plannedLoadKg: Double = 0
    var fastener: ShelfFastener = .none
    var utilitiesChecked = false
    var wallInspected = false
    var manufacturerInstructionsChecked = false
    var ownedQuantities: [String: Int] = [:]
    var completedStepIDs: [String] = []
    var photoPath: String? = nil
    var photoHash: String? = nil
    var updatedAt = Date()

    static let steps: [(id: String, title: String, after: [String])] = [
        ("inspect", "Осмотреть стену и её состояние", []),
        ("utilities", "Проверить скрытые коммуникации", ["inspect"]),
        ("load", "Уточнить вес и допустимую нагрузку", ["inspect"]),
        ("fastener", "Сверить крепёж с инструкцией", ["utilities", "load"]),
        ("mount", "Выполнить монтаж", ["fastener"]),
        ("final", "Проверить результат", ["mount"])
    ]

    var totalLoadKg: Double { shelfWeightKg + plannedLoadKg }
    var allStepsDone: Bool { Self.steps.allSatisfy { completedStepIDs.contains($0.id) } }
    var hasProofPhoto: Bool { photoPath != nil && photoHash != nil }

    func engineInput(products: [[String: Any]]) -> [String: Any] {
        let inventory = ownedQuantities.filter { $0.value > 0 }
            .map { ["id": $0.key, "qty": $0.value] as [String: Any] }
        return ["projectId": id.uuidString,
                "surface": wall.rawValue,
                "fastener": fastener.engineID,
                "shelfWeightKg": shelfWeightKg,
                "plannedLoadKg": plannedLoadKg,
                "wallInspected": wallInspected,
                "verifiedWiring": utilitiesChecked,
                "manufacturerInstructionsChecked": manufacturerInstructionsChecked,
                "products": products,
                "inventory": inventory,
                "completedStepIds": completedStepIDs,
                "photoHashes": hasProofPhoto ? [photoHash!] : []]
    }

    var proofInput: [String: Any] {
        let checklist = Self.steps.map {
            ["code": $0.id, "done": completedStepIDs.contains($0.id)] as [String: Any]
        }
        return ["projectId": id.uuidString,
                "steps": checklist,
                "photoHashes": hasProofPhoto ? [photoHash!] : [],
                "ownerConsent": false]
    }
}
