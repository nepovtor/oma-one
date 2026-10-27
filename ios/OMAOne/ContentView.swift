import SwiftUI
import PhotosUI
import UIKit
import CryptoKit

// MARK: - Demo styling. User supplied reference screenshots are for a hackathon concept, not an official OMA release.
private enum Style {
    // Палитра основана на корпоративных материалах ОМА; проект неофициальный.
    static let blue = Color(red: 0.027, green: 0.373, blue: 0.659)
    static let deepBlue = Color(red: 0.024, green: 0.302, blue: 0.533)
    static let cyan = Color(red: 0.039, green: 0.624, blue: 0.710)
    static let orange = Color(red: 0.784, green: 0.357, blue: 0.153)
    static let ink = Color(red: 0.094, green: 0.196, blue: 0.278)
    static let soft = Color(red: 0.933, green: 0.957, blue: 0.973)
    static let paleBlue = Color(red: 0.910, green: 0.953, blue: 0.984)
    static let paleCyan = Color(red: 0.898, green: 0.969, blue: 0.976)
    static let paleOrange = Color(red: 1.0, green: 0.953, blue: 0.910)
    static let line = Color(red: 0.882, green: 0.910, blue: 0.925)
    static let hero = blue
}

private enum OmaMotion {
    static let change = Animation.spring(response: 0.28, dampingFraction: 0.82)
    static let press = Animation.easeOut(duration: 0.14)
}

private struct OmaPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(reduceMotion ? nil : OmaMotion.press, value: configuration.isPressed)
    }
}

private func categorySymbol(_ category: String) -> String {
    switch category {
    case "Сантехника": "drop"
    case "Инструмент": "hammer"
    case "Мебель": "chair.lounge"
    case "Крепеж": "wrench.adjustable"
    case "Интерьер и отделка": "paintbrush"
    case "Стройматериалы": "square.stack.3d.up"
    case "Благоустройство": "leaf"
    default: "square.grid.2x2"
    }
}

private struct ProductVisual: View {
    let product: Product
    var height: CGFloat = 82
    var radius: CGFloat = 12
    var body: some View {
        Group {
            if let image = UIImage(named: "Product\(product.id.uppercased())") {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: categorySymbol(product.category))
                    .font(.system(size: 31, weight: .light))
                    .foregroundStyle(Style.blue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity).frame(height: height)
        .background(Style.paleBlue)
        .clipShape(RoundedRectangle(cornerRadius: radius))
        .accessibilityLabel("Иллюстрация: \(product.name)")
    }
}

private func productCountText(_ count: Int) -> String {
    let lastTwo = count % 100
    let word: String
    if (11...14).contains(lastTwo) { word = "товаров" }
    else {
        switch count % 10 {
        case 1: word = "товар"
        case 2...4: word = "товара"
        default: word = "товаров"
        }
    }
    return "\(count) \(word)"
}

private struct OmaCardSurface: ViewModifier {
    var radius: CGFloat = 19
    func body(content: Content) -> some View {
        content
            .background(.white, in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius)
                .strokeBorder(Style.line, lineWidth: 1))
    }
}

private struct OmaGlassGroup<Content:View>:View {
    @ViewBuilder let content:()->Content
    var body:some View { content() }
}

private struct OmaTabBarSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.white, in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26)
                .strokeBorder(Style.line.opacity(0.80), lineWidth: 1))
    }
}

private func rub(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(0...2)).grouping(.automatic)) + " BYN"
}

private struct Product: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let price: Double
    let icon: String
    let description: String
    let stock: Int
}

private struct Requirement: Identifiable {
    let productId: String
    let qty: Int
    var id: String { productId }
}

private enum Scenario: String, CaseIterable, Identifiable {
    case faucet, shelf, bathroom, balcony, garden, entry
    var id: String { rawValue }
    var title: String {
        switch self {
        case .faucet: "Починить смеситель"
        case .shelf: "Установить полку"
        case .bathroom: "Обновить ванную"
        case .balcony: "Утеплить балкон"
        case .garden: "Подготовить сад"
        case .entry: "Обустроить прихожую"
        }
    }
    var icon: String {
        switch self {
        case .faucet: "drop.fill"
        case .shelf: "square.stack.3d.up"
        case .bathroom: "shower.fill"
        case .balcony: "house.fill"
        case .garden: "leaf.fill"
        case .entry: "square.grid.2x2.fill"
        }
    }
    var requirements: [Requirement] {
        switch self {
        case .faucet: [Requirement(productId: "p02", qty: 1),Requirement(productId: "p03", qty: 1),Requirement(productId: "p04", qty: 2)]
        case .shelf: [Requirement(productId: "p07", qty: 1),Requirement(productId: "p08", qty: 1),Requirement(productId: "p25", qty: 1)]
        case .bathroom: [Requirement(productId: "p10", qty: 1),Requirement(productId: "p11", qty: 2),Requirement(productId: "p12", qty: 1),Requirement(productId: "p13", qty: 4),Requirement(productId: "p26", qty: 1)]
        case .balcony: [Requirement(productId: "p14", qty: 5),Requirement(productId: "p15", qty: 5),Requirement(productId: "p16", qty: 2),Requirement(productId: "p17", qty: 5)]
        case .garden: [Requirement(productId: "p21", qty: 1),Requirement(productId: "p22", qty: 1),Requirement(productId: "p23", qty: 1),Requirement(productId: "p24", qty: 2)]
        case .entry: [Requirement(productId: "p18", qty: 1),Requirement(productId: "p19", qty: 1),Requirement(productId: "p20", qty: 1)]
        }
    }
    var servicePrice: Double {
        switch self {
        case .faucet: 95
        case .shelf: 65
        case .bathroom: 620
        case .balcony: 590
        case .garden: 140
        case .entry: 95
        }
    }
    var steps: [String] {
        switch self {
        case .faucet: ["Определить модель и причину", "Подобрать совместимые детали", "Безопасно отключить воду", "Выполнить замену", "Проверить соединение"]
        case .shelf: ["Проверить стену и коммуникации", "Выбрать допустимую нагрузку", "Подобрать крепёж", "Установить полку", "Проверить результат"]
        case .bathroom: ["Осмотреть основание", "Проверить трубы", "Подготовить гидроизоляцию", "Уложить плитку", "Проверить результат"]
        case .balcony: ["Уточнить разрешённые работы", "Проверить основание", "Подобрать конструкцию", "Установить материалы", "Проверить результат"]
        case .garden: ["Оценить участок", "Проверить воду", "Установить полив", "Проверить работу", "Сохранить проект"]
        case .entry: ["Измерить помещение", "Проверить коммуникации", "Подобрать модули", "Собрать", "Проверить результат"]
        }
    }
}

private struct SavedProject: Codable, Identifiable {
    var id = UUID()
    var scenario: String
    var amount: Double
    var completed = false
    var proofStatus: String? = nil
    var photoName: String? = nil
    var date = Date()
    var shelf: ShelfProjectData? = nil
}

private struct Category: Identifiable {
    let name: String
    let image: String
    var id: String { name }
}

@MainActor private final class Store: ObservableObject {
    @Published var city: String = UserDefaults.standard.string(forKey: "oma_demo_city") ?? "Минск" {
        didSet { UserDefaults.standard.set(city, forKey: "oma_demo_city") }
    }
    @Published var cart: [String: Int] = UserDefaults.standard.dictionary(forKey: "oma_demo_cart") as? [String: Int] ?? [:] {
        didSet { UserDefaults.standard.set(cart, forKey: "oma_demo_cart") }
    }
    @Published var favorites: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "oma_demo_favs") ?? []) {
        didSet { UserDefaults.standard.set(Array(favorites), forKey: "oma_demo_favs") }
    }
    @Published var owned: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "oma_demo_owned") ?? ["p03", "p25"]) {
        didSet { UserDefaults.standard.set(Array(owned), forKey: "oma_demo_owned") }
    }
    @Published var projects: [SavedProject] = {
        guard let data = UserDefaults.standard.data(forKey: "oma_demo_projects"), let items = try? JSONDecoder().decode([SavedProject].self, from: data) else { return [] }
        return items
    }() { didSet { UserDefaults.standard.set(try? JSONEncoder().encode(projects), forKey: "oma_demo_projects") } }
    @Published var orders: [String] = UserDefaults.standard.stringArray(forKey: "oma_demo_orders") ?? [] {
        didSet { UserDefaults.standard.set(orders, forKey: "oma_demo_orders") }
    }
    @Published var joinedSyncCity = UserDefaults.standard.bool(forKey: "oma_demo_group") {
        didSet { UserDefaults.standard.set(joinedSyncCity, forKey: "oma_demo_group") }
    }
    @Published var votedForge = UserDefaults.standard.bool(forKey: "oma_demo_forge") {
        didSet { UserDefaults.standard.set(votedForge, forKey: "oma_demo_forge") }
    }
    @Published var subscribedPulse = UserDefaults.standard.bool(forKey: "oma_demo_pulse") {
        didSet { UserDefaults.standard.set(subscribedPulse, forKey: "oma_demo_pulse") }
    }
    @Published var demoUserName: String = UserDefaults.standard.string(forKey: "oma_demo_name") ?? "Гость" {
        didSet { UserDefaults.standard.set(demoUserName, forKey: "oma_demo_name") }
    }
    @Published var lastMessage: String = ""
    let products: [Product] = [
        Product(id:"p01",name:"Смеситель кухонный Nova",category:"Сантехника",price:189,icon:"🚰",description:"Хромированный смеситель",stock:46),
        Product(id:"p02",name:"Картридж керамический 35 мм",category:"Сантехника",price:24,icon:"🔩",description:"Проверьте размер и модель",stock:70),
        Product(id:"p03",name:"Лента ФУМ 12 мм",category:"Сантехника",price:6.90,icon:"🧵",description:"Для резьбовых соединений",stock:95),
        Product(id:"p04",name:"Гибкая подводка 50 см",category:"Сантехника",price:16,icon:"💧",description:"Сверьте резьбу",stock:48),
        Product(id:"p05",name:"Набор разводных ключей",category:"Инструмент",price:58,icon:"🔧",description:"Инструмент для дома",stock:33),
        Product(id:"p06",name:"Перфоратор 750 Вт",category:"Инструмент",price:269,icon:"🛠",description:"Для твёрдых оснований",stock:23),
        Product(id:"p07",name:"Полка настенная дуб светлый",category:"Мебель",price:89,icon:"🪵",description:"Ширина 80 см",stock:41),
        Product(id:"p08",name:"Дюбель бетонный 8 мм",category:"Крепеж",price:12,icon:"🔩",description:"Для бетонного основания",stock:99),
        Product(id:"p09",name:"Анкер для гипсокартона",category:"Крепеж",price:16,icon:"📌",description:"Для подходящей нагрузки",stock:74),
        Product(id:"p10",name:"Влагостойкая грунтовка",category:"Интерьер и отделка",price:59,icon:"🎨",description:"Для подготовки основания",stock:35),
        Product(id:"p11",name:"Плиточный клей",category:"Стройматериалы",price:42,icon:"🧱",description:"Проверить совместимость",stock:63),
        Product(id:"p12",name:"Затирка для влажных помещений",category:"Интерьер и отделка",price:32,icon:"✨",description:"Для межплиточных швов",stock:51),
        Product(id:"p13",name:"Плитка белая 30×60",category:"Интерьер и отделка",price:47,icon:"◻️",description:"Цена за м²",stock:83),
        Product(id:"p14",name:"XPS утеплитель 30 мм",category:"Стройматериалы",price:28,icon:"🧊",description:"Для подходящего проекта",stock:69),
        Product(id:"p15",name:"Пароизоляционная мембрана",category:"Стройматериалы",price:18,icon:"〰️",description:"Уточнить конструкцию",stock:52),
        Product(id:"p16",name:"Монтажная пена",category:"Стройматериалы",price:25,icon:"☁️",description:"По инструкции изготовителя",stock:64),
        Product(id:"p17",name:"Отделочная панель",category:"Интерьер и отделка",price:38,icon:"▥",description:"Светлая панель",stock:37),
        Product(id:"p18",name:"Модульная система хранения",category:"Мебель",price:235,icon:"🗄️",description:"Для прихожей",stock:29),
        Product(id:"p19",name:"Крючки настенные",category:"Мебель",price:36,icon:"🪝",description:"Комплект из пяти",stock:79),
        Product(id:"p20",name:"Обувница",category:"Мебель",price:79,icon:"👟",description:"Компактная",stock:39),
        Product(id:"p21",name:"Шланг садовый 20 м",category:"Благоустройство",price:85,icon:"🌱",description:"Для участка",stock:55),
        Product(id:"p22",name:"Комплект капельного полива",category:"Благоустройство",price:125,icon:"💦",description:"Для небольшого участка",stock:32),
        Product(id:"p23",name:"Очиститель для теплицы",category:"Благоустройство",price:26,icon:"🧼",description:"По инструкции",stock:49),
        Product(id:"p24",name:"Грунт универсальный 20 л",category:"Благоустройство",price:21,icon:"🪴",description:"Для выращивания растений",stock:85),
        Product(id:"p25",name:"Защитные очки",category:"Инструмент",price:19,icon:"🥽",description:"Средство защиты",stock:91),
        Product(id:"p26",name:"Санитарный силикон",category:"Сантехника",price:28,icon:"🫧",description:"Для влажных зон",stock:62),
        Product(id:"p27",name:"Ламинат влагостойкий",category:"Интерьер и отделка",price:49,icon:"🪵",description:"Цена за м²",stock:49),
        Product(id:"p28",name:"Подложка под ламинат",category:"Интерьер и отделка",price:12,icon:"📏",description:"Проверить совместимость",stock:71)
    ]
    let categories: [Category] = [
        Category(name:"Акции",image:"Category01"),Category(name:"Интерьер и отделка",image:"Category02"),
        Category(name:"Благоустройство",image:"Category03"),Category(name:"Стройматериалы",image:"Category04"),
        Category(name:"Инструмент",image:"Category05"),Category(name:"Мебель",image:"Category06"),
        Category(name:"Бытовая техника",image:"Category07"),Category(name:"Товары для дома",image:"Category08"),
        Category(name:"Сантехника",image:"Category09"),Category(name:"Электрика",image:"Category10"),
        Category(name:"Инженерные системы",image:"Category11"),Category(name:"Спорт и отдых",image:"Category12"),
        Category(name:"Новый год",image:"Category13"),Category(name:"Крепеж",image:"Category14"),
        Category(name:"Автотовары",image:"Category15"),Category(name:"Электроника",image:"Category16"),
        Category(name:"Товары для детей",image:""),Category(name:"Красота и здоровье",image:"")
    ]
    var cartCount: Int { cart.values.reduce(0,+) }
    var cartTotal: Double { cart.reduce(0.0) { $0 + (product($1.key)?.price ?? 0) * Double($1.value) } }
    func product(_ id: String) -> Product? { products.first { $0.id == id } }
    func add(_ id: String, qty: Int = 1) { guard let p = product(id), qty > 0 else { return }; cart[id] = min(p.stock, (cart[id] ?? 0) + qty); lastMessage = "Добавлено в корзину" }
    func remove(_ id: String) { cart.removeValue(forKey: id) }
    func change(_ id: String, delta: Int) { let count = (cart[id] ?? 0) + delta; if count <= 0 { remove(id) } else { cart[id] = min(product(id)?.stock ?? 100, count) } }
    func toggleFavorite(_ id: String) { if favorites.contains(id) { favorites.remove(id) } else { favorites.insert(id) } }
    func toggleOwned(_ id: String) { if owned.contains(id) { owned.remove(id) } else { owned.insert(id) } }
    func addKit(_ kit: [Requirement], excludeOwned: Bool) {
        // An owned checkbox represents ONE item, not an unlimited stockpile.
        // If a project needs two hoses and one is owned, purchase the other one.
        for req in kit {
            let ownedCount = (excludeOwned && owned.contains(req.productId)) ? 1 : 0
            let toBuy = max(0, req.qty - ownedCount)
            if toBuy > 0 { add(req.productId, qty:toBuy) }
        }
        lastMessage = "Комплект добавлен в корзину с учётом имеющихся единиц"
    }
    func saveVibeProject(amount: Double) {
        if let index = projects.firstIndex(where: { $0.scenario == "vibe-bedroom" }) {
            projects[index].amount = amount
        } else {
            projects.insert(SavedProject(scenario: "vibe-bedroom", amount: amount), at: 0)
        }
        lastMessage = "VIBE-проект сохранён локально в общем разделе «Мой дом»"
    }
    func save(_ scenario: Scenario, amount: Double) {
        projects.insert(SavedProject(scenario:scenario.rawValue,amount:amount),at:0)
        lastMessage = "Проект сохранён в «Мой дом»"
    }
    func saveShelf(_ draft: ShelfProjectData, amount: Double) {
        var copy = draft
        copy.updatedAt = Date()
        if let index = projects.firstIndex(where: { $0.id == draft.id }) {
            // updatedAt alone does not invalidate a completed Proof record.
            var previous = projects[index].shelf
            previous?.updatedAt = copy.updatedAt
            let inputsChanged = previous != copy
            projects[index].shelf = copy
            projects[index].amount = amount
            projects[index].photoName = copy.photoPath
            if inputsChanged {
                projects[index].completed = false
                projects[index].proofStatus = nil
            }
        } else {
            projects.insert(SavedProject(id:copy.id,scenario:Scenario.shelf.rawValue,
                                         amount:amount,photoName:copy.photoPath,shelf:copy),at:0)
        }
        lastMessage = "Проект полки сохранён локально. При изменении параметров подтверждение сбрасывается."
    }
    func complete(_ id: UUID, photo: String? = nil) {
        guard let index = projects.firstIndex(where:{$0.id == id}) else { return }
        if let photo { projects[index].photoName = photo }
        if let shelf = projects[index].shelf {
            var evaluatedShelf = shelf
            if let path = shelf.photoPath, !FileManager.default.fileExists(atPath:path) {
                evaluatedShelf.photoPath = nil
                evaluatedShelf.photoHash = nil
            }
            let catalog = products.map {
                ["id": $0.id, "name": $0.name, "unitPrice": $0.price] as [String:Any]
            }
            let result = EvidenceEngine.shared.run("shelf",input:evaluatedShelf.engineInput(products:catalog))?["result"] as? [String:Any]
            let proof = result?["proof"] as? [String:Any]
            let status = proof?["status"] as? String
            guard result?["readiness"] as? String == ShelfReadiness.candidate.rawValue,
                  (result?["domino"] as? [String:Any])?["valid"] as? Bool == true,
                  status == "SELF_REPORTED" || status == "EVIDENCE_SUBMITTED" else {
                lastMessage = "Сначала проверьте крепёж и завершите все этапы по порядку."
                return
            }
            projects[index].proofStatus = status
        } else {
            projects[index].proofStatus = projects[index].photoName == nil ? "SELF_REPORTED" : "EVIDENCE_SUBMITTED"
        }
        projects[index].completed = true
        lastMessage = projects[index].proofStatus == "EVIDENCE_SUBMITTED"
            ? "Доказательства сохранены. Экспертная проверка НЕ проведена."
            : "Выполнение записано со слов пользователя. Доказательства и экспертная проверка отсутствуют."
    }
    func attachProofPhoto(_ id: UUID, photo: String, hash: String? = nil) {
        guard let index = projects.firstIndex(where:{$0.id == id}) else { return }
        projects[index].photoName = photo
        projects[index].shelf?.photoPath = photo
        if let hash { projects[index].shelf?.photoHash = hash }
        lastMessage = "Фото прикреплено, статус выполнения не менялся"
    }
    var homeTwinShelfEvidence: TwinShelfEvidence {
        guard let project = projects.first(where: { $0.shelf != nil }) else { return .none }
        guard project.completed else { return .planned }
        switch project.proofStatus {
        case "EVIDENCE_SUBMITTED": return .photoSubmitted
        case "SELF_REPORTED": return .selfReported
        default: return .planned
        }
    }

    func checkout() {
        guard cartCount > 0 else { return }
        orders.insert("Демо-заказ №\(1000 + orders.count + 1) · \(rub(cartTotal)) · \(city)", at:0)
        cart = [:]
        lastMessage = "Демо-заказ оформлен, оплата не списывалась"
    }
}

