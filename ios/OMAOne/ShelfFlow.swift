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

    var productID: String? {
        switch self {
        case .concreteAnchor: "p08"
        case .drywallAnchor: "p09"
        case .none, .woodScrew: nil
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

    func readiness(antiFailStatus: String?) -> ShelfReadiness {
        guard wall != .unknown, shelfWeightKg > 0, plannedLoadKg > 0, fastener != .none else { return .incomplete }
        if antiFailStatus == "BLOCKED" { return .blocked }
        guard utilitiesChecked, wallInspected, manufacturerInstructionsChecked,
              totalLoadKg <= 15, antiFailStatus == "PRELIMINARY_PASS",
              fastener.productID != nil else { return .review }
        return .candidate
    }

    func candidateProductIDs(antiFailStatus: String?) -> [String] {
        // Never assemble a shopping kit while the fastening decision is unresolved.
        guard readiness(antiFailStatus: antiFailStatus) == .candidate,
              let fastenerID = fastener.productID else { return [] }
        return ["p07", fastenerID, "p25"]
    }

    var antiFailInput: [String: Any] {
        ["surface": wall.rawValue,
         "fastener": fastener.engineID,
         "loadKg": totalLoadKg,
         "verifiedWiring": utilitiesChecked]
    }

    var dominoInput: [String: Any] {
        let ids = Self.steps.map { $0.id }
        let done = completedStepIDs.filter { ids.contains($0) }
        let order = done + ids.filter { !done.contains($0) }
        let steps = Self.steps.map { ["id": $0.id, "after": $0.after] as [String: Any] }
        return ["order": order, "steps": steps]
    }

    var proofInput: [String: Any] {
        let checklist = Self.steps.map { ["code": $0.id, "done": completedStepIDs.contains($0.id)] as [String: Any] }
        return ["projectId": id.uuidString,
                "steps": checklist,
                "photoHashes": photoHash.map { [$0] } ?? [],
                "ownerConsent": false]
    }
}
