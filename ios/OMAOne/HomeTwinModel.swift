import Foundation

// Synthetic, fixed 80 m² demonstration layout. Millimetres are model coordinates,
// not a measured apartment or construction documentation.
enum TwinRoomKind: String, Codable, CaseIterable, Identifiable {
    case living, kitchen, bedroom, bathroom, hallway

    var id: String { rawValue }
    var title: String {
        switch self {
        case .living: return "Гостиная"
        case .kitchen: return "Кухня"
        case .bedroom: return "Спальня"
        case .bathroom: return "Ванная"
        case .hallway: return "Прихожая"
        }
    }
    var symbol: String {
        switch self {
        case .living: return "sofa"
        case .kitchen: return "fork.knife"
        case .bedroom: return "bed.double"
        case .bathroom: return "shower"
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
        let value = width * depth
        return "\(value.formatted(.number.precision(.fractionLength(0...1)))) м²"
    }

    var dimensionsLabel: String {
        "\(Int((width * 1000).rounded())) × \(Int((depth * 1000).rounded())) мм"
    }
}

struct TwinPlanSpace {
    let key: String
    let kind: TwinRoomKind
    let name: String
    let xMM: Int
    let zMM: Int
    let widthMM: Int
    let depthMM: Int

    var areaMM2: Int { widthMM * depthMM }
}

enum TwinPlan {
    static let widthMM = 10_000
    static let depthMM = 8_000
    static let balconyWidthMM = 1_600
    static let balconyDepthMM = 3_000

    // Coordinates tile the entire 10 000 × 8 000 mm interior without overlap.
    static let spaces: [TwinPlanSpace] = [
        .init(key: "living", kind: .living, name: "Гостиная", xMM: 0, zMM: 0, widthMM: 4_000, depthMM: 5_000),
        .init(key: "kitchen", kind: .kitchen, name: "Кухня", xMM: 0, zMM: 5_000, widthMM: 4_000, depthMM: 3_000),
        .init(key: "hall", kind: .hallway, name: "Коридор", xMM: 4_000, zMM: 0, widthMM: 2_000, depthMM: 8_000),
        .init(key: "bed1", kind: .bedroom, name: "Спальня", xMM: 6_000, zMM: 0, widthMM: 4_000, depthMM: 3_500),
        .init(key: "bed2", kind: .bedroom, name: "Детская", xMM: 6_000, zMM: 3_500, widthMM: 4_000, depthMM: 2_500),
        .init(key: "bath", kind: .bathroom, name: "Санузел", xMM: 6_000, zMM: 6_000, widthMM: 4_000, depthMM: 2_000)
    ]

    static var interiorAreaMM2: Int { spaces.reduce(0) { $0 + $1.areaMM2 } }
    static func space(for room: TwinRoom) -> TwinPlanSpace? {
        spaces.first { $0.key == room.planKey }
    }
}

struct TwinApartment: Codable, Equatable {
    static let storageKey = "oma_home_twin_3d_v2"
    private static let legacyStorageKey = "oma_home_twin_3d_v1"

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
        if let data = defaults.data(forKey: legacyStorageKey),
           let legacy = try? JSONDecoder().decode(TwinApartment.self, from: data) {
            var used = Set<UUID>()
            for index in migrated.rooms.indices {
                let kind = migrated.rooms[index].kind
                guard let old = legacy.rooms.first(where: { $0.kind == kind && !used.contains($0.id) }) else { continue }
                used.insert(old.id)
                migrated.rooms[index].name = old.name
                migrated.rooms[index].finishedStages = old.finishedStages
                migrated.rooms[index].referencePhotoName = old.referencePhotoName
                if old.id == legacy.shelfRoomID { migrated.shelfRoomID = migrated.rooms[index].id }
            }
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