private enum Tab: CaseIterable {
    case home, catalog, cart, favorites, profile
    var title: String {
        switch self {
        case .home: "Главная"
        case .catalog: "Каталог"
        case .cart: "Корзина"
        case .favorites: "Избранное"
        case .profile: "Профиль"
        }
    }
    var icon: String {
        switch self {
        case .home: "square.grid.2x2"
        case .catalog: "magnifyingglass"
        case .cart: "bag"
        case .favorites: "heart"
        case .profile: "person.crop.circle"
        }
    }
}

struct ContentView: View {
    private static var previewTwin: Bool {
        #if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["OMA_TWIN_PREVIEW"] == "1"
        #else
        return false
        #endif
    }
    @StateObject private var store = Store()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var tabPill
    @State private var tab: Tab = .home
    @AppStorage("oma_vibe_enabled") private var vibeEnabled = false
    @State private var showONE = false
    @State private var startPlanner = false
    @State private var startShelf = false
    @State private var startTwin = false
    @State private var showEngine = false
    @State private var category: String? = nil
    @State private var search = ""
    @AppStorage("oma_engine_url") private var backendURL = ""

    var body: some View {
        Group {
        if vibeEnabled {
            VibeExperience(store: store, enabled: $vibeEnabled, classicTab: $tab, showONE: $showONE, startTwin: $startTwin)
        } else {
        VStack(spacing:0) {
            Group {
                switch tab {
                case .home: HomeScreen(store:store, showONE:$showONE, vibeEnabled:$vibeEnabled, startPlanner:$startPlanner, startShelf:$startShelf, startTwin:$startTwin, selectedTab:$tab, category:$category, search:$search)
                case .catalog: CatalogScreen(store:store, category:$category, search:$search)
                case .cart: CartScreen(store:store, selectedTab:$tab)
                case .favorites: FavoritesScreen(store:store, selectedTab:$tab)
                case .profile: ProfileScreen(store:store, showONE:$showONE, showEngine:$showEngine, backendURL:$backendURL)
                }
            }
            .frame(maxWidth:.infinity,maxHeight:.infinity)
            .background(Style.soft)
            HStack(spacing:0) {
                ForEach(Tab.allCases,id:\.self) { item in
                    Button {
                        guard tab != item else { return }
                        withAnimation(reduceMotion ? nil : OmaMotion.change) { tab = item }
                        if item == .catalog { category = nil }
                    } label: {
                        VStack(spacing:5) {
                            ZStack(alignment:.topTrailing) {
                                Image(systemName:item.icon).font(.system(size:24,weight:.light))
                                    .frame(width:39,height:29)
                                if item == .cart && store.cartCount > 0 {
                                    Text("\(store.cartCount)").font(.system(size:9,weight:.bold))
                                        .foregroundColor(.white).padding(4).background(Style.blue).clipShape(Circle())
                                        .offset(x:10,y:-5)
                                        .contentTransition(.numericText())
                                }
                            }
                            Text(item.title).font(.system(size:10,weight:tab == item ? .bold : .medium,design:.rounded)).lineLimit(1)
                        }
                        .foregroundColor(tab == item ? Style.blue : Style.ink)
                        .frame(maxWidth:.infinity,minHeight:54)
                        .background {
                            if tab == item {
                                Capsule().fill(Style.soft.opacity(0.8)).matchedGeometryEffect(id:"selectedTab",in:tabPill)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(OmaPressButtonStyle())
                    .accessibilityLabel(item.title)
                }
            }
            .padding(.horizontal,10).padding(.top,10).padding(.bottom,5)
            .modifier(OmaTabBarSurface())
        }
        } // classic interface
        } // shared mode container
        .preferredColorScheme(.light)
        .onAppear {
            if ContentView.previewTwin {
                startTwin = true
                showONE = true
            }
        }
        .tint(Style.blue)
        .buttonStyle(OmaPressButtonStyle())
        .sheet(isPresented:$showONE,onDismiss:{startPlanner=false;startShelf=false;startTwin=false}) {
            NavigationStack { ONEHub(store:store,showONE:$showONE,startPlanner:$startPlanner,startShelf:$startShelf,startTwin:$startTwin,selectedTab:$tab,showEngine:$showEngine) }
                .tint(Style.blue)
        }
        .sheet(isPresented:$showEngine) {
            NavigationStack {
                VStack {
                    if let url = URL(string:backendURL), let scheme = url.scheme, ["http","https"].contains(scheme) {
                        ServerPreview(url:url)
                    } else {
                        VStack(spacing:14) {
                            Image(systemName:"network.badge.shield.half.filled").font(.system(size:44)).foregroundColor(Style.blue)
                            Text("Укажи адрес сервера ОМА в профиле").font(.headline).multilineTextAlignment(.center)
                            Text("Нативное приложение и все восемь демо-модулей работают без сервера. Полная серверная платформа подключается отдельно.").foregroundColor(.secondary).multilineTextAlignment(.center)
                        }.padding(30)
                    }
                }
                .navigationTitle("Расширенный движок").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement:.topBarTrailing) { Button("Готово") { showEngine = false } } }
            }
        }
    }
}

// MARK: - Original mobile shell / screenshot inspired UI
private struct BrandHeader: View {
    @ObservedObject var store: Store

    var body: some View {
        HStack(spacing: 10) {
            Image("OMALogoReference")
                .resizable()
                .scaledToFit()
                .frame(width: 99, height: 44)
                .accessibilityLabel("ОМА")
            VStack(alignment: .leading, spacing: 2) {
                Text("МОЙ ДОМ")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(Style.blue)
                Text("И РЕМОНТ")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.9)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Menu {
                ForEach(["Минск", "Гомель", "Брест", "Гродно", "Витебск", "Могилёв"], id: \.self) { city in
                    Button(city) { store.city = city }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 13, weight: .medium))
                    Text(store.city)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(Style.blue)
                .padding(.horizontal, 10)
                .frame(minHeight: 39)
                .background(Style.paleBlue, in: Capsule())
            }
            .accessibilityLabel("Город: \(store.city)")
        }
        .padding(.horizontal, 17)
        .frame(height: 76)
        .background(.white)
    }
}

private struct SearchField: View {
    @Binding var text: String
    let onTap: () -> Void
    var body: some View {
        Button(action:onTap) {
            HStack(spacing:12) {
                Image(systemName:"magnifyingglass").font(.system(size:20,weight:.light))
                Text(text.isEmpty ? "Поиск по названию или категории" : text)
                    .lineLimit(1).frame(maxWidth:.infinity,alignment:.leading)
                    .foregroundColor(text.isEmpty ? .gray : Style.ink)
            }
            .font(.system(size:14))
            .foregroundColor(.gray)
            .padding(.horizontal,17).frame(height:49)
            .modifier(OmaCardSurface(radius:16))
        }.buttonStyle(OmaPressButtonStyle())
    }
}

private struct HomeScreen: View {
    @ObservedObject var store: Store
    @Binding var showONE: Bool
    @Binding var vibeEnabled: Bool
    @Binding var startPlanner: Bool
    @Binding var startShelf: Bool
    @Binding var startTwin: Bool
    @Binding var selectedTab: Tab
    @Binding var category: String?
    @Binding var search: String

