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
        let products = [["id":"p07", "name":"Shelf", "unitPrice":89] as [String:Any]]
        let completeInput = complete.engineInput(products:products)
        precondition(completeInput["surface"] as? String == "concrete")
        precondition(completeInput["fastener"] as? String == "concrete-anchor")
        precondition((completeInput["products"] as? [[String:Any]])?.count == 1)

        var unsafe = complete
        unsafe.wall = .drywall
        precondition(unsafe.engineInput(products:[])["surface"] as? String == "drywall")
        unsafe.fastener = .drywallAnchor
        precondition(unsafe.engineInput(products:[])["fastener"] as? String == "drywall-anchor")

        var unfinished = ShelfProjectData()
        unfinished.wall = .drywall
        unfinished.shelfWeightKg = 2
        precondition(unfinished.engineInput(products:[])["surface"] as? String == "drywall")
        precondition(!unfinished.hasProofPhoto)
        let saved = try JSONEncoder().encode(unfinished)
        let restored = try JSONDecoder().decode(ShelfProjectData.self, from: saved)
        precondition(restored == unfinished)
        precondition(restored.id == unfinished.id)
        print("shelf model: complete, blocked, incomplete and persistence passed")
    }
}
