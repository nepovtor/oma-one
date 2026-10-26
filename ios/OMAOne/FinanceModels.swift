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

enum FinanceBudgetKind: String, Codable, CaseIterable { case materials = "Материалы ОМА", services = "Услуги мастеров", delivery = "Доставка", extra = "Дополнительные расходы", reserve = "Резерв" }
struct FinanceBudgetLine: Codable, Identifiable {
    var id: String
    var kind: FinanceBudgetKind
    var estimatedMinor: Int
    var actualMinor: Int?
    var source: String
}
struct FinancePlan: Codable, Identifiable {
    var id: String
    var projectID: String
    var projectTitle: String
    var budgetMinor: Int
    var lines: [FinanceBudgetLine]
    var updatedAt: Date
    var estimatedMinor: Int { lines.reduce(0) { $0 + max(0, $1.estimatedMinor) } }
    var actualMinor: Int { lines.reduce(0) { $0 + max(0, $1.actualMinor ?? $1.estimatedMinor) } }
    var remainingMinor: Int { max(0, budgetMinor - actualMinor) }
    var overrunMinor: Int { max(0, actualMinor - budgetMinor) }
}
enum FinanceMilestoneStatus: String, Codable { case planned = "PLANNED", manuallyPaid = "MANUALLY_PAID", cancelled = "CANCELLED" }
struct FinanceMilestone: Codable, Identifiable {
    var id: String
    var projectID: String
    var title: String
    var amountMinor: Int
    var date: Date
    var stage: String
    var dependsOn: [String]
    var status: FinanceMilestoneStatus
    var note: String
    var linkedTransactionID: String?
}
struct FinanceSavingsGoal: Codable, Identifiable {
    var id: String
    var name: String
    var targetMinor: Int
    var savedMinor: Int
    var targetDate: Date
    var projectID: String?
    var createdAt: Date
}
struct FinanceSimulation: Codable {
    var projectCostMinor: Int
    var downPaymentMinor: Int
    var termMonths: Int
    var annualRateBasisPoints: Int
    var feesMinor: Int
    var financedMinor: Int
    var monthlyPaymentMinor: Int
    var totalPaymentsMinor: Int
    var overpaymentMinor: Int
    var totalCostMinor: Int
}

struct FinanceLocalState: Codable {
    var version = 1
    var mode: FinanceMode
    var account: FinanceAccount
    var cards: [FinanceCard]
    var transactions: [FinanceTransaction]
    var plans: [FinancePlan]
    var milestones: [FinanceMilestone]
    var goals: [FinanceSavingsGoal]
    var lastSimulation: FinanceSimulation
    var updatedAt: Date