    var body: some View {
        VStack(spacing: 0) {
            BrandHeader(store: store)
            SearchField(text: $search) {
                category = nil
                selectedTab = .catalog
            }
            .padding(.horizontal, 17)
            .padding(.bottom, 14)
            .background(.white)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Button { withAnimation(.easeInOut(duration: 0.25)) { vibeEnabled = true } } label: {
                        HStack(spacing: 14) {
                            Image("VibeBedroom").resizable().scaledToFill().frame(width: 94, height: 105).clipped().clipShape(RoundedRectangle(cornerRadius: 16))
                            VStack(alignment: .leading, spacing: 7) {
                                Text("ОМА · VIBE").font(.system(size: 11, weight: .bold)).tracking(1.3).foregroundStyle(Color(red: 0.08, green: 0.68, blue: 0.76))
                                Text("Твой дом. Твой вайб.").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(.white)
                                Text("Вдохновляйся и создавай своё пространство").font(.system(size: 12)).foregroundStyle(.white.opacity(0.9))
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right").foregroundStyle(.white)
                        }.padding(13).background(Color(red: 0.188, green: 0.169, blue: 0.482), in: RoundedRectangle(cornerRadius: 22))
                    }
                    .accessibilityIdentifier("oma.vibe.open")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Добро пожаловать домой")
                            .font(.system(size: 23, weight: .bold, design: .rounded))
                            .foregroundStyle(Style.ink)
                        Text("Все задачи, материалы и проекты в одном месте")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 5)

                    Button {
                        startTwin = true
                        showONE = true
                    } label: {
                        HStack(alignment: .center, spacing: 13) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Style.paleCyan)
                                Image(systemName: "cube.transparent.fill")
                                    .font(.system(size: 33, weight: .light))
                                    .foregroundStyle(Style.blue)
                            }
                            .frame(width: 66, height: 70)

                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 6) {
                                    Text("МОЯ КВАРТИРА · 3D")
                                        .font(.system(size: 12, weight: .bold))
                                        .tracking(0.3)
                                    Text("НОВОЕ")
                                        .font(.system(size: 8, weight: .black))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 4)
                                        .background(Style.paleCyan, in: Capsule())
                                }
                                Text("Видимый прогресс ремонта")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                Text("Поворачивайте план, отмечайте сделанное")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Style.blue)
                        }
                        .padding(13)
                        .modifier(OmaCardSurface(radius: 20))
                        .foregroundStyle(Style.ink)
                    }
                    .buttonStyle(OmaPressButtonStyle())
                    .accessibilityIdentifier("homeTwin.open")

                    HStack(spacing: 9) {
                        miniBenefit("checkmark.shield", "Проверка", "Решений")
                        miniBenefit("bag", "Покупки", "По задаче")
                        miniBenefit("house", "Мой дом", "История")
                    }
                    .accessibilityElement(children: .contain)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Что ещё можно сделать?")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundStyle(Style.ink)
                        Button {
                            startPlanner = true
                            showONE = true
                        } label: {
                            categoryRow("Починить смеситель", "Проверить детали и составить смету", "drop")
                        }
                        Button {
                            category = nil
                            selectedTab = .catalog
                        } label: {
                            categoryRow("Найти материалы", "Перейти в демонстрационный каталог", "square.grid.2x2")
                        }
                        if let latest = store.projects.first(where: { $0.shelf != nil }) {
                            Button {
                                startShelf = true
                                showONE = true
                            } label: {
                                categoryRow("Вернуться к полке",
                                            latest.completed ? "Выполнение записано" : "Черновик сохранён", "bookmark")
                            }
                        }
                    }
                    .buttonStyle(OmaPressButtonStyle())

                    Text("Неофициальный конкурсный прототип · цены, остатки и заказы демонстрационные")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(18)
            }
            .background(Style.soft)
        }
    }

    private func miniBenefit(_ symbol: String, _ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Style.cyan)
                .frame(height: 23)
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Style.ink)
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .modifier(OmaCardSurface(radius: 16))
    }

    private func categoryRow(_ title: String, _ detail: String, _ symbol: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 21, weight: .medium))
                .foregroundStyle(Style.blue)
                .frame(width: 47, height: 47)
                .background(Style.paleBlue, in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Style.blue)
        }
        .padding(13)
        .modifier(OmaCardSurface(radius: 18))
        .foregroundStyle(Style.ink)
    }
}


private struct ScreenTitle: View {
    let title:String
    var body: some View { Text(title).font(.system(size:25,weight:.bold,design:.rounded)).foregroundColor(Style.ink).frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,18).frame(height:62).background(Style.soft) }
}

private struct CatalogScreen: View {
    @ObservedObject var store:Store
    @Binding var category:String?
    @Binding var search:String
    private let grid = [GridItem(.flexible(),spacing:12),GridItem(.flexible(),spacing:12)]
    private var availableCategories: [Category] {
        store.categories.filter { entry in store.products.contains { $0.category == entry.name } }
    }
    var body: some View {
        VStack(spacing:0) {
            HStack {
                if category != nil {
                    Button { category = nil; search = "" } label:{Image(systemName:"chevron.left").font(.headline).frame(width:34,height:44)}
                        .accessibilityLabel("Назад к категориям")
                }
                Text(category ?? "Каталог").font(.system(size:25,weight:.bold,design:.rounded)).foregroundColor(Style.ink).lineLimit(1)
                Spacer()
            }.padding(.horizontal,18).frame(height:62).background(Style.soft)
            ScrollView {
                VStack(alignment:.leading,spacing:18) {
                    HStack(spacing:10) {
                        Image(systemName:"magnifyingglass").foregroundColor(.gray)
                        TextField("Поиск по названию или категории",text:$search)
                            .font(.system(size:14)).submitLabel(.search)
                        if !search.isEmpty { Button { search="" } label:{Image(systemName:"xmark.circle.fill").foregroundColor(.gray)} }
                    }.padding(.horizontal,14).frame(height:49).modifier(OmaCardSurface(radius:15))
                    if category == nil && search.isEmpty {
                        Button { category = "Все товары" } label: {
                            HStack(spacing:14) {
                                Image(systemName:"square.grid.2x2").font(.system(size:22)).frame(width:42)
                                VStack(alignment:.leading,spacing:3) {
                                    Text("Все товары").font(.system(size:17,weight:.semibold))
                                    Text("\(productCountText(store.products.count)) в демо-каталоге").font(.system(size:12)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName:"arrow.right").font(.system(size:15,weight:.semibold))
                            }.foregroundStyle(Style.ink).padding(16).modifier(OmaCardSurface(radius:20))
                        }.buttonStyle(OmaPressButtonStyle())
                        Text("Категории").font(.system(size:19,weight:.bold,design:.rounded)).foregroundStyle(Style.ink)
                        LazyVGrid(columns:grid,spacing:12) {
                            ForEach(Array(availableCategories.dropLast().enumerated()),id:\.element.id) { index, entry in
                                Button { category = entry.name } label: {
                                    VStack(alignment:.leading,spacing:10) {
                                        Image(systemName:categorySymbol(entry.name)).font(.system(size:24,weight:.medium))
                                        Spacer(minLength:0)
                                        Text(entry.name).font(.system(size:15,weight:.semibold,design:.rounded)).lineLimit(2)
                                        Text(productCountText(store.products.filter { $0.category == entry.name }.count))
                                            .font(.system(size:12)).foregroundStyle(Style.ink.opacity(0.7))
                                    }
                                    .frame(maxWidth:.infinity,minHeight:105,alignment:.leading).padding(15)
                                    .foregroundStyle(Style.blue)
                                    .background(index.isMultiple(of:2) ? Style.paleBlue : Style.paleOrange,in:RoundedRectangle(cornerRadius:20))
                                }.buttonStyle(OmaPressButtonStyle())
                            }
                        }
                        if let entry = availableCategories.last {
                            Button { category = entry.name } label: {
                                HStack(spacing:16) {
                                    Image(systemName:categorySymbol(entry.name)).font(.system(size:25)).frame(width:38)
                                    Text(entry.name).font(.system(size:16,weight:.semibold))
                                    Spacer()
                                    Text(productCountText(store.products.filter { $0.category == entry.name }.count)).font(.system(size:13))
                                    Image(systemName:"chevron.right").font(.system(size:12,weight:.semibold))
                                }.foregroundStyle(Style.blue).padding(16)
                                    .background(Style.paleBlue,in:RoundedRectangle(cornerRadius:20))
                            }.buttonStyle(OmaPressButtonStyle())
                        }
                    } else {
                        let results = store.products.filter { product in
                            let matchesCategory = (category == nil || category == "Все товары" || product.category == category)
                            let matchesQuery = search.isEmpty || (product.name + " " + product.category).localizedCaseInsensitiveContains(search)
                            return matchesCategory && matchesQuery
                        }
                        Text("\(productCountText(results.count)) · демонстрационные данные")
                            .font(.system(size:13)).foregroundStyle(.secondary)
                        if results.isEmpty {
                            VStack(spacing:12) {
                                Image(systemName:"magnifyingglass").font(.system(size:42)).foregroundColor(Style.blue)
                                Text("В демо-каталоге ничего не найдено").font(.headline).multilineTextAlignment(.center)
                                Button("Показать категории") { category=nil; search="" }.foregroundColor(Style.blue)
                            }.frame(maxWidth:.infinity).padding(.top,60)
                        } else {
                            LazyVGrid(columns:grid,spacing:13) { ForEach(results) { p in ProductCard(p:p,store:store) } }
                        }
                    }
                    Text("Цены и наличие — демонстрационные, заказ не оплачивается")
                        .font(.system(size:12)).foregroundStyle(.secondary).frame(maxWidth:.infinity)
                }.padding(18)
            }
        }
    }
}

private struct ProductCard: View {
    let p:Product
    @ObservedObject var store:Store
    @State private var showingDetail = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        VStack(alignment:.leading,spacing:10) {
            Button { showingDetail = true } label: {
                VStack(alignment:.leading,spacing:10) {
                    ProductVisual(product:p,height:100)
                    Text(p.name).font(.system(size:13,weight:.semibold)).foregroundStyle(Style.ink)
                        .lineLimit(2).frame(height:37,alignment:.topLeading)
                    Text(rub(p.price)).font(.system(size:18,weight:.bold,design:.rounded)).foregroundStyle(Style.ink)
                        .contentTransition(.numericText())
                }.frame(maxWidth:.infinity,alignment:.leading)
            }.buttonStyle(OmaPressButtonStyle())
            HStack(spacing:8) {
                AddToCartButton(p:p,store:store,compact:true)
                Button { withAnimation(reduceMotion ? nil : OmaMotion.change) { store.toggleFavorite(p.id) } } label:{
                    Image(systemName:store.favorites.contains(p.id) ? "heart.fill" : "heart")
                        .frame(width:42,height:42).foregroundColor(Style.orange)
                        .background(Style.paleOrange,in:RoundedRectangle(cornerRadius:10))
                        .scaleEffect(store.favorites.contains(p.id) && !reduceMotion ? 1.07 : 1)
                }.accessibilityLabel(store.favorites.contains(p.id) ? "Убрать из избранного" : "Добавить в избранное")
            }
        }.padding(12).frame(maxWidth:.infinity,alignment:.leading).modifier(OmaCardSurface(radius:20))
            .sheet(isPresented:$showingDetail) {
                NavigationStack { ProductDetailScreen(p:p,store:store) }
                    .presentationDetents([.medium,.large])
            }
    }
}

private struct AddToCartButton: View {
    let p: Product
    @ObservedObject var store: Store
    var compact = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingAdded = false
    @State private var confirmationSequence = 0

    private var atLimit: Bool { (store.cart[p.id] ?? 0) >= p.stock }

    var body: some View {
        Button {
            guard !atLimit else { return }
            withAnimation(reduceMotion ? nil : OmaMotion.change) {
                store.add(p.id)
                showingAdded = true
                confirmationSequence += 1
            }
        } label: {
            HStack(spacing: compact ? 4 : 8) {
                if showingAdded { Image(systemName:"checkmark").fontWeight(.bold) }
                Text(showingAdded ? "Добавлено" : compact ? "В корзину" : "Добавить в корзину")
                    .lineLimit(1)
            }
            .font(.system(size:compact ? 12 : 16,weight:.semibold))
            .frame(maxWidth:.infinity).frame(height:compact ? 42 : 52)
            .foregroundStyle(.white)
            .background(showingAdded ? Style.blue.opacity(0.84) : Style.blue,
                        in:RoundedRectangle(cornerRadius:compact ? 10 : 16))
        }
        .buttonStyle(OmaPressButtonStyle())
        .disabled(atLimit)
        .accessibilityLabel(showingAdded ? "\(p.name) добавлен в корзину" : "Добавить \(p.name) в корзину")
        .accessibilityHint(atLimit ? "Достигнуто демонстрационное наличие" : "")
        .task(id:confirmationSequence) {
            guard confirmationSequence > 0 else { return }
            try? await Task.sleep(nanoseconds:1_300_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : OmaMotion.change) { showingAdded = false }
        }
    }
}

private struct ProductDetailScreen: View {
    let p:Product
    @ObservedObject var store:Store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                ProductVisual(product:p,height:180,radius:22)
                VStack(alignment:.leading,spacing:9) {
                    Text(p.category).font(.system(size:13,weight:.medium)).foregroundStyle(.secondary)
                    Text(p.name).font(.system(size:26,weight:.bold,design:.rounded)).foregroundStyle(Style.ink)
                    Text(rub(p.price)).font(.system(size:26,weight:.bold,design:.rounded)).foregroundStyle(Style.blue)
                    Text(p.description).font(.system(size:15)).foregroundStyle(Style.ink)
                }
                HStack {
                    Text("Демонстрационное наличие")
                    Spacer()
                    Text("\(p.stock) шт.").fontWeight(.semibold)
                }.font(.system(size:14)).padding(16).modifier(OmaCardSurface(radius:18))
                Text("Учебный каталог: параметры, цена и остаток не подтверждены ОМА. Перед реальной покупкой проверьте характеристики и совместимость.")
                    .font(.system(size:12)).foregroundStyle(.secondary)
            }.padding(18)
        }.background(Style.soft)
            .safeAreaInset(edge:.bottom) {
                HStack(spacing:12) {
                    Button { withAnimation(reduceMotion ? nil : OmaMotion.change) { store.toggleFavorite(p.id) } } label: {
                        Image(systemName:store.favorites.contains(p.id) ? "heart.fill" : "heart")
                            .frame(width:52,height:52).foregroundStyle(Style.orange)
                            .modifier(OmaCardSurface(radius:16))
                    }.accessibilityLabel(store.favorites.contains(p.id) ? "Убрать из избранного" : "Добавить в избранное")
                    AddToCartButton(p:p,store:store)
                }.padding(.horizontal,18).padding(.vertical,10).background(.white)
            }
            .navigationTitle("Товар · демо").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement:.topBarTrailing) { Button("Готово") { dismiss() } } }
    }
}

