import Foundation

// Synthetic interpretation of the user-provided apartment plan. The stated areas come
// from the reference image; coordinates are an approximate viewing model, not an as-built survey.
enum TwinRoomKind: String, Codable, CaseIterable, Identifiable {
    case living, kitchen, bedroom, bathroom, toilet, hallway

    var id: String { rawValue }
    var title: String {
        switch self {
        case .living: return "Гостиная"
        case .kitchen: return "Кухня"
        case .bedroom: return "Спальня"
        case .bathroom: return "Ванная"
        case .toilet: return "Туалет"
        case .hallway: return "Коридор"
        }
    }
    var symbol: String {
        switch self {
        case .living: return "sofa"
        case .kitchen: return "fork.knife"
        case .bedroom: return "bed.double"
        case .bathroom: return "shower"
        case .toilet: return "toilet"
        case .hallway: return "door.left.hand.open"
        }
    }
}

enum TwinStage: String, Codable, CaseIterable, Hashable, Identifiable {
    case walls, floor, lights, furniture

    var id: String { rawValue }
    var title: String {
        switch self {
        case .walls: return "Стены и отделка"
        case .floor: return "Напольное покрытие"
        case .lights: return "Освещение"
        case .furniture: return "Мебель и оснащение"
        }
    }
    var symbol: String {
        switch self {
        case .walls: return "paintbrush.pointed"
        case .floor: return "square.grid.3x3"
        case .lights: return "lightbulb"
        case .furniture: return "chair.lounge"
        }
    }
}

enum TwinShelfEvidence: String {
    case none, planned, selfReported, photoSubmitted

    var isRecorded: Bool {
        self == .selfReported || self == .photoSubmitted
    }

    var caption: String {
        switch self {
        case .none: return "Проект полки пока не создан"
        case .planned: return "Полка запланирована, монтаж не подтверждён"
        case .selfReported: return "Полка: выполнение отмечено пользователем"
        case .photoSubmitted: return "Полка: фото сохранено, экспертом не проверено"
        }
    }
}

struct TwinRoom: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var planKey: String? = nil
    var kind: TwinRoomKind
    var name: String
    var width: Double = 4.0
    var depth: Double = 4.0
    var finishedStages: Set<TwinStage> = []
    var referencePhotoName: String? = nil

    var sizeLabel: String {
        let value = TwinPlan.space(for: self)?.declaredAreaM2 ?? width * depth
        return "\(value.formatted(.number.precision(.fractionLength(0...2)))) м²"
    }

    var dimensionsLabel: String {
        TwinPlan.space(for: self)?.displayDimensions ??
            "\(Int((width * 1000).rounded())) × \(Int((depth * 1000).rounded())) мм"
    }
}

struct TwinPlanRect: Hashable, Identifiable {
    let xMM: Int
    let zMM: Int
    let widthMM: Int
    let depthMM: Int

    var id: String { "\(xMM)-\(zMM)-\(widthMM)-\(depthMM)" }
    var areaMM2: Int { widthMM * depthMM }
}

struct TwinPlanSpace {
    let key: String
    let kind: TwinRoomKind
    let name: String
    let xMM: Int
    let zMM: Int
    let widthMM: Int
    let depthMM: Int
    let declaredAreaM2: Double
    let displayDimensions: String
    let renderAssetName: String
    var footprint: [TwinPlanRect] = []

    var planRects: [TwinPlanRect] {
        footprint.isEmpty
            ? [TwinPlanRect(xMM: xMM, zMM: zMM, widthMM: widthMM, depthMM: depthMM)]
            : footprint
    }
    var areaMM2: Int { Int((declaredAreaM2 * 1_000_000).rounded()) }
}

enum TwinPlan {
    static let widthMM = 6_070
    static let depthMM = 9_820
    static let declaredAreaM2 = 58.67

    // The low-resolution source plan provides areas and several dimensions. Small gaps below
    // represent wall thickness; the L-shaped corridor uses two rectangles from the same room.
    static let spaces: [TwinPlanSpace] = [
        .init(key: "living", kind: .living, name: "Гостиная", xMM: 0, zMM: 0,
              widthMM: 3_240, depthMM: 5_560, declaredAreaM2: 18.00,
              displayDimensions: "3 240 × 5 560 мм", renderAssetName: "TwinLiving"),
        .init(key: "kitchen", kind: .kitchen, name: "Кухня", xMM: 3_240, zMM: 0,
              widthMM: 2_830, depthMM: 2_340, declaredAreaM2: 6.62,
              displayDimensions: "2 830 × 2 340 мм", renderAssetName: "TwinKitchen"),
        .init(key: "bath", kind: .bathroom, name: "Ванная", xMM: 4_030, zMM: 2_340,
              widthMM: 2_040, depthMM: 1_035, declaredAreaM2: 2.11,
              displayDimensions: "≈ 2 040 × 1 035 мм", renderAssetName: "TwinBathroom"),
        .init(key: "wc", kind: .toilet, name: "Туалет", xMM: 4_300, zMM: 3_375,
              widthMM: 1_770, depthMM: 590, declaredAreaM2: 1.04,
              displayDimensions: "≈ 1 770 × 590 мм", renderAssetName: "TwinWC"),
        .init(key: "hall", kind: .hallway, name: "Коридор", xMM: 3_240, zMM: 2_340,
              widthMM: 2_830, depthMM: 3_660, declaredAreaM2: 7.04,
              displayDimensions: "Г-образный · 7,04 м²", renderAssetName: "TwinHallway",
              footprint: [
                TwinPlanRect(xMM: 3_240, zMM: 3_965, widthMM: 2_830, depthMM: 2_035),
                TwinPlanRect(xMM: 3_240, zMM: 2_340, widthMM: 790, depthMM: 1_625)
              ]),
        .init(key: "bed1", kind: .bedroom, name: "Спальня", xMM: 0, zMM: 5_560,
              widthMM: 3_190, depthMM: 4_260, declaredAreaM2: 13.58,
              displayDimensions: "≈ 3 190 × 4 260 мм", renderAssetName: "TwinPrimaryBedroom"),
        .init(key: "bed2", kind: .bedroom, name: "Вторая комната", xMM: 3_220, zMM: 6_210,
              widthMM: 2_850, depthMM: 3_610, declaredAreaM2: 10.28,
              displayDimensions: "≈ 2 850 × 3 610 мм", renderAssetName: "TwinFlexBedroom")
    ]

