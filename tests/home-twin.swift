import Foundation

@main
struct TwinModelRegression {
    static func main() {
        let suiteName = "oma.home-twin.test." + UUID().uuidString
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Could not initialize isolated UserDefaults suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        assert(TwinPlan.widthMM * TwinPlan.depthMM == 80_000_000)
        assert(TwinPlan.interiorAreaMM2 == 80_000_000)
        assert(TwinPlan.balconyWidthMM * TwinPlan.balconyDepthMM == 4_800_000)
        for (index, a) in TwinPlan.spaces.enumerated() {
            assert(a.xMM >= 0 && a.zMM >= 0)
            assert(a.xMM + a.widthMM <= TwinPlan.widthMM)
            assert(a.zMM + a.depthMM <= TwinPlan.depthMM)
            for b in TwinPlan.spaces.dropFirst(index + 1) {
                let overlapX = max(a.xMM, b.xMM) < min(a.xMM + a.widthMM, b.xMM + b.widthMM)
                let overlapZ = max(a.zMM, b.zMM) < min(a.zMM + a.depthMM, b.zMM + b.depthMM)
                assert(!(overlapX && overlapZ), "Rooms must not overlap")
            }
        }

        var apartment = TwinApartment.load(defaults: defaults)
        assert(apartment.rooms.count == 6)
        assert(apartment.rooms.filter { $0.kind == .bedroom }.count == 2)
        assert(apartment.totalProgress(shelf: .none) == 0)
        let livingID = apartment.rooms[0].id
        assert(apartment.shelfRoomID == livingID)
        assert(apartment.rooms[0].dimensionsLabel == "4000 × 5000 мм")
        apartment.mark(.walls, in: livingID, completed: true)
        apartment.mark(.walls, in: livingID, completed: true)
        assert(apartment.rooms[0].finishedStages.count == 1)
        assert(apartment.progress(in: livingID, shelf: .none) == 25)
        for stage in TwinStage.allCases { apartment.mark(stage, in: livingID, completed: true) }
        assert(apartment.totalProgress(shelf: .selfReported) > apartment.totalProgress(shelf: .planned))
        assert(apartment.totalProgress(shelf: .photoSubmitted) == apartment.totalProgress(shelf: .selfReported))
        apartment.mark(.furniture, in: livingID, completed: false)
        assert(!apartment.rooms[0].finishedStages.contains(.furniture))
        apartment.rooms[0].referencePhotoName = "\(livingID.uuidString).jpg"
        apartment.save(defaults: defaults)
        assert(TwinApartment.load(defaults: defaults) == apartment)

        // A persisted dimension cannot silently change the fixed synthetic plan.
        apartment.rooms[0].width = 100
        apartment.save(defaults: defaults)
        assert(TwinApartment.load(defaults: defaults).rooms[0].width == 4)

        // Legacy v1 records remain in their original key and useful progress/photo data migrate.
        defaults.removeObject(forKey: TwinApartment.storageKey)
        let oldRoom = TwinRoom(kind: .living, name: "Гостиная семьи", width: 4.5, depth: 4.5,
                               finishedStages: [.floor], referencePhotoName: "\(livingID.uuidString).jpg")
        let legacy = TwinApartment(rooms: [oldRoom], shelfRoomID: oldRoom.id)
        defaults.set(try! JSONEncoder().encode(legacy), forKey: "oma_home_twin_3d_v1")
        let migrated = TwinApartment.load(defaults: defaults)
        assert(migrated.rooms[0].name == "Гостиная семьи")
        assert(migrated.rooms[0].width == 4 && migrated.rooms[0].depth == 5)
        assert(migrated.rooms[0].finishedStages == [.floor])
        assert(migrated.rooms[0].referencePhotoName == oldRoom.referencePhotoName)
        assert(migrated.shelfRoomID == migrated.rooms[0].id)
        assert(defaults.data(forKey: "oma_home_twin_3d_v1") != nil)

        defaults.set(Data("broken json".utf8), forKey: TwinApartment.storageKey)
        assert(TwinApartment.load(defaults: defaults).rooms.count == 6)
        print("home twin model passed")
    }
}