    static func demo() -> FinanceLocalState {
        let account = FinanceAccount(id: "demo-account-1", providerAccountID: "demo-provider-account-001", name: "Основной демо-счёт", balanceMinor: 1_248_630, availableMinor: 1_218_630, source: .demo)
        let card = FinanceCard(id: "demo-card-1", providerCardID: "demo-card-token-2841", accountID: account.id, name: "OMA Finance Virtual", maskedPAN: "•••• 2841", status: .active, kind: "VIRTUAL", network: nil, controls: FinanceCardControls(online: true, contactless: false, cashWithdrawal: false, monthlyLimitMinor: 300_000), source: .demo, synthetic: true)
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        func transaction(_ id: String, days: Int, amount: Int, direction: String, kind: FinanceTransactionKind, category: String, counterparty: String, status: FinanceTransactionStatus = .settled, projectID: String? = nil) -> FinanceTransaction {
            FinanceTransaction(id: id, providerTransactionID: "demo-partner-\(id)", accountID: account.id, occurredAt: calendar.date(byAdding: .day, value: days, to: now) ?? now, amountMinor: amount, direction: direction, kind: kind, category: category, counterparty: counterparty, status: status, source: .demo, projectID: projectID, synthetic: true)
        }
        let shelfPlan = FinancePlan(id: "plan-shelf", projectID: "shelf-local", projectTitle: "Повесить полку", budgetMinor: 55_000, lines: [
            FinanceBudgetLine(id: "shelf-materials", kind: .materials, estimatedMinor: 11_200, actualMinor: nil, source: "ZeroBuy применён"),
            FinanceBudgetLine(id: "shelf-services", kind: .services, estimatedMinor: 18_000, actualMinor: nil, source: "Ручная оценка"),
            FinanceBudgetLine(id: "shelf-delivery", kind: .delivery, estimatedMinor: 2_500, actualMinor: nil, source: "Ручная оценка"),
            FinanceBudgetLine(id: "shelf-extra", kind: .extra, estimatedMinor: 3_000, actualMinor: nil, source: "Ручная оценка"),
            FinanceBudgetLine(id: "shelf-reserve", kind: .reserve, estimatedMinor: 5_000, actualMinor: nil, source: "Ручная оценка")
        ], updatedAt: now)
        let bathroomPlan = FinancePlan(id: "plan-bathroom", projectID: "bathroom-demo", projectTitle: "Обновление ванной · синтетический пример", budgetMinor: 800_000, lines: [
            FinanceBudgetLine(id: "bath-materials", kind: .materials, estimatedMinor: 360_000, actualMinor: nil, source: "Предварительная демо-смета"),
            FinanceBudgetLine(id: "bath-services", kind: .services, estimatedMinor: 260_000, actualMinor: nil, source: "Ручная оценка"),
            FinanceBudgetLine(id: "bath-delivery", kind: .delivery, estimatedMinor: 22_000, actualMinor: nil, source: "Ручная оценка"),
            FinanceBudgetLine(id: "bath-extra", kind: .extra, estimatedMinor: 38_000, actualMinor: nil, source: "Ручная оценка"),
            FinanceBudgetLine(id: "bath-reserve", kind: .reserve, estimatedMinor: 80_000, actualMinor: nil, source: "Ручная оценка")
        ], updatedAt: now)
        let simulation = FinanceStore.simulate(projectCostMinor: 550_000, downPaymentMinor: 150_000, termMonths: 24, annualRateBasisPoints: 1_800, feesMinor: 12_000)
        return FinanceLocalState(mode: .demo, account: account, cards: [card], transactions: [
            transaction("tx-1", days: -1, amount: 8_950, direction: "DEBIT", kind: .purchase, category: "Кафе", counterparty: "Кофейня у парка · синтетический пример"),
            transaction("tx-2", days: -2, amount: 3_400, direction: "DEBIT", kind: .purchase, category: "Транспорт", counterparty: "Городской транспорт · синтетический пример", status: .authorized),
            transaction("tx-3", days: -3, amount: 28_600, direction: "DEBIT", kind: .homeProject, category: "Материалы", counterparty: "Материалы для полки · демо", projectID: "shelf-local"),
            transaction("tx-4", days: -4, amount: 150_000, direction: "CREDIT", kind: .topUp, category: "Пополнение", counterparty: "Демо-пополнение")
        ], plans: [shelfPlan, bathroomPlan], milestones: [
            FinanceMilestone(id: "ms-materials", projectID: "shelf-local", title: "Купить материалы", amountMinor: 11_200, date: calendar.date(byAdding: .day, value: 7, to: now) ?? now, stage: "Подготовка", dependsOn: [], status: .planned, note: "Сумма после ZeroBuy", linkedTransactionID: nil),
            FinanceMilestone(id: "ms-install", projectID: "shelf-local", title: "Монтаж полки", amountMinor: 18_000, date: calendar.date(byAdding: .day, value: 10, to: now) ?? now, stage: "Монтаж", dependsOn: ["ms-materials"], status: .planned, note: "Ручная стоимость мастера", linkedTransactionID: nil)
        ], goals: [FinanceSavingsGoal(id: "goal-bathroom", name: "Обновление ванной", targetMinor: 800_000, savedMinor: 215_000, targetDate: calendar.date(byAdding: .month, value: 7, to: now) ?? now, projectID: "bathroom-demo", createdAt: now)], lastSimulation: simulation, updatedAt: now)
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

    nonisolated static func simulate(projectCostMinor: Int, downPaymentMinor: Int, termMonths: Int, annualRateBasisPoints: Int, feesMinor: Int) -> FinanceSimulation {
        let cost = max(0, projectCostMinor), down = min(cost, max(0, downPaymentMinor)), months = min(600, max(1, termMonths))
        let financed = cost - down, rate = Double(max(0, annualRateBasisPoints)) / 10_000 / 12
        let rawMonthly: Double
        if financed == 0 { rawMonthly = 0 }
        else if rate == 0 { rawMonthly = Double(financed) / Double(months) }
        else { let factor = pow(1 + rate, Double(months)); rawMonthly = Double(financed) * (rate * factor) / (factor - 1) }
        let monthly = Int(rawMonthly.rounded()), total = monthly * months
        return FinanceSimulation(projectCostMinor: cost, downPaymentMinor: down, termMonths: months, annualRateBasisPoints: max(0, annualRateBasisPoints), feesMinor: max(0, feesMinor), financedMinor: financed, monthlyPaymentMinor: monthly, totalPaymentsMinor: total, overpaymentMinor: max(0, total - financed), totalCostMinor: down + total + max(0, feesMinor))
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

    func syncMaterialsFromCart(_ cartMinor: Int) {
        guard cartMinor > 0, let planIndex = state.plans.firstIndex(where: { $0.projectID == "shelf-local" }), let lineIndex = state.plans[planIndex].lines.firstIndex(where: { $0.kind == .materials }) else { return }
        state.plans[planIndex].lines[lineIndex].estimatedMinor = cartMinor
        state.plans[planIndex].lines[lineIndex].source = "Корзина после ZeroBuy — повторно не вычитается"
        state.plans[planIndex].updatedAt = Date(); state.updatedAt = Date()
    }

    func updatePlanLine(planID: String, lineID: String, estimatedMinor: Int? = nil, actualMinor: Int? = nil, clearActual: Bool = false) {
        guard let planIndex = state.plans.firstIndex(where: { $0.id == planID }), let lineIndex = state.plans[planIndex].lines.firstIndex(where: { $0.id == lineID }) else { return }
        if let estimatedMinor { state.plans[planIndex].lines[lineIndex].estimatedMinor = max(0, estimatedMinor) }
        if clearActual { state.plans[planIndex].lines[lineIndex].actualMinor = nil }
        else if let actualMinor { state.plans[planIndex].lines[lineIndex].actualMinor = max(0, actualMinor) }
        state.plans[planIndex].updatedAt = Date(); state.updatedAt = Date(); notice = "Бюджет сохранён локально"
    }

    func updatePlanBudget(planID: String, budgetMinor: Int) {
        guard let index = state.plans.firstIndex(where: { $0.id == planID }) else { return }
        state.plans[index].budgetMinor = max(0, budgetMinor); state.plans[index].updatedAt = Date(); state.updatedAt = Date()
    }

    func addPlan() {
        let id = UUID().uuidString.lowercased()
        state.plans.append(FinancePlan(id: "plan-\(id)", projectID: "local-\(id)", projectTitle: "Новый домашний проект", budgetMinor: 100_000, lines: FinanceBudgetKind.allCases.enumerated().map { index, kind in FinanceBudgetLine(id: "line-\(id)-\(index)", kind: kind, estimatedMinor: 0, actualMinor: nil, source: "Ручная оценка") }, updatedAt: Date()))
        state.updatedAt = Date(); notice = "Новый бюджет создан"
    }

    func setMilestoneStatus(_ id: String, status: FinanceMilestoneStatus) {
        guard let index = state.milestones.firstIndex(where: { $0.id == id }) else { return }
        state.milestones[index].status = status; state.updatedAt = Date()
        notice = status == .manuallyPaid ? "Отмечено вручную. Банковская операция не создавалась." : "Статус этапа обновлён"
    }

    func milestoneOrderErrors(projectID: String) -> [String] {
        let rows = state.milestones.filter { $0.projectID == projectID }
        let ids = Set(rows.map(\.id)); var errors: [String] = []
        for row in rows { for dependency in row.dependsOn where !ids.contains(dependency) { errors.append("Для \(row.title) отсутствует зависимость \(dependency)") } }
        func reaches(_ current: String, target: String, visited: inout Set<String>) -> Bool {
            guard visited.insert(current).inserted, let row = rows.first(where: { $0.id == current }) else { return false }
            if row.dependsOn.contains(target) { return true }
            return row.dependsOn.contains { reaches($0, target: target, visited: &visited) }
        }
        for row in rows { var visited = Set<String>(); if reaches(row.id, target: row.id, visited: &visited) { errors.append("Обнаружен цикл этапов") } }
        return Array(Set(errors))
    }

    func updateSimulation(projectCostMinor: Int, downPaymentMinor: Int, termMonths: Int, annualRateBasisPoints: Int, feesMinor: Int) {
        state.lastSimulation = Self.simulate(projectCostMinor: projectCostMinor, downPaymentMinor: downPaymentMinor, termMonths: termMonths, annualRateBasisPoints: annualRateBasisPoints, feesMinor: feesMinor)
        state.updatedAt = Date(); notice = "Расчёт сохранён. Это не кредитная заявка и не одобрение."
    }

    func addGoal(name: String, targetMinor: Int, savedMinor: Int, targetDate: Date, projectID: String?) -> Bool {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, targetMinor > 0, savedMinor >= 0 else { notice = "Проверьте название и суммы цели"; return false }
        state.goals.append(FinanceSavingsGoal(id: "goal-\(UUID().uuidString.lowercased())", name: String(title.prefix(80)), targetMinor: targetMinor, savedMinor: min(savedMinor, targetMinor), targetDate: targetDate, projectID: projectID, createdAt: Date()))
        state.updatedAt = Date(); notice = "Финансовая цель сохранена как личный план, не банковский счёт"; return true
    }

    func updateGoalSaved(_ id: String, savedMinor: Int) {
        guard let index = state.goals.firstIndex(where: { $0.id == id }) else { return }
        state.goals[index].savedMinor = min(state.goals[index].targetMinor, max(0, savedMinor)); state.updatedAt = Date()
    }

    func monthlyGoalAmount(_ goal: FinanceSavingsGoal, now: Date = Date()) -> Int {
        let remaining = max(0, goal.targetMinor - goal.savedMinor)
        let months = max(1, Calendar.current.dateComponents([.month], from: now, to: goal.targetDate).month ?? 1)
        return Int(ceil(Double(remaining) / Double(months)))
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
