import Foundation

// Demo-only service requests. Nothing in this model contacts OMA, a technician,
// a payment provider, or a backend; these records remain on the device.
enum DemoServiceKind: String, Codable, CaseIterable, Identifiable {
    case shelfInstallation, faucetRepair, bathroomConsultation
    var id: String { rawValue }
    var title: String {
        switch self {
        case .shelfInstallation: return "Установка полки"
        case .faucetRepair: return "Осмотр смесителя"
        case .bathroomConsultation: return "Консультация по ванной"
        }
    }
    var indicativePriceBYN: Int {
        switch self {
        case .shelfInstallation: return 65
        case .faucetRepair: return 95
        case .bathroomConsultation: return 120
        }
    }
}

enum DemoServiceSlot: String, Codable, CaseIterable, Identifiable {
    case morning, afternoon, evening
    var id: String { rawValue }
    var title: String {
        switch self {
        case .morning: return "09:00–12:00"
        case .afternoon: return "12:00–16:00"
        case .evening: return "16:00–20:00"
        }
    }
}

enum DemoServiceStatus: String, Codable {
    case savedLocally, cancelled
    var title: String {
        switch self {
        case .savedLocally: return "Сохранена только на телефоне"
        case .cancelled: return "Отменена в демо"
        }
    }
}

struct DemoServiceRequest: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    let projectID: UUID?
    let kind: DemoServiceKind
    let desiredDay: Date
    let slot: DemoServiceSlot
    let note: String
    let indicativePriceBYN: Int
    let createdAt: Date
    var status: DemoServiceStatus = .savedLocally
}

enum DemoServiceRequestError: Error, Equatable {
    case invalidDate, noteTooLong, duplicateActiveProject
    var message: String {
        switch self {
        case .invalidDate: return "Выберите день с сегодняшнего по 30-й день включительно."
        case .noteTooLong: return "Сократите примечание до 300 символов."
        case .duplicateActiveProject: return "Для этого проекта уже сохранена демо-заявка. Её можно отменить ниже."
        }
    }
}

struct DemoServiceLedger: Codable, Equatable {
    private(set) var requests: [DemoServiceRequest] = []

    func activeRequest(for projectID: UUID) -> DemoServiceRequest? {
        requests.first { $0.projectID == projectID && $0.status == .savedLocally }
    }

    mutating func create(projectID: UUID?, kind: DemoServiceKind,
                         desiredDay: Date, slot: DemoServiceSlot, note: String,
                         now: Date = Date(), calendar: Calendar = .current)
        -> Result<DemoServiceRequest, DemoServiceRequestError> {
        let today = calendar.startOfDay(for: now)
        let day = calendar.startOfDay(for: desiredDay)
        guard let lastDay = calendar.date(byAdding: .day, value: 30, to: today),
              day >= today && day <= lastDay else { return .failure(.invalidDate) }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedNote.count <= 300 else { return .failure(.noteTooLong) }
        if let projectID, activeRequest(for: projectID) != nil {
            return .failure(.duplicateActiveProject)
        }
        let request = DemoServiceRequest(projectID: projectID, kind: kind,
                                         desiredDay: day, slot: slot, note: trimmedNote,
                                         indicativePriceBYN: kind.indicativePriceBYN,
                                         createdAt: now)
        requests.insert(request, at: 0)
        return .success(request)
    }

    mutating func cancel(id: UUID) -> Bool {
        guard let index = requests.firstIndex(where: { $0.id == id && $0.status == .savedLocally }) else {
            return false
        }
        requests[index].status = .cancelled
        return true
    }
}
