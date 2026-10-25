import Foundation

@main
struct TwinModelRegression {
    static func main() {
        let suiteName = "oma.home-twin.test." + UUID().uuidString
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Could not initialize isolated UserDefaults suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var apartment = TwinApartment.load(defaults: defaults)
        assert(apartment.rooms.count == 2)
        assert(apartment.totalProgress(shelf: .none) == 0)
        let originalID = apartment.rooms[0].id
        assert(apartment.shelfRoomID == originalID)

        apartment.mark(.walls, in: originalID, completed: true)
        assert(apartment.progress(in: originalID, shelf: .none) == 25)
        assert(apartment.totalProgress(shelf: .none) == 13)
        apartment.mark(.walls, in: originalID, completed: true)
        assert(apartment.rooms[0].finishedStages.count == 1, "No duplicate stages")

        for stage in TwinStage.allCases {
            apartment.mark(stage, in: originalID, completed: true)
        }
        let planned = apartment.totalProgress(shelf: .planned)
        let reported = apartment.totalProgress(shelf: .selfReported)
        assert(reported > planned, "Shelf must become completed only after Proof record")
        assert(apartment.totalProgress(shelf: .photoSubmitted) == reported,
               "Photos do not double-count or add expert status")

        apartment.mark(.furniture, in: originalID, completed: false)
        assert(!apartment.rooms[0].finishedStages.contains(.furniture))
        apartment.updateRoom(id: originalID, kind: .living, name: "  Гостиная семьи ",
                             width: 9.0, depth: 1.0)
        assert(apartment.rooms[0].name == "Гостиная семьи")
        assert(apartment.rooms[0].width == 5.8 && apartment.rooms[0].depth == 2.5,
               "Invalid dimensions must be bounded")

        assert(apartment.addRoom(kind: .bedroom))
        assert(apartment.addRoom(kind: .bathroom))
        assert(!apartment.addRoom(kind: .hallway), "MVP room limit is four")
        apartment.save(defaults: defaults)

        var reloaded = TwinApartment.load(defaults: defaults)
        assert(reloaded == apartment, "User-authored rooms and marks must persist")
        reloaded.removeRoom(id: originalID)
        assert(reloaded.rooms.count == 3)
        assert(reloaded.shelfRoomID != originalID, "Removing a room must rehome the shelf")

        for room in Array(reloaded.rooms.dropFirst()) {
            reloaded.removeRoom(id: room.id)
        }
        assert(reloaded.rooms.count == 1)
        reloaded.removeRoom(id: reloaded.rooms[0].id)
        assert(reloaded.rooms.count == 1, "Must preserve at least one room")

        // A corrupt or incompatible payload restores a safe local starter
        defaults.set(Data("broken json".utf8), forKey: TwinApartment.storageKey)
        assert(TwinApartment.load(defaults: defaults).rooms.count == 2)
        print("home twin model passed")
    }
}