    static var interiorAreaMM2: Int { spaces.reduce(0) { $0 + $1.areaMM2 } }
    static func space(for room: TwinRoom) -> TwinPlanSpace? {
        spaces.first { $0.key == room.planKey }
    }
    static func space(forKey key: String?) -> TwinPlanSpace? {
        spaces.first { $0.key == key }
    }
}

struct TwinApartment: Codable, Equatable {
    static let storageKey = "oma_home_twin_photo_v3"
    private static let legacyStorageKeys = ["oma_home_twin_3d_v2", "oma_home_twin_3d_v1"]

    var rooms: [TwinRoom]
    var shelfRoomID: UUID?

    static func starter() -> TwinApartment {
        let rooms = TwinPlan.spaces.map { space in
            TwinRoom(planKey: space.key, kind: space.kind, name: space.name,
                     width: Double(space.widthMM) / 1000, depth: Double(space.depthMM) / 1000)
        }
        return TwinApartment(rooms: rooms, shelfRoomID: rooms.first?.id)
    }

    static func load(defaults: UserDefaults = .standard) -> TwinApartment {
        if let data = defaults.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode(TwinApartment.self, from: data),
           saved.rooms.count == TwinPlan.spaces.count,
           Set(saved.rooms.map(\.id)).count == saved.rooms.count,
           Set(saved.rooms.compactMap(\.planKey)) == Set(TwinPlan.spaces.map(\.key)) {
            var restored = saved
            for index in restored.rooms.indices {
                guard let space = TwinPlan.space(for: restored.rooms[index]) else { continue }
                restored.rooms[index].kind = space.kind
                restored.rooms[index].width = Double(space.widthMM) / 1000
                restored.rooms[index].depth = Double(space.depthMM) / 1000
            }
            if !restored.rooms.contains(where: { $0.id == restored.shelfRoomID }) {
                restored.shelfRoomID = restored.rooms.first?.id
            }
            return restored
        }

        var migrated = starter()
        let defaultNames = Set(["Гостиная", "Кухня", "Коридор", "Прихожая", "Спальня",
                                "Детская", "Вторая комната", "Санузел", "Ванная", "Туалет"])
        for legacyKey in legacyStorageKeys {
            guard let data = defaults.data(forKey: legacyKey),
                  let legacy = try? JSONDecoder().decode(TwinApartment.self, from: data) else { continue }
            var used = Set<UUID>()
            for index in migrated.rooms.indices {
                let target = migrated.rooms[index]
                let old = legacy.rooms.first {
                    $0.planKey == target.planKey && !used.contains($0.id)
                } ?? legacy.rooms.first {
                    $0.kind == target.kind && !used.contains($0.id)
                }
                guard let old else { continue }
                used.insert(old.id)
                if !defaultNames.contains(old.name) { migrated.rooms[index].name = old.name }
                migrated.rooms[index].finishedStages = old.finishedStages
                migrated.rooms[index].referencePhotoName = old.referencePhotoName
                if old.id == legacy.shelfRoomID { migrated.shelfRoomID = migrated.rooms[index].id }
            }
            break
        }
        migrated.save(defaults: defaults)
        return migrated
    }

    func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    mutating func mark(_ stage: TwinStage, in roomID: UUID, completed: Bool) {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else { return }
        if completed {
            rooms[index].finishedStages.insert(stage)
        } else {
            rooms[index].finishedStages.remove(stage)
        }
    }

    func progress(in roomID: UUID, shelf: TwinShelfEvidence) -> Int {
        guard let room = rooms.first(where: { $0.id == roomID }) else { return 0 }
        let includesShelf = shelf != .none && shelfRoomID == roomID
        let total = TwinStage.allCases.count + (includesShelf ? 1 : 0)
        let done = room.finishedStages.count + (includesShelf && shelf.isRecorded ? 1 : 0)
        return Int((Double(done) / Double(total) * 100).rounded())
    }

    func totalProgress(shelf: TwinShelfEvidence) -> Int {
        guard !rooms.isEmpty else { return 0 }
        let includesShelf = shelf != .none && rooms.contains(where: { $0.id == shelfRoomID })
        let total = rooms.count * TwinStage.allCases.count + (includesShelf ? 1 : 0)
        let done = rooms.reduce(0) { $0 + $1.finishedStages.count } +
            (includesShelf && shelf.isRecorded ? 1 : 0)
        return Int((Double(done) / Double(total) * 100).rounded())
    }
}
