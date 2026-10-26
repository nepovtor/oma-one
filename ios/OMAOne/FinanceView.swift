import SwiftUI

enum FinancePalette {
    static let navy = Color(red: 0.035, green: 0.13, blue: 0.29)
    static let blue = Color(red: 0.08, green: 0.32, blue: 0.67)
    static let ground = Color(red: 0.949, green: 0.961, blue: 0.976)
    static let ink = Color(red: 0.07, green: 0.09, blue: 0.12)
    static let muted = Color(red: 0.33, green: 0.36, blue: 0.41)
    static let line = Color(red: 0.89, green: 0.90, blue: 0.92)
}

struct FinanceRootView: View {
    @StateObject private var finance = FinanceStore()

    var body: some View {
        NavigationStack {
            FinanceDashboardView(store: finance)
        }
        .tint(FinancePalette.navy)
    }
}

private struct FinanceDashboardView: View {
    @ObservedObject var store: FinanceStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                accountCard
                quickActions
                projectSnapshot
                recentTransactions
                transparency
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 34)
        }
        .background(FinancePalette.ground)
        .navigationBarHidden(true)
        .accessibilityIdentifier("finance.dashboard")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("OMA Finance").font(.system(size: 27, weight: .semibold, design: .rounded))
                Text("Банкинг и бюджет жилья").font(.subheadline).foregroundStyle(FinancePalette.muted)
            }
            Spacer()
            Text(store.state.mode.rawValue)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.white, in: Capsule())
                .accessibilityLabel("Режим: демонстрация")
        }
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack {
                Text(store.state.account.name).font(.subheadline.weight(.medium))
                Spacer()
                Text("Демонстрация").font(.caption.weight(.semibold)).padding(.horizontal, 9).padding(.vertical, 5).background(.white.opacity(0.14), in: Capsule())
            }
            Text(financeMoney(store.state.account.balanceMinor))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .accessibilityLabel("Синтетический баланс \(financeMoney(store.state.account.balanceMinor))")
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Доступно").font(.caption).foregroundStyle(.white.opacity(0.7))
                    Text(financeMoney(store.state.account.availableMinor)).font(.subheadline.weight(.semibold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(store.state.cards.first?.maskedPAN ?? "Карта не создана").font(.subheadline.weight(.semibold))
                    Text(store.state.cards.first?.status.rawValue ?? "—").font(.caption).foregroundStyle(.white.opacity(0.7))
                }
            }
            Text("Синтетические данные. Счёт и карта не принимают и не хранят реальные деньги.")
                .font(.caption).foregroundStyle(.white.opacity(0.72))
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(FinancePalette.navy, in: RoundedRectangle(cornerRadius: 20))
    }

    private var quickActions: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
            NavigationLink { FinancePlaceholder(title: "Мои карты", message: "Управление синтетическими картами") } label: { FinanceAction(icon: "creditcard", title: "Карты") }
            NavigationLink { FinancePlaceholder(title: "Демо-перевод", message: "Реальные деньги не перемещаются") } label: { FinanceAction(icon: "arrow.left.arrow.right", title: "Перевести") }
            NavigationLink { FinancePlaceholder(title: "Демо-пополнение", message: "Будет добавлена только синтетическая операция") } label: { FinanceAction(icon: "plus", title: "Пополнить") }
            NavigationLink { FinancePlaceholder(title: "История", message: "Операции из источника DEMO") } label: { FinanceAction(icon: "clock.arrow.circlepath", title: "История") }
        }
    }

    private var projectSnapshot: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Text("Домашний проект").font(.headline); Spacer(); Text("Полка").font(.subheadline).foregroundStyle(FinancePalette.muted) }
            Text("Остаток плана").font(.caption).foregroundStyle(FinancePalette.muted)
            Text(financeMoney(15_300)).font(.title2.weight(.bold))
            ProgressView(value: 39_700, total: 55_000).tint(FinancePalette.blue)
            HStack {
                NavigationLink("Открыть бюджет") { FinancePlaceholder(title: "Бюджет проекта", message: "Материалы, услуги, доставка и резерв") }
                Spacer()
                NavigationLink("План платежей") { FinancePlaceholder(title: "План платежей", message: "Этапы ремонта и ручные отметки") }
            }.font(.subheadline.weight(.semibold))
        }
        .padding(18).background(.white, in: RoundedRectangle(cornerRadius: 16))
    }

    private var recentTransactions: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack { Text("Последние операции").font(.headline); Spacer(); NavigationLink("Все") { FinancePlaceholder(title: "История", message: "Фильтры и статусы операций") }.font(.subheadline.weight(.semibold)) }
            ForEach(store.state.transactions.prefix(3)) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.kind == .homeProject ? "house" : "cart").frame(width: 28).foregroundStyle(FinancePalette.muted)
                    VStack(alignment: .leading, spacing: 3) { Text(item.counterparty).font(.subheadline.weight(.medium)).lineLimit(1); Text("\(item.status.rawValue) · \(item.source.rawValue)").font(.caption).foregroundStyle(FinancePalette.muted) }
                    Spacer()
                    Text((item.direction == "CREDIT" ? "+" : "−") + financeMoney(item.amountMinor)).font(.subheadline.weight(.semibold)).monospacedDigit()
                }.padding(.vertical, 12)
                if item.id != store.state.transactions.prefix(3).last?.id { Divider().foregroundStyle(FinancePalette.line) }
            }
        }.padding(18).background(.white, in: RoundedRectangle(cornerRadius: 16))
    }

    private var transparency: some View {
        Text("Stage 1 · Неофициальный демонстрационный контур OMA ONE. LIVE заблокирован до договора и технической проверки лицензированного финансового партнёра.")
            .font(.caption).foregroundStyle(FinancePalette.muted).fixedSize(horizontal: false, vertical: true)
    }
}

private struct FinanceAction: View {
    let icon: String
    let title: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 19, weight: .regular)).frame(height: 23)
            Text(title).font(.caption2.weight(.medium)).lineLimit(1).minimumScaleFactor(0.72)
        }
        .foregroundStyle(FinancePalette.ink)
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct FinancePlaceholder: View {
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "building.columns").font(.system(size: 36)).foregroundStyle(FinancePalette.navy)
            Text(title).font(.title2.weight(.semibold))
            Text(message).foregroundStyle(FinancePalette.muted).multilineTextAlignment(.center)
            Text("Демонстрационный контур · не банковская операция").font(.caption).foregroundStyle(FinancePalette.muted)
        }.padding(28).navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }
}