private struct CartScreen: View {
    @ObservedObject var store:Store
    @Binding var selectedTab:Tab
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confirm = false
    var body: some View {
        VStack(spacing:0) {
            ScreenTitle(title:"Корзина")
            if store.cartCount == 0 {
                VStack(spacing:18) {
                    Spacer()
                    Image(systemName:"bag").font(.system(size:48,weight:.ultraLight)).foregroundStyle(Style.blue)
                        .frame(width:100,height:100).background(Style.paleBlue,in:RoundedRectangle(cornerRadius:25))
                    Text("Корзина пока пуста").font(.system(size:22,weight:.bold,design:.rounded)).foregroundColor(Style.ink)
                    Text("В каталоге \(store.products.count) демонстрационных товаров для дома и ремонта")
                        .multilineTextAlignment(.center).font(.system(size:14)).foregroundStyle(.secondary)
                    Button("Перейти в каталог") { selectedTab = .catalog }
                        .font(.system(size:15,weight:.semibold)).foregroundColor(.white)
                        .padding(.horizontal,22).frame(height:48).background(Style.blue,in:Capsule())
                    Spacer()
                }.padding(.horizontal,24).frame(maxWidth:.infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment:.leading,spacing:12) {
                        Text("\(productCountText(store.cartCount)) · демонстрационные данные")
                            .font(.system(size:13)).foregroundStyle(.secondary)
                        ForEach(store.cart.keys.sorted(),id:\.self) { id in
                            if let p = store.product(id) {
                                VStack(alignment:.leading,spacing:12) {
                                    HStack(spacing:13) {
                                        ProductVisual(product:p,height:54).frame(width:54)
                                        VStack(alignment:.leading,spacing:4) {
                                            Text(p.name).font(.system(size:14,weight:.semibold)).lineLimit(2)
                                            Text("\(rub(p.price)) за шт.").font(.system(size:12)).foregroundStyle(.secondary)
                                        }
                                        Spacer(minLength:0)
                                    }
                                    HStack {
                                        HStack(spacing:0) {
                                            Button {withAnimation(reduceMotion ? nil : OmaMotion.change) {store.change(id,delta:-1)}} label:{Image(systemName:"minus").frame(width:44,height:44)}
                                                .accessibilityLabel("Уменьшить количество \(p.name)")
                                            Text("\(store.cart[id] ?? 0)").font(.system(size:15,weight:.semibold))
                                                .monospacedDigit().frame(minWidth:30)
                                                .contentTransition(.numericText())
                                            Button {withAnimation(reduceMotion ? nil : OmaMotion.change) {store.change(id,delta:1)}} label:{Image(systemName:"plus").frame(width:44,height:44)}
                                                .accessibilityLabel("Увеличить количество \(p.name)")
                                        }.foregroundStyle(Style.blue).background(Style.paleBlue,in:Capsule())
                                        Spacer()
                                        Text(rub(p.price * Double(store.cart[id] ?? 0)))
                                            .font(.system(size:16,weight:.bold,design:.rounded)).foregroundStyle(Style.ink)
                                            .contentTransition(.numericText())
                                    }
                                }.padding(14).modifier(OmaCardSurface(radius:20))
                            }
                        }
                    }.padding(18)
                }
                VStack(spacing:12) {
                    HStack {Text("Итого").font(.system(size:16));Spacer();Text(rub(store.cartTotal)).font(.system(size:22,weight:.bold,design:.rounded)).contentTransition(.numericText())}
                    Text("Демо-заказ · оплата и доставка не выполняются").font(.system(size:12)).foregroundColor(.secondary)
                    Button {confirm=true} label:{ Text("Оформить демо-заказ").font(.system(size:16,weight:.semibold)).frame(maxWidth:.infinity).frame(height:50).background(Style.blue,in:RoundedRectangle(cornerRadius:14)).foregroundColor(.white) }
                }.padding(18).background(.white)
                .alert("Подтвердить демо-заказ?",isPresented:$confirm) {
                    Button("Отмена",role:.cancel){}
                    Button("Оформить") { store.checkout() }
                } message: { Text("Это конкурсный прототип, оплата и доставка не выполняются.") }
            }
        }
    }
}

private struct FavoritesScreen: View {
    @ObservedObject var store:Store
    @Binding var selectedTab:Tab
    private let grid = [GridItem(.flexible()),GridItem(.flexible())]
    var body: some View {
        VStack(spacing:0) {
            ScreenTitle(title:"Избранное")
            if store.favorites.isEmpty {
                VStack(spacing:18) {
                    Spacer()
                    Image(systemName:"heart").font(.system(size:48,weight:.ultraLight)).foregroundStyle(Style.blue)
                        .frame(width:100,height:100).background(Style.paleBlue,in:RoundedRectangle(cornerRadius:25))
                    Text("Сохраните то, что понравилось").font(.system(size:22,weight:.bold,design:.rounded)).foregroundColor(Style.ink).multilineTextAlignment(.center)
                    Text("Отмечайте товары сердцем, чтобы быстро вернуться к ним")
                        .font(.system(size:14)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button("Перейти в каталог") {selectedTab = .catalog}
                        .font(.system(size:15,weight:.semibold)).foregroundColor(.white)
                        .padding(.horizontal,22).frame(height:48).background(Style.blue,in:Capsule())
                    Spacer()
                }.padding(.horizontal,17).frame(maxWidth:.infinity)
            } else {
                ScrollView { LazyVGrid(columns:grid,spacing:14) {
                    ForEach(store.products.filter{store.favorites.contains($0.id)}) {p in ProductCard(p:p,store:store)}
                }.padding(17) }
            }
        }
    }
}

private struct ProfileScreen: View {
    @ObservedObject var store:Store
    @Binding var showONE:Bool
    @Binding var showEngine:Bool
    @Binding var backendURL:String
    @AppStorage("oma_evidence_url") private var evidenceURL = ""
    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var showingAbout = false
    var body: some View {
        VStack(spacing:0) {
            ScreenTitle(title:"Профиль")
            ScrollView {
                VStack(alignment:.leading,spacing:14) {
                    HStack {
                        Text("Демонстрационный профиль").font(.system(size:15,weight:.medium))
                        Spacer()
                        Text("\(store.demoUserName)").font(.subheadline.bold()).foregroundColor(Style.blue)
                    }.padding(18).modifier(OmaCardSurface(radius:18))
                    Button {showONE = true} label: {
                        HStack {
                            Image(systemName:"house").font(.system(size:23))
                            VStack(alignment:.leading,spacing:3) {
                                Text("ОМА · Мой дом").font(.system(size:17,weight:.bold))
                                Text("Проекты, 3D-квартира и 8 демо-технологий").font(.system(size:12))
                            }
                            Spacer(); Image(systemName:"chevron.right")
                        }.padding(20).foregroundColor(.white).background(Style.hero,in:RoundedRectangle(cornerRadius:20))
                    }
                    Text("Личный кабинет").font(.system(size:19,weight:.bold,design:.rounded)).foregroundColor(Style.ink).padding(.top,12)
                    profileRow("История заказов","list.bullet.rectangle") {showingHistory=true}
                    profileRow("Моя информация","person.crop.rectangle") {showingSettings=true}
                    Text("О проекте").font(.system(size:19,weight:.bold,design:.rounded)).foregroundColor(Style.ink).padding(.top,18)
                    profileRow("Как работает демо","info.circle") {showingAbout=true}
                    Text("Неофициальный конкурсный прототип · без реальных покупок")
                        .font(.system(size:12)).foregroundColor(.secondary).frame(maxWidth:.infinity).padding(.top,12)
                }.padding(16)
            }
        }.sheet(isPresented:$showingSettings) {
            NavigationStack {
                Form {
                    Section("Профиль") {TextField("Имя",text:$store.demoUserName)}
                    Section("Город") {Picker("Город",selection:$store.city){ForEach(["Минск","Гомель","Брест","Гродно","Витебск","Могилёв"],id:\.self){Text($0).tag($0)}}}
                    Section("Дополнительно") {
                        TextField("URL лаборатории (http://IP:8790/proof.html)",text:$evidenceURL)
                            .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                        TextField("URL backend (http://IP:8787)",text:$backendURL)
                            .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                        Button("Открыть расширенный веб-движок") { showingSettings=false;showEngine=true }
                    }
                    Section(footer:Text("Без сервера работают каталог, корзина, проекты и 8 нативных модулей. Для серверной версии нужен адрес машины в той же Wi-Fi сети, не localhost на iPhone.")) { EmptyView() }
                }.scrollContentBackground(.hidden).background(Style.soft)
                    .navigationTitle("Настройки демо").toolbar {ToolbarItem(placement:.topBarTrailing){Button("Готово"){showingSettings=false}}}
            }
        }.sheet(isPresented:$showingHistory) {
            NavigationStack {
                List {
                    if store.orders.isEmpty { Text("Демо-заказов ещё нет").foregroundColor(.secondary) }
                    ForEach(store.orders,id:\.self) {Text($0)}
                }.scrollContentBackground(.hidden).background(Style.soft).navigationTitle("История заказов")
                    .toolbar {ToolbarItem(placement:.topBarTrailing){Button("Закрыть"){showingHistory=false}}}
            }
        }.sheet(isPresented:$showingAbout) {
            NavigationStack {
                ScrollView {
                    VStack(alignment:.leading,spacing:16) {
                        Text("ОМА помогает пройти путь от домашней задачи до плана и демонстрационной корзины.")
                            .font(.system(size:19,weight:.semibold,design:.rounded))
                        Text("Восемь модулей показывают проверяемые учебные сценарии. Каталог, цены, наличие, услуги и заказы не связаны с официальными системами ОМА.")
                        Text("Нативные сценарии работают без сервера. Для расширенной версии и лаборатории расчётов адреса можно указать в разделе «Моя информация».")
                    }.font(.system(size:15)).foregroundStyle(Style.ink).padding(20)
                }.background(Style.soft).navigationTitle("О демо").navigationBarTitleDisplayMode(.inline)
                    .toolbar {ToolbarItem(placement:.topBarTrailing){Button("Готово"){showingAbout=false}}}
            }
        }
    }
    private func profileRow(_ name:String,_ icon:String,action:@escaping ()->Void) -> some View {
        Button(action:action) {
            HStack(spacing:17){Image(systemName:icon).font(.system(size:22,weight:.light)).frame(width:29);Text(name).font(.system(size:16));Spacer();Image(systemName:"chevron.right").font(.system(size:12)).foregroundColor(.gray)}
                .foregroundColor(Style.ink).frame(height:51).padding(.horizontal,10)
                .modifier(OmaCardSurface(radius:15))
        }.buttonStyle(OmaPressButtonStyle())
    }
}

// MARK: - ОМА native feature hub, backed by persistent demo state
private enum ONEFeature: String, CaseIterable, Identifiable {
    case zerobuy, antifail, domino, synccity, proof, dna, forge, pulse
    var id:String{rawValue}
    var title:String {
        switch self {
        case .zerobuy:"ZeroBuy"
        case .antifail:"AntiFail"
        case .domino:"Domino"
        case .synccity:"SyncCity"
        case .proof:"Proof"
        case .dna:"OMA DNA"
        case .forge:"OMA FORGE"
        case .pulse:"OMA PULSE"
        }
    }
    var description:String {
        switch self {
        case .zerobuy:"Не покупай лишнее"
        case .antifail:"Защита от ошибок"
        case .domino:"Порядок ремонта"
        case .synccity:"Соседские закупки"
        case .proof:"Результат работ"
        case .dna:"Опыт похожих квартир"
        case .forge:"Комплекты по спросу"
        case .pulse:"Сигналы о проблемах"
        }
    }
    var symbol:String {
        switch self {
        case .zerobuy:"arrow.3.trianglepath"
        case .antifail:"shield.checkered"
        case .domino:"square.stack.3d.up.fill"
        case .synccity:"person.3.fill"
        case .proof:"checkmark.seal.fill"
        case .dna:"circle.hexagongrid.fill"
        case .forge:"shippingbox.fill"
        case .pulse:"waveform.path.ecg"
        }
    }
}

private struct ONEHub: View {
    @ObservedObject var store:Store
    @Binding var showONE:Bool
    @Binding var startPlanner:Bool
    @Binding var startShelf:Bool
    @Binding var startTwin:Bool
    @Binding var selectedTab:Tab
    @Binding var showEngine:Bool
    @Environment(\.dismiss) private var dismiss
    @AppStorage("oma_engine_url") private var backendURL = ""
    @AppStorage("oma_evidence_url") private var evidenceURL = ""
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                VStack(alignment:.leading,spacing:13) {
                    Text("ОМА · Мой дом").font(.system(size:14,weight:.semibold))
                    Text("От задачи к готовому плану")
                        .font(.system(size:25,weight:.bold,design:.rounded)).fixedSize(horizontal:false,vertical:true)
                    Text("Подберите материалы, проверьте ограничения и сохраните проект.")
                        .font(.system(size:14)).foregroundStyle(Style.ink.opacity(0.72))
                    NavigationLink { PlannerScreen(store:store,showONE:$showONE,selectedTab:$selectedTab) } label: {
                        HStack {Text("Составить план").font(.system(size:15,weight:.semibold)); Spacer(); Image(systemName:"arrow.right")}
                            .foregroundColor(Style.blue).padding(.horizontal,16).frame(height:46)
                            .background(.white,in:RoundedRectangle(cornerRadius:14))
                    }.padding(.top,3)
                }
                .foregroundColor(Style.ink).padding(19)
                .background(Style.paleBlue)
                .clipShape(RoundedRectangle(cornerRadius:16))
                .overlay(RoundedRectangle(cornerRadius:16).strokeBorder(Style.line, lineWidth:1))
                NavigationLink {
                    ShelfFlowScreen(store:store,showONE:$showONE,selectedTab:$selectedTab,
                                    existing:store.projects.first(where:{$0.shelf != nil})?.shelf)
                } label: {
                    HStack { Text("Хочу повесить полку").font(.system(size:16,weight:.semibold)); Spacer(); Image(systemName:"arrow.right") }
                        .foregroundStyle(Style.blue).padding(17).modifier(OmaCardSurface(radius:18))
                }
                NavigationLink {
                    HomeTwin3DView(shelfEvidence: store.homeTwinShelfEvidence)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "cube.transparent.fill")
                            .font(.system(size: 31))
                            .foregroundStyle(Style.blue)
                            .frame(width: 47, height: 52)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OMA HOME TWIN · 3D")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(Style.ink)
                            Text("Смотрите типовую трёшку и прогресс ремонта")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Style.blue)
                    }
                    .padding(17)
                    .modifier(OmaCardSurface(radius: 20))
                }
                .accessibilityIdentifier("homeTwin.hub")

                HStack {
                    VStack(alignment:.leading,spacing:3) { Text("Мои проекты").font(.system(size:16,weight:.semibold)); Text("Сохранено: \(store.projects.count)").font(.system(size:13)).foregroundColor(.secondary) }
                    Spacer()
                    NavigationLink {ProjectsScreen(store:store,showONE:$showONE,selectedTab:$selectedTab)} label: {
                        Image(systemName:"arrow.right").font(.system(size:15,weight:.semibold)).frame(width:44,height:44)
                    }.accessibilityLabel("Открыть мои проекты")
                }.padding(.horizontal,16).padding(.vertical,10).modifier(OmaCardSurface(radius:20))
                Text("Технологии проекта").font(.system(size:19,weight:.bold,design:.rounded)).foregroundColor(Style.ink)
                OmaGlassGroup {
                    LazyVStack(spacing:10) {
                        ForEach(ONEFeature.allCases) {feature in
                            NavigationLink {FeatureScreen(feature:feature,store:store)} label: {
                                HStack(spacing:14) {
                                    Image(systemName:feature.symbol).font(.system(size:20,weight:.regular))
                                        .foregroundColor(Style.blue).frame(width:30)
                                    VStack(alignment:.leading,spacing:3) {
                                        Text(feature.description).font(.system(size:15,weight:.semibold)).foregroundColor(Style.ink)
                                        Text(feature.title).font(.system(size:12)).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName:"chevron.right").font(.system(size:12,weight:.semibold)).foregroundColor(.secondary)
                                }.padding(15).frame(maxWidth:.infinity,minHeight:66,alignment:.leading)
                                    .modifier(OmaCardSurface(radius:18))
                            }.buttonStyle(OmaPressButtonStyle())
                        }
                    }
                }
                Text("Дополнительно").font(.system(size:19,weight:.bold,design:.rounded)).foregroundColor(Style.ink).padding(.top,6)
                NavigationLink {
                    Group {
                        if let url = URL(string: backendURL), ["http", "https"].contains(url.scheme ?? "") {
                            ServerPreview(url: url)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "server.rack").font(.system(size: 38)).foregroundColor(Style.blue)
                                Text("Сервер не подключён").font(.title3.bold())
                                Text("Для расширенной версии укажи URL сервера в разделе «Профиль → Моя информация». Все нативные функции уже работают локально.")
                                    .multilineTextAlignment(.center).foregroundColor(.secondary)
                            }.padding(24)
                        }
                    }.navigationTitle("Серверная версия")
                } label: {
                    Label("Открыть расширенный движок",systemImage:"network")
                        .frame(maxWidth:.infinity).padding(14).modifier(OmaCardSurface(radius:16))
                }.tint(Style.blue)
                NavigationLink {
                    VStack {
                        if let url = URL(string:evidenceURL), let scheme = url.scheme, ["http","https"].contains(scheme) {
                            ServerPreview(url:url)
                        } else {
                            VStack(spacing:14) {
                                Image(systemName:"checkmark.shield").font(.system(size:40)).foregroundColor(Style.blue)
                                Text("Лаборатория проверяемых расчётов").font(.headline)
                                Text("Запустите npm run evidence на Mac. В разделе «Профиль → Моя информация» укажите http://IP-вашего-Mac:8790/proof.html. На iPhone localhost не работает.")
                                    .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                            }.padding()
                        }
                    }.navigationTitle("Проверка 8 модулей")
                } label: {
                    Label("Проверить расчёты: 8 функций + экономика",systemImage:"checkmark.shield.fill")
                        .frame(maxWidth:.infinity).padding(14).modifier(OmaCardSurface(radius:16))
                }.tint(Style.blue)
                Text("Конкурсный прототип. Товары, цены, группы, сигналы и заказы — демонстрационные. Не связан с официальным аккаунтом ОМА.")
                    .font(.system(size:11)).foregroundColor(.secondary)
            }.padding(16)
        }.background(Style.soft)
            .navigationTitle("ОМА").navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented:$startPlanner) {
                PlannerScreen(store:store,showONE:$showONE,selectedTab:$selectedTab)
            }
            .navigationDestination(isPresented:$startShelf) {
                ShelfFlowScreen(store:store,showONE:$showONE,selectedTab:$selectedTab,
                                existing:store.projects.first(where:{$0.shelf != nil})?.shelf)
            }
            .navigationDestination(isPresented:$startTwin) {
                HomeTwin3DView(shelfEvidence:store.homeTwinShelfEvidence)
            }
            .toolbar {ToolbarItem(placement:.topBarTrailing){Button("Закрыть"){dismiss()}}}
    }
}

