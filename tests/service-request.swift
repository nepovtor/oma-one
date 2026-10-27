import Foundation

@main
struct CheckServiceModel {
 static func main() {
  let suite = "oma.service.tests." + UUID().uuidString
  let defaults = UserDefaults(suiteName: suite)!
  defer { defaults.removePersistentDomain(forName: suite) }
  var ledger = DemoServiceLedger()
  let project = UUID()
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let calendar = Calendar(identifier: .gregorian)
  let validDay = calendar.date(byAdding:.day,value:4,to:now)!
  let first = ledger.create(projectID:project,kind:.shelfInstallation,desiredDay:validDay,slot:.morning,note:"   Нужно проверить стену   ",now:now,calendar:calendar)
  guard case .success(let req) = first else { fatalError("valid request must save") }
  assert(req.note == "Нужно проверить стену")
  assert(req.indicativePriceBYN == 65)
  assert(req.status == .savedLocally)
  assert(ledger.requests.count == 1)
  assert(ledger.activeRequest(for:project)?.id == req.id)
  let dup = ledger.create(projectID:project,kind:.shelfInstallation,desiredDay:validDay,slot:.morning,note:"",now:now,calendar:calendar)
  assert(dup == .failure(.duplicateActiveProject))
  let yesterday = calendar.date(byAdding:.day,value:-1,to:now)!
  assert(ledger.create(projectID:nil,kind:.shelfInstallation,desiredDay:yesterday,slot:.morning,note:"",now:now,calendar:calendar) == .failure(.invalidDate))
  let beyond = calendar.date(byAdding:.day,value:31,to:now)!
  assert(ledger.create(projectID:nil,kind:.shelfInstallation,desiredDay:beyond,slot:.morning,note:"",now:now,calendar:calendar) == .failure(.invalidDate))
  assert(ledger.create(projectID:nil,kind:.shelfInstallation,desiredDay:validDay,slot:.morning,note:String(repeating:"x",count:301),now:now,calendar:calendar) == .failure(.noteTooLong))
  assert(ledger.cancel(id:req.id))
  assert(!ledger.cancel(id:req.id))
  assert(ledger.activeRequest(for:project) == nil)
  guard case .success = ledger.create(projectID:project,kind:.shelfInstallation,desiredDay:validDay,slot:.afternoon,note:"",now:now,calendar:calendar) else {fatalError("new request after cancellation")}
  let encoded = try! JSONEncoder().encode(ledger)
  defaults.set(encoded,forKey:"test")
  assert(try! JSONDecoder().decode(DemoServiceLedger.self,from:defaults.data(forKey:"test")!) == ledger)
  print("service model checks: PASS")
 }
}
