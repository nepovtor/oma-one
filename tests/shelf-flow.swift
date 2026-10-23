import Foundation

@main struct ShelfFlowChecks {
    static func main() throws {
        var complete = ShelfProjectData()
        complete.wall = .concrete
        complete.shelfWeightKg = 2
        complete.plannedLoadKg = 5
        complete.fastener = .concreteAnchor
        complete.wallInspected = true
        complete.utilitiesChecked = true
        complete.manufacturerInstructionsChecked = true
        precondition(complete.readiness(antiFailStatus: "PRELIMINARY_PASS") == .candidate)
        precondition(complete.candidateProductIDs(antiFailStatus: "PRELIMINARY_PASS") == ["p07", "p08", "p25"])

        var unsafe = complete
        unsafe.wall = .drywall
        precondition(unsafe.readiness(antiFailStatus: "BLOCKED") == .blocked)
        precondition(unsafe.candidateProductIDs(antiFailStatus: "BLOCKED").isEmpty)
        unsafe.fastener = .drywallAnchor
        precondition(unsafe.candidateProductIDs(antiFailStatus: "PRELIMINARY_PASS") == ["p07", "p09", "p25"])

        var unfinished = ShelfProjectData()
        unfinished.wall = .drywall
        unfinished.shelfWeightKg = 2
        precondition(unfinished.readiness(antiFailStatus: nil) == .incomplete)
        precondition(unfinished.candidateProductIDs(antiFailStatus: nil).isEmpty)
        precondition(!unfinished.hasProofPhoto)
        let saved = try JSONEncoder().encode(unfinished)
        let restored = try JSONDecoder().decode(ShelfProjectData.self, from: saved)
        precondition(restored == unfinished)
        precondition(restored.id == unfinished.id)
        print("shelf model: complete, blocked, incomplete and persistence passed")
    }
}