private struct PlannerScreen: View {
    @ObservedObject var store:Store
    @Binding var showONE:Bool
    @Binding var selectedTab:Tab
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scenario:Scenario = .faucet
    @State private var budget:Double = 250
    @State private var area:Double = 4
    @State private var hirePro = false
    @State private var useOwned = true
    @State private var substrate = "Бетон"
    @State private var success = false
    @State private var kitAdded = false
    var allCost:Double {scenario.requirements.reduce(0){$0 + (store.product($1.productId)?.price ?? 0) * Double($1.qty)}}
    var materialCost:Double {scenario.requirements.reduce(0){total, req in
        let ownedCount = (useOwned && store.owned.contains(req.productId)) ? 1 : 0
        return total + (store.product(req.productId)?.price ?? 0) * Double(max(0, req.qty - ownedCount))
    }}
    var total:Double { materialCost + (hirePro ? scenario.servicePrice : 0) }
    var wrongMaterial:Bool {scenario == .shelf && substrate == "Гипсокартон"}
    var body: some View {
        Form {
            Section("Ваша задача") {
                Picker("Что хотите сделать",selection:$scenario) {ForEach(Scenario.allCases.filter { $0 != .shelf }){s in Label(s.title,systemImage:s.icon).tag(s)}}
                HStack {Text("Бюджет");Spacer();Text(rub(budget)).fontWeight(.bold)}
                Slider(value:$budget,in:100...3500,step:50).tint(Style.blue)
                if scenario == .shelf {
                    Picker("Материал стены",selection:$substrate) {Text("Бетон").tag("Бетон"); Text("Гипсокартон").tag("Гипсокартон")}
                }
                Toggle("Вычесть то, что есть дома (ZeroBuy)",isOn:$useOwned).tint(Style.blue)
                Toggle("Добавить мастера (условная услуга)",isOn:$hirePro).tint(Style.blue)
            }
            Section("Предварительная смета") {
                HStack {
                    VStack(alignment:.leading,spacing:3) {
                        Text("К покупке и услугам").font(.system(size:14)).foregroundStyle(.secondary)
                        Text(rub(total)).font(.system(size:28,weight:.bold,design:.rounded)).foregroundStyle(Style.blue)
                    }
                    Spacer()
                    Image(systemName:(wrongMaterial || total > budget) ? "exclamationmark.circle" : "checkmark.circle")
                        .font(.system(size:24)).foregroundStyle((wrongMaterial || total > budget) ? Style.orange : Style.blue)
                }.padding(.vertical,5)
                if wrongMaterial {
                    Text("Крепёж не подходит для гипсокартона · комплект заблокирован")
                        .font(.subheadline).foregroundStyle(Style.orange)
                }
                if total > budget {Text("Превышение бюджета на \(rub(total - budget))").foregroundStyle(Style.orange)}
                else {Text("Остаток бюджета: \(rub(budget - total))").foregroundStyle(.secondary)}
                if useOwned {Text("Учтено то, что отмечено дома — не больше 1 шт. каждой позиции").font(.caption).foregroundStyle(.secondary)}
            }
            Section("Материалы · демонстрационные цены") {
                ForEach(scenario.requirements) {req in
                    if let product=store.product(req.productId) {
                        HStack {
                            ProductVisual(product:product,height:42).frame(width:42)
                            VStack(alignment:.leading,spacing:4) {Text(product.name).font(.subheadline);Text("\(req.qty) шт. · \(rub(product.price))").font(.caption).foregroundColor(.secondary)}
                            Spacer()
                            let ownedCount = (useOwned && store.owned.contains(req.productId)) ? 1 : 0
                            VStack(alignment:.trailing,spacing:2) {
                                if ownedCount > 0 {Text("Дома: 1 шт.").font(.caption).foregroundColor(.green)}
                                Text("Купить: \(max(0, req.qty-ownedCount)) шт.").font(.caption).foregroundColor(.secondary)
                                Text(rub(Double(max(0, req.qty-ownedCount))*product.price)).font(.subheadline.bold())
                            }
                        }
                    }
                }
                if hirePro {HStack {Text("Услуга мастера · демо");Spacer();Text(rub(scenario.servicePrice))}}
            }
            Section("AntiFail · проверка ограничений") {
                if wrongMaterial {Label("Выбран дюбель для бетона, но стена из гипсокартона. В демо-каталоге есть анкер для гипсокартона, однако нагрузку и совместимость должен проверить специалист.",systemImage:"exclamationmark.shield.fill").foregroundColor(Style.orange)}
                else {Label("Явного конфликта демонстрационных правил не обнаружено",systemImage:"checkmark.shield.fill").foregroundColor(.green)}
                Text("Совместимость не подтверждена для реального объекта: необходима проверка специалистом.").font(.caption).foregroundColor(.secondary)
            }
            Section("Domino · последовательность работ") {
                ForEach(Array(scenario.steps.enumerated()),id:\.offset){index,step in
                    HStack {Text("\(index + 1)").font(.caption.bold()).foregroundColor(.white).frame(width:24,height:24).background(Style.blue).clipShape(Circle());Text(step).font(.subheadline)}
                }
            }
            Section(footer:Text("Демонстрационный расчёт, не технический проект и не оферта ОМА. Цены, запас и услуги тестовые.")){EmptyView()}
        }.scrollContentBackground(.hidden).background(Style.soft)
            .safeAreaInset(edge:.bottom) {
                VStack(spacing:8) {
                    if wrongMaterial {
                        Text("Сначала проверьте крепёж для гипсокартона")
                            .font(.system(size:12,weight:.medium)).foregroundStyle(Style.orange)
                    }
                    Button {
                        withAnimation(reduceMotion ? nil : OmaMotion.change) {
                            store.addKit(scenario.requirements,excludeOwned:useOwned)
                            kitAdded = true
                        }
                    } label: {
                        Label(kitAdded ? "Комплект добавлен" : "Добавить комплект и открыть корзину",
                              systemImage:kitAdded ? "checkmark" : "bag")
                            .font(.system(size:15,weight:.semibold))
                            .frame(maxWidth:.infinity).frame(height:50)
                            .foregroundStyle(.white).background(Style.blue,in:RoundedRectangle(cornerRadius:14))
                    }.disabled(wrongMaterial || kitAdded).opacity(wrongMaterial ? 0.55 : 1)
                    Button {store.save(scenario,amount:total);success=true} label: {
                        Text("Сохранить проект").font(.system(size:14,weight:.semibold)).frame(height:36)
                    }.disabled(wrongMaterial)
                }.padding(.horizontal,18).padding(.top,10).background(.white)
            }
            .navigationTitle("Решить задачу").navigationBarTitleDisplayMode(.inline)
            .alert("Готово",isPresented:$success) {Button("OK",role:.cancel){}} message:{Text(store.lastMessage)}
            .task(id:kitAdded) {
                guard kitAdded else { return }
                try? await Task.sleep(nanoseconds:520_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(reduceMotion ? nil : OmaMotion.change) {
                    selectedTab = .cart
                    showONE = false
                }
            }
    }
}

private struct ProjectsScreen: View {
    @ObservedObject var store:Store
    @Binding var showONE:Bool
    @Binding var selectedTab:Tab
    var body: some View {
        List {
            NavigationLink {
                HomeTwin3DView(shelfEvidence: store.homeTwinShelfEvidence)
            } label: {
                Label("Открыть мою 3D-квартиру", systemImage: "cube.transparent.fill")
                    .foregroundStyle(Style.blue)
                    .font(.system(size: 16, weight: .semibold))
            }
            if store.projects.isEmpty {Text("Пока нет сохранённых проектов. Начните с раздела «Решить задачу».").foregroundColor(.secondary)}
            ForEach(store.projects) {p in
                Group {
                    if let shelf = p.shelf {
                        NavigationLink {
                            ShelfFlowScreen(store:store,showONE:$showONE,selectedTab:$selectedTab,existing:shelf)
                        } label: {
                            VStack(alignment:.leading,spacing:5) {
                                Text("Установить полку").font(.headline)
                                Text(p.completed ? "Выполнение записано · не проверено специалистом" : "Черновик · продолжить")
                                    .font(.subheadline).foregroundStyle(.secondary)
                                Text("Демо-список: \(rub(p.amount))").font(.caption).foregroundStyle(.secondary)
                            }.padding(.vertical,5)
                        }
                    } else {
                        VStack(alignment:.leading,spacing:9) {
                            HStack {Text(p.scenario == "vibe-bedroom" ? "OMA VIBE · Моя спальня" : (Scenario(rawValue:p.scenario)?.title ?? "Проект")).font(.headline);Spacer();Text(p.completed ? "Выполнен" : "В работе").font(.caption).foregroundColor(p.completed ? .green : Style.blue)}
                            Text("Смета: \(rub(p.amount)) · \(p.date.formatted(date:.abbreviated,time:.omitted))").font(.caption).foregroundColor(.secondary)
                            if let img=p.photoName, let data=try? Data(contentsOf:URL(fileURLWithPath:img)),let photo=UIImage(data:data) {
                                Image(uiImage:photo).resizable().scaledToFit().frame(height:120)
                            }
                        }.padding(.vertical,6)
                    }
                }
            }
        }.scrollContentBackground(.hidden).background(Style.soft).navigationTitle("Мой дом")
    }
}

private struct FeatureScreen: View {
    let feature: ONEFeature
    @ObservedObject var store:Store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scenario:Scenario = .shelf
    @State private var wall = "Бетон"
    @State private var swapped = false
    @State private var roomArea:Double = 4
    @State private var photo:PhotosPickerItem?
    @State private var selectedProject:UUID?
    @State private var status = ""
    @State private var evidenceResult:[String:Any]?
    @State private var evidenceError = false
    @State private var pulseConfirmedReports = 2
    var body: some View {
        Form {
            Section {
                HStack(alignment:.top,spacing:14) {
                    Image(systemName:feature.symbol).font(.system(size:29)).foregroundColor(Style.blue)
                    VStack(alignment:.leading,spacing:6) {
                        Text(feature.title).font(.system(size:27,weight:.black,design:.rounded)).foregroundColor(Style.blue)
                        Text(feature.description).font(.subheadline).foregroundColor(.secondary)
                    }
                }.padding(.vertical,8)
            }
            switch feature {
            case .zerobuy: zeroContent
            case .antifail: antiContent
            case .domino: dominoContent
            case .synccity: syncContent
            case .proof: proofContent
            case .dna: dnaContent
            case .forge: forgeContent
            case .pulse: pulseContent
            }
            Section("Проверка правил на iPhone") {
                Text(evidenceInput == nil
                     ? "Базовый синтетический пример из отчёта. Работает без Mac и сети."
                     : "Расчёт по текущим параметрам экрана. Работает без Mac и сети.")
                    .font(.caption).foregroundColor(.secondary)
                Button {
                    withAnimation(reduceMotion ? nil : OmaMotion.change) {
                        evidenceResult = EvidenceEngine.shared.run(feature.rawValue,input:evidenceInput)
                        evidenceError = evidenceResult == nil
                    }
                } label: {
                    Label("Рассчитать локально",systemImage:"checkmark.shield.fill")
                        .frame(maxWidth:.infinity)
                }
                if evidenceError { Text(EvidenceEngine.shared.loadError ?? "Не удалось выполнить расчёт").foregroundColor(.red) }
                if let evidenceResult {
                    Text(evidenceSummary(evidenceResult)).font(.subheadline.bold()).foregroundColor(Style.blue)
                    if let version = evidenceResult["version"] as? String {
                        Text("Правила: \(version)").font(.caption).foregroundColor(.secondary)
                    }
                    DisclosureGroup("Данные и ограничения") {
                        Text(prettyEvidence(evidenceResult)).font(.system(size:10,design:.monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
            Section(footer:Text("ОМА · рабочий нативный демонстрационный сценарий. Сведения о ценах, соседях, ремонтах и неисправностях являются тестовыми.")) {EmptyView()}
        }
        .scrollContentBackground(.hidden).background(Style.soft)
        .navigationTitle(feature.title).navigationBarTitleDisplayMode(.inline)
        .alert("ОМА",isPresented:Binding(get:{!status.isEmpty},set:{if !$0 {status=""}})) {Button("ОК",role:.cancel){status=""}} message:{Text(status)}
    }
    private var evidenceInput:[String:Any]? {
        switch feature {
        case .zerobuy:
            return ["requirements":scenario.requirements.compactMap { req -> [String:Any]? in
                guard let product = store.product(req.productId) else { return nil }
                return ["id":product.id,"name":product.name,"qty":req.qty,"unitPrice":product.price]
            },"inventory":store.owned.map {["id":$0,"qty":1] as [String:Any]}]
        case .antifail:
            return ["surface":wall == "Гипсокартон" ? "drywall" : "concrete",
                    "fastener":"concrete-anchor","loadKg":8,"verifiedWiring":false]
        case .domino:
            return ["order":swapped ? ["inspect","pipes","tiles","waterproof","finish"] :
                        ["inspect","pipes","waterproof","tiles","finish"]]
        case .synccity:
            let count = store.joinedSyncCity ? 5 : 4
            let requests = (0..<count).map {
                ["id":"request-\($0)","city":store.city,"zone":"demo-zone","slot":"2026-11-04","service":"plumbing"]
            }
            return ["requests":requests,"selectedId":"request-0","sharedTripCost":48,"individualTripCost":24,"minGroup":5]
        case .dna:
            return ["homeType":"panel","room":"bath","area":roomArea,"qtyPerM2":1.1,
                    "templates":[["id":"T-101","homeType":"panel","room":"bath","area":4,"inspection":"professional"]]]
        case .proof:
            guard let id = selectedProject, let project = store.projects.first(where: { $0.id == id }) else { return nil }
            if let shelf = project.shelf { return shelf.proofInput }
            let hash = project.photoName.flatMap { try? Data(contentsOf: URL(fileURLWithPath: $0)) }
                .map { SHA256.hash(data: $0).map { String(format: "%02x", $0) }.joined() }
            return ["projectId":id.uuidString,
                    "steps":[["code":"self_report", "done":project.completed]],
                    "photoHashes":hash.map { [$0] } ?? [], "ownerConsent":false]
        case .forge:
            let count = store.votedForge ? 4 : 3
            let projects = (0..<count).map {
                ["id":"interest-\($0)","userId":"synthetic-\($0)","problem":"small-entry","homeType":"flat","optIn":true] as [String:Any]
            }
            return ["projects":projects,"interestThreshold":4,"skuCosts":[["id":"storage","cost":120]],"assemblyCost":30,"minGrossMargin":0.15]
        case .pulse:
            let reports = (0..<pulseConfirmedReports).map {
                ["userId":"synthetic-\($0)","model":"A35","verifiedByExpert":true] as [String:Any]
            }
            return ["reports":reports,"cohortSize":120,"minCases":3,"minCohort":30,"expertApproved":false]
        }
    }
    private func evidenceSummary(_ output:[String:Any]) -> String {
        guard let result = output["result"] as? [String:Any] else { return "Результат получен" }
        switch feature {
        case .zerobuy: return "К оплате: \(result["after"] ?? "—") BYN · без повторной покупки: \(result["savings"] ?? "—") BYN"
        case .antifail: return "Статус: \(result["status"] ?? "—")"
        case .domino: return (result["valid"] as? Bool == true) ? "Порядок шагов принят" : "Порядок шагов отклонён"
        case .synccity: return "Условная экономия: \(result["savingsPerUser"] ?? 0) BYN на участника"
        case .proof: return "Статус записи: \(result["status"] ?? "—")"
        case .dna: return "Лучшее совпадение: \((result["best"] as? [String:Any])?["score"] ?? "—") / 100"
        case .forge: return "Статус идеи: \(result["status"] ?? "—")"
        case .pulse: return "Автоматических уведомлений: \(result["notificationsSent"] ?? 0)"
        }
    }
    private func prettyEvidence(_ output:[String:Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject:output,options:[.prettyPrinted,.sortedKeys]),
              let text = String(data:data,encoding:.utf8) else { return "" }
        return text
    }
    private var zeroContent:some View {
        Group {
            Section("Домашние запасы") {
                Text("Отмечайте, что уже есть дома. ZeroBuy исключит эти позиции из нового заказа.").font(.caption).foregroundColor(.secondary)
                ForEach(store.products.prefix(12)){p in
                    Button {withAnimation(reduceMotion ? nil : OmaMotion.change) {store.toggleOwned(p.id)}} label:{HStack{Image(systemName:store.owned.contains(p.id) ? "checkmark.circle.fill" : "circle").foregroundColor(store.owned.contains(p.id) ? .green : Style.blue);Text(p.name).foregroundColor(Style.ink);Spacer();Text(rub(p.price)).font(.caption).foregroundColor(.secondary)}}
                }
            }
            Section("Оценка экономии на ремонте") {
                ForEach(Scenario.allCases){s in
                    let saved=s.requirements.filter{store.owned.contains($0.productId)}.reduce(0.0){$0+(store.product($1.productId)?.price ?? 0)*Double(min(1,$1.qty))}
                    HStack{Text(s.title).font(.subheadline);Spacer();Text("−\(rub(saved))").foregroundColor(.green).font(.subheadline.bold())}
                }
            }
        }
    }
    private var antiContent:some View {
        Group {
            Section("Проверка монтажа полки") {
                Picker("Основание",selection:$wall){Text("Бетон").tag("Бетон");Text("Гипсокартон").tag("Гипсокартон")}
                HStack{Text("В комплекте:");Spacer();Text("Бетонные дюбели 8 мм")}
            }
            Section("Результат AntiFail") {
                if wall == "Гипсокартон" {
                    Label("НЕСОВМЕСТИМО: комплектный бетонный дюбель не предназначен для гипсокартона.",systemImage:"exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text("Возможная альтернатива: анкер для гипсокартона (тестовая позиция). Не добавляем автоматически до подтверждения нагрузки и типа конструкции.").font(.caption).foregroundColor(.secondary)
                } else {
                    Label("Материал основания совпадает с назначением крепежа. Нужно также проверить нагрузку, коммуникации и инструкцию.",systemImage:"checkmark.shield.fill").foregroundColor(.green)
                }
            }
        }
    }
    private var dominoContent:some View {
        Group {
            Section("Порядок ремонта ванной") {
                ForEach(Array((["Осмотр и состояние труб","Гидроизоляция","Укладка плитки","Проверка результата"] as [String]).enumerated()),id:\.offset) {i,step in
                    let displayed:[String] = swapped ? ["Осмотр и состояние труб","Укладка плитки","Гидроизоляция","Проверка результата"] : ["Осмотр и состояние труб","Гидроизоляция","Укладка плитки","Проверка результата"]
                    HStack {Text("\(i+1)").frame(width:25,height:25).background(Style.soft).clipShape(Circle());Text(displayed[i])}
                }
                Button(swapped ? "Восстановить порядок" : "Поменять местами 2-й и 3-й этап") {withAnimation(reduceMotion ? nil : OmaMotion.change) {swapped.toggle()}}
            }
            Section("Проверка Domino") {
                if swapped {Label("Ошибка: нельзя укладывать плитку до выполнения предусмотренной проектом гидроизоляции.",systemImage:"xmark.octagon.fill").foregroundColor(.red)}
                else {Label("Базовая последовательность соблюдена. Реальные сроки зависят от материалов и инструкций.",systemImage:"checkmark.circle.fill").foregroundColor(.green)}
            }
        }
    }
    private var syncContent:some View {
        Group {
            Section("Совместный заказ соседей · демо") {
                HStack{Text("Группа: квартал Минск");Spacer();Image(systemName:"person.3.fill").foregroundColor(Style.blue)}
                HStack{Text("Участников");Spacer();Text(store.joinedSyncCity ? "5 из 8" : "4 из 8").fontWeight(.bold)}
                HStack{Text("Категория");Spacer();Text("Сантехника")}
                HStack{Text("Гипотеза экономии доставки");Spacer();Text("до 20 BYN").foregroundColor(.green)}
                Button(store.joinedSyncCity ? "Выйти из группы" : "Присоединиться к группе") {withAnimation(reduceMotion ? nil : OmaMotion.change) {store.joinedSyncCity.toggle()}}
            }
            Section {Text("Реальные совместные доставки требуют согласия всех участников, подтверждения наличия, стоимости логистики и партнёрских условий.").font(.caption).foregroundColor(.secondary)}
        }
    }
    private var proofContent:some View {
        Group {
            Section("Подтверждение результата") {
                if store.projects.isEmpty {
                    Text("Сначала сохраните проект в «Решить задачу».").foregroundColor(.secondary)
                } else {
                    Picker("Проект",selection:$selectedProject){
                        Text("Выберите проект").tag(nil as UUID?)
                        ForEach(store.projects){p in Text(Scenario(rawValue:p.scenario)?.title ?? "Проект").tag(p.id as UUID?)}
                    }
                    PhotosPicker(selection:$photo,matching:.images) {Label("Прикрепить фото результата",systemImage:"photo.on.rectangle")}
                    Text("Без фото сохраняется только отметка со слов пользователя. Фото не подтверждает качество или безопасность работ.")
                        .font(.caption).foregroundColor(.secondary)
                    Button("Подтвердить выполнение проекта") {
                        guard let id=selectedProject else {status="Выберите проект";return}
                        store.complete(id)
                        status="Проект отмечен выполненным. Фото, если выбрано, сохраняется после обработки."
                    }
                    .disabled(selectedProject == nil)
                }
            }
            Section("Результаты") {ForEach(store.projects.filter{$0.completed}){p in Label(Scenario(rawValue:p.scenario)?.title ?? "Проект",systemImage:"checkmark.seal.fill").foregroundColor(.green)}}
        }
        .onChange(of:photo) { item in
            guard let item,let id=selectedProject else{return}
            Task {
                guard let data=try? await item.loadTransferable(type:Data.self),data.count < 12_000_000 else{return}
                let url=FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0].appendingPathComponent("proof-\(id.uuidString).jpg")
                if let image=UIImage(data:data),let converted=image.jpegData(compressionQuality:0.70) {
                    do {
                        try converted.write(to:url,options:.atomic)
                        let hash = SHA256.hash(data:converted).map { String(format:"%02x",$0) }.joined()
                        store.attachProofPhoto(id,photo:url.path,hash:hash)
                        status="Фото прикреплено. Выполнение нужно подтвердить отдельно; экспертной проверки нет."
                    } catch { status="Не удалось сохранить фото" }
                }
            }
        }
    }
    private var dnaContent:some View {
        Group {
            Section("OMA DNA · проверенный шаблон · тестовые данные") {
                Text("Ремонт ванной 4 м² · демонстрационный образец").font(.headline)
                Text("Система адаптирует количество материалов к площади помещения; нужно проверить основания, коммуникации и реальные нормы расхода.").font(.caption).foregroundColor(.secondary)
                HStack{Text("Площадь ванной");Spacer();Text("\(roomArea.formatted(.number.precision(.fractionLength(1)))) м²")}
                Slider(value:$roomArea,in:2...9,step:0.5)
                let tileCost=47*roomArea
                HStack{Text("Плитка · условная стоимость");Spacer();Text(rub(tileCost)).fontWeight(.bold)}
                HStack{Text("Базовые материалы и принадлежности");Spacer();Text(rub(59+84+32+28))}
                HStack{Text("Комплект");Spacer();Text(rub(tileCost+203)).font(.headline).foregroundColor(Style.blue)}
                Button("Взять этот проект за основу") {store.save(.bathroom,amount:tileCost+203);status="Адаптированный проект сохранён. Расходы приблизительные."}
            }
            Section {Text("OMA DNA станет проверенной библиотекой только после получения реальных завершённых проектов с согласиями и проверкой результатов.").font(.caption).foregroundColor(.secondary)}
        }
    }
    private var forgeContent:some View {
        Group {
            Section("OMA FORGE · формирование спроса") {
                Text("Набор «Прихожая 2.0»").font(.headline)
                HStack{Text("Заинтересованных семей");Spacer();Text(store.votedForge ? "39" : "38").font(.title3.bold())}
                HStack{Text("Условная цена");Spacer();Text("990 BYN")}
                ProgressView(value:Double(store.votedForge ? 39 : 38),total:50).tint(Style.blue)
                Button(store.votedForge ? "Отменить интерес" : "Мне интересен такой комплект") {withAnimation(reduceMotion ? nil : OmaMotion.change) {store.votedForge.toggle()}}
            }
            Section {Text("При достижении 50 заявок ОМА могла бы проверить оптовые условия у поставщика. Голоса в демо не являются реальными предзаказами.").font(.caption).foregroundColor(.secondary)}
        }
    }
    private var pulseContent:some View {
        Group {
            Section("OMA PULSE · пример сигнала") {
                Label("Проверка сантехнического соединения",systemImage:"waveform.path.ecg").font(.headline)
                Text("В тестовой базе есть несколько сообщений о похожем компоненте. Это не доказательство дефекта вашей установки.").font(.subheadline)
                HStack{Text("Источник");Spacer();Text("Синтетические записи")}
                HStack{Text("Достоверность");Spacer();Text("Не подтверждена").foregroundColor(.orange)}
                Stepper("Синтетически подтверждённых: \(pulseConfirmedReports)",value:$pulseConfirmedReports,in:0...5)
                Button(store.subscribedPulse ? "Отключить наблюдение" : "Включить наблюдение") {withAnimation(reduceMotion ? nil : OmaMotion.change) {store.subscribedPulse.toggle()}}
            }
            Section("Следующие действия") {
                Label("Проверить маркировку и модель",systemImage:"checkmark.circle")
                Label("При сомнениях обратиться к специалисту",systemImage:"person.crop.circle.badge.questionmark")
                Label("Не выполнять опасные работы по одному уведомлению",systemImage:"exclamationmark.shield")
            }
        }
    }
}

// MARK: - One complete, offline shelf journey. The engine receives this project's inputs,
// never the generic fixture used by the independent technology demonstrations.
private struct ShelfFlowScreen: View {
    @ObservedObject var store: Store
    @Binding var showONE: Bool
    @Binding var selectedTab: Tab
    @State private var draft: ShelfProjectData
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var message = ""
    @AppStorage("oma_shelf_wizard_step") private var currentStep = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(store: Store, showONE: Binding<Bool>, selectedTab: Binding<Tab>, existing: ShelfProjectData?) {
        self.store = store
        _showONE = showONE
        _selectedTab = selectedTab
        _draft = State(initialValue: existing ?? ShelfProjectData())
    }

    private var antiResult: [String: Any]? {
        shelfResult?["antiFail"] as? [String: Any]
    }
    private var catalogInput: [[String: Any]] {
        store.products.map { ["id": $0.id, "name": $0.name, "unitPrice": $0.price] }
    }
    private var shelfResult: [String: Any]? {
        EvidenceEngine.shared.run("shelf", input:draft.engineInput(products:catalogInput))?["result"] as? [String:Any]
    }
    private var readiness: ShelfReadiness {
        ShelfReadiness(rawValue:shelfResult?["readiness"] as? String ?? "") ?? .incomplete
    }
    private var dominoValid: Bool {
        (shelfResult?["domino"] as? [String: Any])?["valid"] as? Bool == true
    }
    private var listProducts: [Product] {
        (shelfResult?["candidateProductIds"] as? [String] ?? []).compactMap(store.product)
    }
    private var zeroResult: [String: Any]? {
        shelfResult?["zeroBuy"] as? [String: Any]
    }
    private var zeroItems: [[String: Any]] { zeroResult?["items"] as? [[String: Any]] ?? [] }
    private var shoppingTotal: Double { (zeroResult?["after"] as? NSNumber)?.doubleValue ?? 0 }
    private var hasSavedProject: Bool { store.projects.contains { $0.id == draft.id } }
    private var isRecorded: Bool { store.projects.first { $0.id == draft.id }?.completed == true }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Повесить полку")
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                            .foregroundStyle(Style.ink)
                        Text("Условия, проверка, комплект, работы и результат — один шаг за раз.")
                            .font(.system(size: 14)).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Image("ProductP07").resizable().scaledToFit()
                        .frame(width: 76, height: 66).padding(6)
                        .background(.white, in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Иллюстрация настенной полки")
                }

                stepProgress
                currentStepContent

                Text("Неофициальный офлайн-прототип. Цены, остатки и заказы демонстрационные. Фото и отметка пользователя не являются экспертной проверкой.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }.padding(18)
        }
        .background(Style.soft)
        .safeAreaInset(edge: .bottom) {
            wizardActions
                .padding(.horizontal, 18).padding(.vertical, 10).background(.white)
        }
        .navigationTitle("Повесить полку").navigationBarTitleDisplayMode(.inline)
        .alert("ОМА", isPresented: Binding(get: { !message.isEmpty }, set: { if !$0 { message = "" } })) {
            Button("Понятно", role: .cancel) { message = "" }
        } message: { Text(message) }
        .onChange(of: selectedPhoto) { item in
            guard let item else { return }
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self), data.count < 12_000_000,
                      let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.75) else {
                    message = "Фото не удалось открыть или оно больше 12 МБ"
                    return
                }
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("shelf-proof-\(draft.id.uuidString).jpg")
                do {
                    try jpeg.write(to: url, options: .atomic)
                    draft.photoPath = url.path
                    draft.photoHash = SHA256.hash(data: jpeg).map { String(format: "%02x", $0) }.joined()
                    saveDraft()
                    message = "Фото сохранено локально. Выполнение ещё не подтверждено."
                } catch { message = "Не удалось сохранить фото на устройстве" }
            }
        }
    }

    private var stepProgress: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { index in
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(index + 1)").font(.system(size: 12, weight: .bold))
                        .foregroundStyle(index <= currentStep ? Style.blue : .secondary)
                    Capsule().fill(index <= currentStep ? Style.cyan : Style.line).frame(height: 3)
                }.accessibilityLabel(["Условия", "Проверка", "Комплект", "Работы и результат"][index])
            }
        }
    }

    @ViewBuilder private var currentStepContent: some View {
        switch currentStep {
        case 0: conditionsStep
        case 1: checksStep
        case 2: kitStep
        default: finishStep
        }
    }

    private var conditionsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Условия", "Сохранённые параметры поступают в локальный расчётный движок")
            Picker("Материал стены", selection: $draft.wall) {
                ForEach(ShelfSurface.allCases, id: \.self) { Text($0.title).tag($0) }
            }.accessibilityIdentifier("shelf.wall")
            Picker("Тип крепежа", selection: $draft.fastener) {
                ForEach(ShelfFastener.allCases, id: \.self) { Text($0.title).tag($0) }
            }.accessibilityIdentifier("shelf.fastener")
            HStack(spacing: 12) {
                numberField("Вес полки", value: $draft.shelfWeightKg)
                numberField("Что поставите", value: $draft.plannedLoadKg)
            }
            Text("Суммарная нагрузка: \(draft.totalLoadKg.formatted(.number.precision(.fractionLength(0...1)))) кг")
                .font(.system(size: 13, weight: .medium)).foregroundStyle(Style.ink)
        }.padding(18).modifier(OmaCardSurface(radius: 16))
    }

    private var checksStep: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionTitle("Проверка", "AntiFail · совместимость крепежа, стены и нагрузки")
            Toggle("Стена осмотрена: нет видимых повреждений", isOn: $draft.wallInspected)
            Toggle("Места скрытых проводов и труб проверены", isOn: $draft.utilitiesChecked)
            Toggle("Инструкция производителя сверена", isOn: $draft.manufacturerInstructionsChecked)
            decisionCard
            Text("Предупреждения остаются видимыми. При статусе blocked комплект сформировать нельзя.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }.tint(Style.blue).padding(18).modifier(OmaCardSurface(radius: 16))
    }

    private var kitStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Комплект и корзина", "ZeroBuy · учёт точного количества вещей дома")
            ForEach(listProducts) { product in
                VStack(spacing: 8) {
                    HStack(spacing: 11) {
                        ProductVisual(product:product,height:54).frame(width:54).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(product.name).font(.system(size: 14, weight: .semibold))
                            Text("\(rub(product.price)) · цена демо").font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    Stepper("Есть дома: \(draft.ownedQuantities[product.id] ?? 0) шт.",
                            value: Binding(get: { draft.ownedQuantities[product.id] ?? 0 },
                                           set: { draft.ownedQuantities[product.id] = $0 }), in: 0...1)
                        .font(.system(size: 13))
                }
            }
            HStack { Text("К покупке · демо"); Spacer(); Text(rub(shoppingTotal)).fontWeight(.bold) }
                .font(.system(size: 17)).foregroundStyle(Style.ink)
            Text("Изменение условий пересчитывает комплект; несовместимый крепёж удаляется перед следующим добавлением.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }.padding(18).modifier(OmaCardSurface(radius: 16))
    }

    private var finishStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Работы и результат", "Domino открывает этап только после обязательных предыдущих")
            ForEach(0..<ShelfProjectData.steps.count, id: \.self) { index in
                let step = ShelfProjectData.steps[index]
                let done = draft.completedStepIDs.contains(step.id)
                let available = done || (EvidenceEngine.shared.canCompleteShelfStep(draft.completedStepIDs, stepID: step.id) ?? false)
                Button {
                    draft.completedStepIDs = EvidenceEngine.shared
                        .toggleShelfStep(draft.completedStepIDs,stepID:step.id) ?? draft.completedStepIDs
                } label: {
                    HStack(spacing: 11) {
                        Image(systemName: done ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(done ? Style.blue : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title).foregroundStyle(Style.ink)
                            Text(available ? "Можно выполнить" : "Сначала завершите предыдущий этап")
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }.frame(minHeight: 44)
                }.disabled(!available).buttonStyle(OmaPressButtonStyle())
            }
            if !dominoValid {
                Text("Порядок ещё не завершён. Зависимый этап нельзя отметить раньше обязательных предыдущих.")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Style.orange)
            }
            Divider()
            sectionTitle("Proof", "Личная запись результата, не проверка специалистом")
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label(draft.hasProofPhoto ? "Заменить фото результата" : "Прикрепить фото результата", systemImage: "photo")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            if draft.hasProofPhoto { Text("Фото сохранено локально на устройстве").font(.system(size: 12)).foregroundStyle(.secondary) }
            Button("Записать выполнение со слов пользователя") {
                saveDraft(); store.complete(draft.id); message = store.lastMessage
            }
            .disabled(readiness != .candidate || !draft.allStepsDone || !dominoValid)
            .font(.system(size: 14, weight: .semibold))
            if isRecorded { Text("Выполнение записано · экспертной проверки нет").foregroundStyle(Style.blue) }
        }.padding(18).modifier(OmaCardSurface(radius: 16))
    }

    private var wizardActions: some View {
        HStack(spacing: 10) {
            if currentStep > 0 {
                Button("Назад") { currentStep -= 1 }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(minWidth: 86, minHeight: 50)
                    .background(Style.paleBlue, in: RoundedRectangle(cornerRadius: 10))
            }
            Button(nextTitle) { advance() }
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 50)
                .foregroundStyle(canAdvance ? .white : Style.ink)
                .background(canAdvance ? Style.cyan : Style.line, in: RoundedRectangle(cornerRadius: 10))
                .disabled(!canAdvance)
                .accessibilityIdentifier("shelf.next")
        }
    }

    private var canAdvance: Bool {
        switch currentStep {
        case 0: return draft.wall != .unknown && draft.fastener != .none && draft.shelfWeightKg > 0 && draft.plannedLoadKg > 0
        case 1: return readiness == .candidate
        case 2: return readiness == .candidate && zeroResult != nil
        default: return true
        }
    }

    private var nextTitle: String {
        switch currentStep {
        case 0: "Далее: проверка"
        case 1: readiness == .blocked ? "Комплект заблокирован" : "Далее: комплект"
        case 2: "Добавить комплект и далее"
        default: hasSavedProject ? "Сохранить изменения" : "Сохранить проект"
        }
    }

    private func advance() {
        saveDraft()
        if currentStep == 2 { addShoppingList(); return }
        if currentStep < 3 { currentStep += 1 }
        else { message = store.lastMessage }
    }

    private func sectionTitle(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(Style.ink)
            Text(detail).font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }

    private func numberField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(title), кг").font(.system(size: 13, weight: .medium)).foregroundStyle(Style.ink)
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(title == "Вес полки" ? "shelf.weight" : "shelf.load")
        }
    }

    private var decisionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch readiness {
            case .incomplete:
                Label("Пока не хватает данных", systemImage: "questionmark.circle")
                    .font(.system(size: 18, weight: .bold)).foregroundStyle(Style.ink)
                Text("Выберите материал стены, укажите вес полки и вещей, затем выберите крепёж для проверки. Черновик можно сохранить сейчас.")
            case .blocked:
                Label("Этот крепёж исключён", systemImage: "exclamationmark.shield.fill")
                    .font(.system(size: 18, weight: .bold)).foregroundStyle(Style.orange)
                Text("Выбранный крепёж не соответствует указанному основанию по демонстрационным правилам. Он не попадёт в список покупок.")
                if draft.wall == .drywall && draft.fastener == .concreteAnchor {
                    Button("Рассмотреть анкер для гипсокартона") { draft.fastener = .drywallAnchor }
                        .font(.system(size: 14, weight: .semibold))
                }
            case .review:
                Label("Нужна дополнительная проверка", systemImage: "exclamationmark.circle")
                    .font(.system(size: 18, weight: .bold)).foregroundStyle(Style.orange)
                Text("Уточните состояние стены, коммуникации и инструкцию крепежа. При большой нагрузке или сомнениях обратитесь к специалисту.")
            case .candidate:
                Label("Есть предварительный вариант", systemImage: "checkmark.circle")
                    .font(.system(size: 18, weight: .bold)).foregroundStyle(Style.blue)
                Text("Демо-правила не нашли явного конфликта. Это не подтверждение безопасного монтажа: параметры крепежа и стены нужно сверить на месте.")
            }
            if draft.totalLoadKg > 15 {
                Text("Суммарная нагрузка выше 15 кг — вне демонстрационного порога, требуется проверка специалиста.")
                    .foregroundStyle(Style.orange)
            }
            Button("Сохранить и уточнить со специалистом") { saveDraft() }
                .font(.system(size: 14, weight: .semibold))
        }
        .font(.system(size: 14)).foregroundStyle(Style.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18).background(Style.paleBlue, in: RoundedRectangle(cornerRadius: 20))
    }

    private func saveDraft() {
        store.saveShelf(draft, amount: shoppingTotal)
        message = store.lastMessage
    }

    private func addShoppingList() {
        guard zeroResult != nil else { message = "Локальный расчёт недоступен"; return }
        // Replace the previous local shelf kit instead of accumulating incompatible quantities.
        ["p07", "p08", "p09", "p25"].forEach(store.remove)
        for item in zeroItems {
            guard let id = item["id"] as? String, let count = (item["toBuy"] as? NSNumber)?.intValue,
                  listProducts.contains(where: { $0.id == id }), count > 0 else { continue }
            store.add(id, qty: count)
        }
        store.saveShelf(draft, amount: shoppingTotal)
        message = "Комплект обновлён с учётом домашних запасов"
        withAnimation(reduceMotion ? nil : OmaMotion.change) { currentStep = 3 }
    }
}


