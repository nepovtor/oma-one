import Foundation

enum FinanceMode: String, Codable, CaseIterable { case demo = "DEMO", sandbox = "SANDBOX", live = "LIVE" }
enum FinanceCardStatus: String, Codable { case active = "ACTIVE", blocked = "BLOCKED", preparing = "PREPARING" }
enum FinanceTransactionStatus: String, Codable, CaseIterable { case pending = "PENDING", authorized = "AUTHORIZED", settled = "SETTLED", declined = "DECLINED", reversed = "REVERSED" }
enum FinanceTransactionKind: String, Codable, CaseIterable { case purchase = "Покупки", transfer = "Переводы", service = "Услуги", refund = "Возвраты", homeProject = "Домашние проекты", topUp = "Пополнения" }

struct FinanceAccount: Codable {
    var id: String
    var providerAccountID: String
    var name: String
    var balanceMinor: Int
    var availableMinor: Int
    var source: FinanceMode
}

struct FinanceCardControls: Codable {
    var online: Bool
    var contactless: Bool
    var cashWithdrawal: Bool
    var monthlyLimitMinor: Int
}

struct FinanceCard: Codable, Identifiable {
    var id: String
    var providerCardID: String
    var accountID: String
    var name: String
    var maskedPAN: String
    var status: FinanceCardStatus
    var kind: String
    var network: String?
    var controls: FinanceCardControls
    var source: FinanceMode
    var synthetic: Bool
}

struct FinanceTransaction: Codable, Identifiable {
    var id: String
    var providerTransactionID: String
    var accountID: String
    var occurredAt: Date
    var amountMinor: Int
    var direction: String
    var kind: FinanceTransactionKind
    var category: String
    var counterparty: String
    var status: FinanceTransactionStatus
    var source: FinanceMode
    var projectID: String?
    var synthetic: Bool
}

struct FinanceLocalState: Codable {
    var version = 1
    var mode: FinanceMode
    var account: FinanceAccount
    var cards: [FinanceCard]
    var transactions: [FinanceTransaction]
    var updatedAt: Date

    static func demo() -> FinanceLocalState {
        let account = FinanceAccount(id: "demo-account-1", providerAccountID: "demo-provider-account-001", name: "Основной демо-счёт", balanceMinor: 1_248_630, availableMinor: 1_218_630, source: .demo)
        let card = FinanceCard(id: "demo-card-1", providerCardID: "demo-card-token-2841", accountID: account.id, name: "OMA Finance Virtual", maskedPAN: "•••• 2841", status: .active, kind: "VIRTUAL", network: nil, controls: FinanceCardControls(online: true, contactless: false, cashWithdrawal: false, monthlyLimitMinor: 300_000), source: .demo, synthetic: true)
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        func transaction(_ id: String, days: Int, amount: Int, direction: String, kind: FinanceTransactionKind, category: String, counterparty: String, status: FinanceTransactionStatus = .settled, projectID: String? = nil) -> FinanceTransaction {
            FinanceTransaction(id: id, providerTransactionID: "demo-partner-\(id)", accountID: account.id, occurredAt: calendar.date(byAdding: .day, value: days, to: now) ?? now, amountMinor: amount, direction: direction, kind: kind, category: category, counterparty: counterparty, status: status, source: .demo, projectID: projectID, synthetic: true)
        }
        return FinanceLocalState(mode: .demo, account: account, cards: [card], transactions: [
            transaction("tx-1", days: -1, amount: 8_950, direction: "DEBIT", kind: .purchase, category: "Кафе", counterparty: "Кофейня у парка · синтетический пример"),
            transaction("tx-2", days: -2, amount: 3_400, direction: "DEBIT", kind: .purchase, category: "Транспорт", counterparty: "Городской транспорт · синтетический пример", status: .authorized),
            transaction("tx-3", days: -3, amount: 28_600, direction: "DEBIT", kind: .homeProject, category: "Материалы", counterparty: "Материалы для полки · демо", projectID: "shelf-local"),
            transaction("tx-4", days: -4, amount: 150_000, direction: "CREDIT", kind: .topUp, category: "Пополнение", counterparty: "Демо-пополнение")
        ], updatedAt: now)
    }
}

