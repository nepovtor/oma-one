import Foundation

// HOME TWIN is a user-authored, approximate apartment model, not a measured scan.
// Only user-marked milestones and local OMA ONE Proof records affect progress.
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
}

struct TwinApartment: Codable, Equatable {
    static let storageKey = "oma_home_twin_3d_v1"
    static let maximumRooms = 4

    var rooms: [TwinRoom]
    var shelfRoomID: UUID?

    static func starter() -> TwinApartment {
        let living = TwinRoom(kind: .living, name: "Моя гостиная", width: 4.5, depth: 4.5)
        let kitchen = TwinRoom(kind: .kitchen, name: "Кухня", width: 3.5, depth: 3.5)
        return TwinApartment(rooms: [living, kitchen], shelfRoomID: living.id)
    }

    static func load(defaults: UserDefaults = .standard) -> TwinApartment {
        guard let data = defaults.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode(TwinApartment.self, from: data),
              (1...maximumRooms).contains(saved.rooms.count),
              Set(saved.rooms.map(\.id)).count == saved.rooms.count,
              saved.rooms.allSatisfy({ (2.5...5.8).contains($0.width) &&
                  (2.5...5.8).contains($0.depth) }) else {
            return starter()
        }
        var restored = saved
        if !restored.rooms.contains(where: { $0.id == restored.shelfRoomID }) {
            restored.shelfRoomID = restored.rooms.first?.id
        }
        return restored
    }

    func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    mutating func addRoom(kind: TwinRoomKind) -> Bool {
        guard rooms.count < Self.maximumRooms else { return false }
        let room = TwinRoom(kind: kind, name: kind.title)
        rooms.append(room)
        return true
    }

    mutating func updateRoom(id: UUID, kind: TwinRoomKind, name: String, width: Double, depth: Double) {
        guard let index = rooms.firstIndex(where: { $0.id == id }) else { return }
        rooms[index].kind = kind
        rooms[index].name = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(36))
        if rooms[index].name.isEmpty { rooms[index].name = kind.title }
        rooms[index].width = min(5.8, max(2.5, width))
        rooms[index].depth = min(5.8, max(2.5, depth))
    }

    mutating func removeRoom(id: UUID) {
        guard rooms.count > 1 else { return }
        rooms.removeAll { $0.id == id }
        if shelfRoomID == id { shelfRoomID = rooms.first?.id }
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