// MARK: - OMA VIBE: separate optional lifestyle mode, connected to the same Store.
// Interior pictures are synthetic references; not a scan, installed design or real catalog.
private enum VibeStyle {
    static let indigo = Color(red: 0.188, green: 0.169, blue: 0.482)
    static let cyan = Color(red: 0.075, green: 0.678, blue: 0.761)
    static let coral = Color(red: 1.0, green: 0.439, blue: 0.345)
    static let cream = Color(red: 0.969, green: 0.961, blue: 0.941)
    static let ink = Color(red: 0.125, green: 0.129, blue: 0.169)
    static let lavender = Color(red: 0.925, green: 0.914, blue: 0.961)
}
private struct VibeExperience: View {
    @ObservedObject var store: Store
    @Binding var enabled: Bool
    @Binding var classicTab: Tab
    @Binding var showONE: Bool
    @Binding var startTwin: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var screen = "welcome"
    @AppStorage("oma_vibe_style") private var chosenStyle = "Soft Loft"
    @AppStorage("oma_vibe_saved") private var vibeSaved = false
    @AppStorage("oma_vibe_nodrill") private var noDrill = true
    @AppStorage("oma_vibe_owned_storage") private var ownedStorage = false

    private var suggested: [Product] {
        ["p18", "p20"].compactMap { store.product($0) }
    }
    private var suggestedTotal: Double {
        suggested.reduce(0) { $0 + (($1.id == "p20" && ownedStorage) ? 0 : $1.price) }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("ОМА").font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(VibeStyle.coral)
                Text("VIBE").font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(VibeStyle.indigo)
                Spacer()
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.24)) { enabled = false; classicTab = .home }
                } label: {
                    Label("Обычный ОМА", systemImage: "arrow.uturn.backward")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(VibeStyle.indigo)
                        .padding(.horizontal, 12).frame(minHeight: 44)
                        .background(.white, in: Capsule())
                }
                .accessibilityIdentifier("oma.vibe.exit")
            }
            .padding(.horizontal, 20).padding(.top, 11).padding(.bottom, 10)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch screen {
                    case "welcome": welcome
                    case "styles": stylesPage
                    case "studio": studioPage
                    case "materials": materialsPage
                    case "projects": projectsPage
                    case "profile": profilePage
                    default: homePage
                    }
                    Text("Неофициальный концепт · визуализация и цены демонстрационные · нет заказа в системах ОМА")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20).padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if screen != "welcome" {
                HStack(spacing: 2) {
                    navButton("house", "VIBE", "home")
                    navButton("sparkles.rectangle.stack", "Стили", "styles")
                    navButton("square.on.square", "Комната", "studio")
                    navButton("bag", "Материалы", "materials")
                    navButton("person", "Профиль", "profile")
                }
                .padding(.horizontal, 8).padding(.vertical, 7)
                .background(.white)
            }
        }
        .background(VibeStyle.cream)
        .tint(VibeStyle.indigo)
        .accessibilityIdentifier("oma.vibe.mode")
    }
    private func go(_ next: String) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) { screen = next }
    }
    private func navButton(_ icon: String, _ title: String, _ target: String) -> some View {
        Button { go(target) } label: {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 19))
                Text(title).font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(screen == target ? VibeStyle.indigo : .gray)
            .frame(maxWidth: .infinity).frame(minHeight: 49)
        }
        .accessibilityLabel(title)
    }
    private func pillButton(_ label: String, _ target: String, coral: Bool = false) -> some View {
        Button { go(target) } label: {
            Text(label).font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white).frame(maxWidth: .infinity).frame(minHeight: 51)
                .background(coral ? VibeStyle.coral : VibeStyle.indigo, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    private func hero(_ image: String, height: CGFloat = 260) -> some View {
        Image(image).resizable().scaledToFill().frame(maxWidth: .infinity)
            .frame(height: height).clipped()
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .accessibilityLabel("Синтетическая интерьерная визуализация, не фотография реальной квартиры")
    }
    private var welcome: some View {
        VStack(alignment: .leading, spacing: 17) {
            Text("НОВЫЙ РЕЖИМ").font(.system(size: 12, weight: .black)).tracking(2)
                .foregroundStyle(VibeStyle.cyan)
            Text("Добро пожаловать\nв свой VIBE ✦")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(VibeStyle.indigo)
                .fixedSize(horizontal: false, vertical: true)
            hero("VibeBedroom", height: 338)
            Text("Не просто выбирай товары. Найди свой стиль и составь понятный план преображения комнаты.")
                .font(.system(size: 16)).foregroundStyle(VibeStyle.ink)
            pillButton("Создать свой вайб →", "home", coral: true)
        }
    }
    private var homePage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Твой дом.\nТвой вайб.")
                .font(.system(size: 39, weight: .heavy, design: .rounded))
                .foregroundStyle(VibeStyle.indigo)
                .fixedSize(horizontal: false, vertical: true)
            ZStack(alignment: .bottomLeading) {
                hero("VibeBedroom", height: 315)
                VStack(alignment: .leading, spacing: 8) {
                    Text("SOFT LOFT / МИНСК").font(.system(size: 11, weight: .bold)).tracking(1)
                    Text("Твоя первая квартира — твоя история")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white).padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 24))
            }
            pillButton("Преобразить мою комнату ✨", "studio", coral: true)
            Text("Идеи для тебя").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(VibeStyle.ink)
            HStack(spacing: 12) {
                Button { go("styles") } label: { smallImageCard("VibeLiving", title: "Найди свой стиль") }
                Button { go("materials") } label: { smallImageCard("VibeBedroom", title: "До своего бюджета") }
            }
        }
    }
    private func smallImageCard(_ image: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(image).resizable().scaledToFill().frame(height: 105).clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Text(title).font(.system(size: 13, weight: .bold)).foregroundStyle(VibeStyle.ink)
        }
        .frame(maxWidth: .infinity).padding(9)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }
    private var stylesPage: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Какой интерьер — твой?")
                .font(.system(size: 31, weight: .heavy, design: .rounded)).foregroundStyle(VibeStyle.indigo)
            Text("Выбери настроение. Мы покажем концептуальный референс и доступные следующие шаги.")
                .font(.subheadline).foregroundStyle(.secondary)
            ForEach(["Soft Loft", "Japandi", "Cozy Minimal", "Scandinavian"], id: \.self) { name in
                Button {
                    chosenStyle = name
                } label: {
                    HStack(spacing: 14) {
                        Image(name == "Soft Loft" ? "VibeBedroom" : "VibeLiving")
                            .resizable().scaledToFill().frame(width: 94, height: 92).clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(name).font(.system(size: 18, weight: .bold))
                            Text(name == chosenStyle ? "Выбрано" : "Посмотреть стиль")
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: name == chosenStyle ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(VibeStyle.indigo)
                    }.padding(10).background(.white, in: RoundedRectangle(cornerRadius: 19))
                        .overlay(RoundedRectangle(cornerRadius: 19).strokeBorder(name == chosenStyle ? VibeStyle.cyan : .clear, lineWidth: 2))
                }
                .foregroundStyle(VibeStyle.ink)
            }
            pillButton("Продолжить с \(chosenStyle)", "studio")
        }
    }
    private var studioPage: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Моя спальня").font(.system(size: 33, weight: .heavy, design: .rounded))
                .foregroundStyle(VibeStyle.indigo)
            HStack {
                tag("13 м²")
                tag("Съёмная квартира")
                tag("Бюджет 1 200 BYN")
            }
            hero("VibeBedroom", height: 315)
            Text("Образ комнаты · \(chosenStyle)")
                .font(.system(size: 20, weight: .bold)).foregroundStyle(VibeStyle.ink)
            Text("Это синтетическая иллюстрация целевого интерьера, а не AI-преображение фотографии твоей комнаты.")
                .font(.system(size: 13)).foregroundStyle(.secondary)
            Toggle("Без сверления и необратимых изменений", isOn: $noDrill)
                .font(.system(size: 14, weight: .semibold))
                .tint(VibeStyle.cyan)
                .padding(14).background(.white, in: RoundedRectangle(cornerRadius: 16))
            pillButton("Составить план и товары", "materials", coral: true)
        }
    }
    private func tag(_ text: String) -> some View {
        Text(text).font(.system(size: 11, weight: .bold))
            .foregroundStyle(VibeStyle.indigo).padding(.horizontal, 10)
            .padding(.vertical, 8).background(.white, in: Capsule())
    }
    private var materialsPage: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Сделать это у себя").font(.system(size: 31, weight: .heavy, design: .rounded))
                .foregroundStyle(VibeStyle.indigo)
            Text("Доступные товары демонстрационного каталога ОМА. Для полного интерьера ассортимент потребуется расширить.")
                .font(.system(size: 13)).foregroundStyle(.secondary)
            HStack {
                Text("Предварительный список").font(.headline)
                Spacer()
                Text(rub(suggestedTotal)).font(.headline).foregroundStyle(VibeStyle.indigo)
            }.padding(15).background(.white, in: RoundedRectangle(cornerRadius: 16))
            Toggle("Обувница уже есть дома (ZeroBuy)", isOn: $ownedStorage)
                .font(.system(size: 13, weight: .medium)).tint(VibeStyle.cyan)
                .padding(14).background(VibeStyle.lavender, in: RoundedRectangle(cornerRadius: 16))
            ForEach(suggested) { product in
                HStack(spacing: 12) {
                    ProductVisual(product: product, height: 82).frame(width: 82)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(product.name).font(.system(size: 14, weight: .bold))
                        Text(rub(product.price)).font(.system(size: 13)).foregroundStyle(VibeStyle.indigo)
                        Button("Добавить в общую корзину") { store.add(product.id) }
                            .font(.system(size: 12, weight: .bold)).foregroundStyle(VibeStyle.coral)
                            .disabled(product.id == "p20" && ownedStorage)
                    }
                    Spacer(minLength: 0)
                }.padding(12).background(.white, in: RoundedRectangle(cornerRadius: 18))
            }
            if noDrill {
                Label("Для съёмной квартиры не предлагаем крепёж без проверки условий. Сверление исключено из этого демонстрационного плана.", systemImage: "checkmark.shield.fill")
                    .font(.system(size: 12)).foregroundStyle(VibeStyle.indigo)
                    .padding(13).background(VibeStyle.lavender, in: RoundedRectangle(cornerRadius: 16))
            }
            Button {
                enabled = false
                classicTab = .cart
            } label: {
                Text("Открыть общую корзину · \(store.cartCount)")
                    .font(.system(size: 15, weight: .bold)).frame(maxWidth: .infinity)
                    .frame(minHeight: 50).foregroundStyle(.white)
                    .background(VibeStyle.indigo, in: RoundedRectangle(cornerRadius: 16))
            }
            Button {
                store.saveVibeProject(amount: suggestedTotal)
                vibeSaved = true
                go("projects")
            } label: {
                Text("Сохранить проект в «Мой дом»").font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity).frame(minHeight: 46)
            }
        }
    }
    private var projectsPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Мой дом").font(.system(size: 33, weight: .heavy, design: .rounded))
                .foregroundStyle(VibeStyle.indigo)
            hero("VibeOverview", height: 240)
            Text("Моя спальня · \(chosenStyle)").font(.system(size: 22, weight: .bold))
            Text(vibeSaved ? "Концептуальный проект сохранён в общем кабинете" : "Начни с выбора стиля и сохрани проект")
                .font(.subheadline).foregroundStyle(.secondary)
            pillButton("Открыть проект", "studio")
            Button {
                startTwin = true
                showONE = true
            } label: {
                Label("Открыть HOME TWIN", systemImage: "house")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity).frame(minHeight: 48)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
            }
            Text("HOME TWIN показывает концептуальные рендеры и локальные отметки. Это не строительная экспертиза.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }
    private var profilePage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Твой профиль").font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(VibeStyle.indigo)
            Text("Один аккаунт, одна корзина и одна история проектов для двух режимов.")
                .font(.subheadline)
            Label("В общей корзине: \(store.cartCount)", systemImage: "bag")
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
            Button("Вернуться в обычный ОМА") { enabled = false; classicTab = .home }
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(minHeight: 52)
                .background(VibeStyle.indigo, in: RoundedRectangle(cornerRadius: 16))
            Button("Посмотреть общий каталог") { enabled = false; classicTab = .catalog }
                .font(.system(size: 15, weight: .semibold)).frame(minHeight: 48)
        }
    }
}