@MainActor final class FinanceStore: ObservableObject {
    private static let storageKey = "oma_finance_demo_v1"
    @Published var state: FinanceLocalState { didSet { persist() } }
    @Published var notice = ""

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey), let saved = try? JSONDecoder().decode(FinanceLocalState.self, from: data), saved.mode == .demo {
            state = saved
        } else {
            state = .demo()
        }
    }

    func persist() {
        guard state.mode == .demo, let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    func setCardBlocked(_ cardID: String, blocked: Bool) {
        guard let index = state.cards.firstIndex(where: { $0.id == cardID }) else { return }
        state.cards[index].status = blocked ? .blocked : .active
        state.updatedAt = Date()
        notice = blocked ? "Синтетическая карта заблокирована только в DEMO" : "Синтетическая карта разблокирована только в DEMO"
    }

    func updateControls(_ cardID: String, online: Bool? = nil, contactless: Bool? = nil, cashWithdrawal: Bool? = nil, monthlyLimitMinor: Int? = nil) {
        guard let index = state.cards.firstIndex(where: { $0.id == cardID }) else { return }
        if let online { state.cards[index].controls.online = online }
        if let contactless { state.cards[index].controls.contactless = contactless }
        if let cashWithdrawal { state.cards[index].controls.cashWithdrawal = cashWithdrawal }
        if let monthlyLimitMinor { state.cards[index].controls.monthlyLimitMinor = max(0, monthlyLimitMinor) }
        state.updatedAt = Date()
        notice = "Настройки сохранены в изолированном DEMO"
    }

    func requestVirtualCard() {
        let suffix = String(format: "%04d", Int.random(in: 0...9999))
        let id = "demo-card-\(UUID().uuidString.lowercased())"
        state.cards.append(FinanceCard(id: id, providerCardID: "demo-token-\(UUID().uuidString.lowercased())", accountID: state.account.id, name: "OMA Finance Virtual", maskedPAN: "•••• \(suffix)", status: .active, kind: "VIRTUAL", network: nil, controls: FinanceCardControls(online: true, contactless: false, cashWithdrawal: false, monthlyLimitMinor: 150_000), source: .demo, synthetic: true))
        state.updatedAt = Date()
        notice = "Создана тестовая запись карты. Она не работает для настоящих покупок."
    }

    func demoOperation(amountText: String, counterparty: String, topUp: Bool) -> Bool {
        let normalized = amountText.replacingOccurrences(of: ",", with: ".")
        guard let decimal = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")), decimal > 0 else {
            notice = "Введите корректную сумму"
            return false
        }
        let minor = NSDecimalNumber(decimal: decimal * 100).intValue
        guard minor >= 100 else { notice = "Минимальная демо-сумма — 1 BYN"; return false }
        guard topUp || minor <= state.account.availableMinor else { notice = "Недостаточно синтетического остатка"; return false }
        let direction = topUp ? "CREDIT" : "DEBIT"
        state.account.balanceMinor += topUp ? minor : -minor
        state.account.availableMinor += topUp ? minor : -minor
        state.transactions.insert(FinanceTransaction(id: "demo-\(UUID().uuidString.lowercased())", providerTransactionID: "demo-local-\(UUID().uuidString.lowercased())", accountID: state.account.id, occurredAt: Date(), amountMinor: minor, direction: direction, kind: topUp ? .topUp : .transfer, category: topUp ? "Пополнение" : "Переводы", counterparty: counterparty.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (topUp ? "Демо-пополнение" : "Демо-получатель") : String(counterparty.prefix(80)), status: .settled, source: .demo, projectID: nil, synthetic: true), at: 0)
        state.updatedAt = Date()
        notice = "Синтетическая операция добавлена. Реальные деньги не перемещались."
        return true
    }
}

func financeMoney(_ minor: Int) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "ru_BY")
    formatter.numberStyle = .currency
    formatter.currencyCode = "BYN"
    formatter.minimumFractionDigits = 2
    return formatter.string(from: NSNumber(value: Double(minor) / 100)) ?? "\(minor / 100) BYN"
}
