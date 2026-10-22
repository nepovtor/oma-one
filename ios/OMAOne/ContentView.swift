import SwiftUI
import PhotosUI
import UIKit

// MARK: - Demo styling. User supplied reference screenshots are for a hackathon concept, not an official OMA release.
private enum Style {
    static let blue = Color(red: 0.05, green: 0.29, blue: 0.69)
    static let orange = Color(red: 0.94, green: 0.35, blue: 0.08)
    static let ink = Color(red: 0.08, green: 0.13, blue: 0.20)
    static let soft = Color(red: 0.96, green: 0.97, blue: 0.99)
    static let paleBlue = Color(red: 0.88, green: 0.94, blue: 1.0)
    static let paleOrange = Color(red: 1.0, green: 0.93, blue: 0.87)
    static let line = Color(red: 0.88, green: 0.90, blue: 0.93)
    static let hero = blue
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
    var radius:CGFloat = 19
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(.white,in:RoundedRectangle(cornerRadius:radius))
        } else if #available(iOS 26, *) {
            content.glassEffect(.regular.tint(Style.soft.opacity(0.35)).interactive(),in:.rect(cornerRadius:radius))
        } else {
            content.background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:radius))
                .overlay(RoundedRectangle(cornerRadius:radius).strokeBorder(.white.opacity(0.65)))
        }
    }
}

private struct OmaGlassGroup<Content:View>:View {
    @ViewBuilder let content:()->Content
    var body:some View {
        if #available(iOS 26, *) { GlassEffectContainer(spacing:12) { content() } }
        else { content() }
    }
}

private struct OmaTabBarSurface:ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    func body(content:Content)->some View {
        if reduceTransparency {
            content.background(.white,in:RoundedRectangle(cornerRadius:26))
        } else if #available(iOS 26, *) {
            content.glassEffect(.regular.tint(Style.soft.opacity(0.2)),in:.rect(cornerRadius:26))
        } else {
            content.background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:26))
        }
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
    var photoName: String? = nil
    var date = Date()
}

private struct Category: Identifiable {
    let name: String
    let image: String
    var id: String { name }
}

private final class Store: ObservableObject {
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
    func save(_ scenario: Scenario, amount: Double) {
        projects.insert(SavedProject(scenario:scenario.rawValue,amount:amount),at:0)
        lastMessage = "Проект сохранён в «Мой дом»"
    }
    func complete(_ id: UUID, photo: String? = nil) {
        guard let index = projects.firstIndex(where:{$0.id == id}) else { return }
        projects[index].completed = true
        if let photo { projects[index].photoName = photo }
        lastMessage = "Самостоятельное выполнение записано. Экспертная проверка НЕ проведена."
    }
    func attachProofPhoto(_ id: UUID, photo: String) {
        guard let index = projects.firstIndex(where:{$0.id == id}) else { return }
        projects[index].photoName = photo
        lastMessage = "Фото прикреплено, статус выполнения не менялся"
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
    @StateObject private var store = Store()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var tabPill
    @State private var tab: Tab = .home
    @State private var showONE = false
    @State private var startPlanner = false
    @State private var showEngine = false
    @State private var category: String? = nil
    @State private var search = ""
    @AppStorage("oma_engine_url") private var backendURL = ""

    var body: some View {
        VStack(spacing:0) {
            Group {
                switch tab {
                case .home: HomeScreen(store:store, showONE:$showONE, startPlanner:$startPlanner, selectedTab:$tab, category:$category, search:$search)
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
                        UISelectionFeedbackGenerator().selectionChanged()
                        withAnimation(reduceMotion ? nil : .spring(response:0.34,dampingFraction:0.82)) { tab = item }
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
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.title)
                }
            }
            .padding(.horizontal,10).padding(.top,10).padding(.bottom,5)
            .modifier(OmaTabBarSurface())
            .shadow(color:Style.blue.opacity(0.08),radius:16,y:-4)
        }
        .preferredColorScheme(.light)
        .tint(Style.blue)
        .sheet(isPresented:$showONE,onDismiss:{startPlanner=false}) {
            NavigationStack { ONEHub(store:store,showONE:$showONE,startPlanner:$startPlanner,selectedTab:$tab,showEngine:$showEngine) }
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
                            Text("Укажи адрес сервера OMA ONE в профиле").font(.headline).multilineTextAlignment(.center)
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
        HStack {
            Image("OMALogoReference").resizable().scaledToFit().frame(width:67,height:37)
            Spacer()
            Menu {
                ForEach(["Минск","Гомель","Брест","Гродно","Витебск","Могилёв"],id:\.self) { city in
                    Button(city) { store.city = city }
                }
            } label: {
                HStack(spacing:6) {
                    Image(systemName:"location.north.fill").font(.system(size:15))
                    Text(store.city).font(.system(size:16)).foregroundColor(.black)
                    Image(systemName:"chevron.right").font(.system(size:12,weight:.bold))
                }
            }.tint(.black)
        }.padding(.horizontal,18).frame(height:64).background(.white)
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
        }.buttonStyle(.plain)
    }
}

private struct HomeScreen: View {
    @ObservedObject var store: Store
    @Binding var showONE: Bool
    @Binding var startPlanner: Bool
    @Binding var selectedTab: Tab
    @Binding var category: String?
    @Binding var search: String
    var body: some View {
        VStack(spacing:0) {
            BrandHeader(store:store)
            SearchField(text:$search) { category = nil; selectedTab = .catalog }
                .padding(.horizontal,17).padding(.bottom,16)
                .background(Color.white)
            ScrollView {
                VStack(alignment:.leading,spacing:22) {
                    VStack(alignment:.leading,spacing:5) {
                        Text("Для вашего дома")
                            .font(.system(size:25,weight:.bold,design:.rounded)).foregroundStyle(Style.ink)
                        Text("Покупки и проекты — в одном месте")
                            .font(.system(size:14)).foregroundStyle(.secondary)
                    }
                    Button { UIImpactFeedbackGenerator(style:.light).impactOccurred(); startPlanner = true; showONE = true } label: {
                        VStack(alignment:.leading,spacing:13) {
                            HStack {
                                Text("OMA ONE · Мой дом").font(.system(size:14,weight:.semibold))
                                Spacer()
                                Text("Проекты: \(store.projects.count)")
                                    .font(.system(size:12,weight:.medium)).foregroundStyle(.white.opacity(0.8))
                            }
                            Text("Решите задачу для дома")
                                .font(.system(size:24,weight:.bold,design:.rounded))
                                .multilineTextAlignment(.leading)
                            Text("План, нужные материалы и проверка рисков")
                                .font(.system(size:14)).foregroundStyle(.white.opacity(0.84))
                            HStack {
                                Text("Составить план").font(.system(size:14,weight:.bold))
                                Image(systemName:"arrow.right").font(.system(size:13,weight:.bold))
                            }
                            .foregroundStyle(Style.blue).padding(.horizontal,15).frame(height:38)
                            .background(.white,in:Capsule())
                        }
                        .frame(maxWidth:.infinity,alignment:.leading).padding(20)
                        .foregroundStyle(.white)
                        .background(Style.hero,in:RoundedRectangle(cornerRadius:22))
                    }.buttonStyle(.plain)

                    VStack(alignment:.leading,spacing:12) {
                        Text("Быстрый доступ")
                            .font(.system(size:19,weight:.bold,design:.rounded)).foregroundStyle(Style.ink)
                        OmaGlassGroup {
                            HStack(spacing:12) {
                                quickAction("Каталог","square.grid.2x2",accent:Style.blue) { category=nil; selectedTab = .catalog }
                                quickAction("Корзина · \(store.cartCount)","bag",accent:Style.orange) { selectedTab = .cart }
                            }
                        }
                    }

                    VStack(alignment:.leading,spacing:12) {
                        Text("Начните с нужного")
                            .font(.system(size:19,weight:.bold,design:.rounded)).foregroundStyle(Style.ink)
                        Button { category = "Инструмент"; selectedTab = .catalog } label: {
                            categoryRow("Инструменты","Для ремонта и сборки","hammer")
                        }.buttonStyle(.plain)
                        Button { category = "Сантехника"; selectedTab = .catalog } label: {
                            categoryRow("Сантехника","Для кухни и ванной","drop")
                        }.buttonStyle(.plain)
                    }
                    Text("Неофициальный конкурсный прототип · данные демонстрационные")
                        .font(.system(size:12)).foregroundStyle(.secondary)
                }
                .padding(18)
            }
            .background(Style.soft)
        }
    }
    private func quickAction(_ title:String,_ symbol:String,accent:Color,action:@escaping ()->Void) -> some View {
        Button(action:action) {
            VStack(alignment:.leading,spacing:14) {
                Image(systemName:symbol).font(.system(size:22,weight:.medium)).foregroundStyle(accent)
                Text(title).font(.system(size:15,weight:.semibold,design:.rounded)).lineLimit(1)
            }
            .frame(maxWidth:.infinity,minHeight:66,alignment:.leading)
            .padding(16).modifier(OmaCardSurface(radius:20))
            .foregroundStyle(Style.ink)
        }.buttonStyle(.plain)
    }
    private func categoryRow(_ title:String,_ detail:String,_ symbol:String) -> some View {
        HStack(spacing:15) {
            Image(systemName:symbol).font(.system(size:23,weight:.medium))
                .foregroundStyle(Style.blue).frame(width:38,height:38)
            VStack(alignment:.leading,spacing:4) {
                Text(title).font(.system(size:16,weight:.bold,design:.rounded))
                Text(detail).font(.system(size:12)).foregroundStyle(.secondary)
            }
            Spacer(minLength:0)
            Image(systemName:"chevron.right").font(.system(size:12,weight:.bold)).foregroundStyle(Style.blue)
        }.padding(14).modifier(OmaCardSurface(radius:20)).foregroundStyle(Style.ink)
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
                        }.buttonStyle(.plain)
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
                                }.buttonStyle(.plain)
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
                            }.buttonStyle(.plain)
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
    var body: some View {
        VStack(alignment:.leading,spacing:10) {
            Button { showingDetail = true } label: {
                VStack(alignment:.leading,spacing:10) {
                    Image(systemName:categorySymbol(p.category))
                        .font(.system(size:34,weight:.light)).foregroundStyle(Style.blue)
                        .frame(maxWidth:.infinity).frame(height:82)
                        .background(Style.paleBlue,in:RoundedRectangle(cornerRadius:12))
                    Text(p.name).font(.system(size:13,weight:.semibold)).foregroundStyle(Style.ink)
                        .lineLimit(2).frame(height:37,alignment:.topLeading)
                    Text(rub(p.price)).font(.system(size:18,weight:.bold,design:.rounded)).foregroundStyle(Style.ink)
                        .contentTransition(.numericText())
                }.frame(maxWidth:.infinity,alignment:.leading)
            }.buttonStyle(.plain)
            HStack(spacing:8) {
                Button { store.add(p.id); UIImpactFeedbackGenerator(style:.light).impactOccurred() } label:{
                    Text("В корзину").font(.system(size:12,weight:.semibold))
                        .frame(maxWidth:.infinity).frame(height:42).foregroundColor(.white)
                        .background(Style.blue,in:RoundedRectangle(cornerRadius:10))
                }.accessibilityLabel("Добавить \(p.name) в корзину")
                Button { store.toggleFavorite(p.id) } label:{
                    Image(systemName:store.favorites.contains(p.id) ? "heart.fill" : "heart")
                        .frame(width:42,height:42).foregroundColor(Style.orange)
                        .background(Style.paleOrange,in:RoundedRectangle(cornerRadius:10))
                }.accessibilityLabel(store.favorites.contains(p.id) ? "Убрать из избранного" : "Добавить в избранное")
            }
        }.padding(12).frame(maxWidth:.infinity,alignment:.leading).modifier(OmaCardSurface(radius:20))
            .sheet(isPresented:$showingDetail) {
                NavigationStack { ProductDetailScreen(p:p,store:store) }
                    .presentationDetents([.medium,.large])
            }
    }
}

private struct ProductDetailScreen: View {
    let p:Product
    @ObservedObject var store:Store
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                Image(systemName:categorySymbol(p.category))
                    .font(.system(size:46,weight:.ultraLight)).foregroundStyle(Style.blue)
                    .frame(maxWidth:.infinity).frame(height:104)
                    .background(Style.paleBlue,in:RoundedRectangle(cornerRadius:22))
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
                    Button { store.toggleFavorite(p.id) } label: {
                        Image(systemName:store.favorites.contains(p.id) ? "heart.fill" : "heart")
                            .frame(width:52,height:52).foregroundStyle(Style.orange)
                            .modifier(OmaCardSurface(radius:16))
                    }.accessibilityLabel(store.favorites.contains(p.id) ? "Убрать из избранного" : "Добавить в избранное")
                    Button { store.add(p.id); UIImpactFeedbackGenerator(style:.light).impactOccurred() } label: {
                        Text("Добавить в корзину").font(.system(size:16,weight:.semibold))
                            .frame(maxWidth:.infinity).frame(height:52).foregroundStyle(.white)
                            .background(Style.blue,in:RoundedRectangle(cornerRadius:16))
                    }
                }.padding(.horizontal,18).padding(.vertical,10).background(.white)
            }
            .navigationTitle("Товар · демо").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement:.topBarTrailing) { Button("Готово") { dismiss() } } }
    }
}

private struct CartScreen: View {
    @ObservedObject var store:Store
    @Binding var selectedTab:Tab
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
                                        Image(systemName:categorySymbol(p.category)).font(.system(size:25,weight:.light))
                                            .foregroundStyle(Style.blue).frame(width:54,height:54)
                                            .background(Style.paleBlue,in:RoundedRectangle(cornerRadius:12))
                                        VStack(alignment:.leading,spacing:4) {
                                            Text(p.name).font(.system(size:14,weight:.semibold)).lineLimit(2)
                                            Text("\(rub(p.price)) за шт.").font(.system(size:12)).foregroundStyle(.secondary)
                                        }
                                        Spacer(minLength:0)
                                    }
                                    HStack {
                                        HStack(spacing:0) {
                                            Button {store.change(id,delta:-1)} label:{Image(systemName:"minus").frame(width:44,height:44)}
                                                .accessibilityLabel("Уменьшить количество \(p.name)")
                                            Text("\(store.cart[id] ?? 0)").font(.system(size:15,weight:.semibold))
                                                .monospacedDigit().frame(minWidth:30)
                                            Button {store.change(id,delta:1)} label:{Image(systemName:"plus").frame(width:44,height:44)}
                                                .accessibilityLabel("Увеличить количество \(p.name)")
                                        }.foregroundStyle(Style.blue).background(Style.paleBlue,in:Capsule())
                                        Spacer()
                                        Text(rub(p.price * Double(store.cart[id] ?? 0)))
                                            .font(.system(size:16,weight:.bold,design:.rounded)).foregroundStyle(Style.ink)
                                    }
                                }.padding(14).modifier(OmaCardSurface(radius:20))
                            }
                        }
                    }.padding(18)
                }
                VStack(spacing:12) {
                    HStack {Text("Итого").font(.system(size:16));Spacer();Text(rub(store.cartTotal)).font(.system(size:22,weight:.bold,design:.rounded))}
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
                                Text("OMA ONE · Мой дом").font(.system(size:17,weight:.bold))
                                Text("Планы, проекты и 8 демо-технологий").font(.system(size:12))
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
                        Text("OMA ONE помогает пройти путь от домашней задачи до плана и демонстрационной корзины.")
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
        }.buttonStyle(.plain)
    }
}

// MARK: - OMA ONE native feature hub, backed by persistent demo state
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
    @Binding var selectedTab:Tab
    @Binding var showEngine:Bool
    @Environment(\.dismiss) private var dismiss
    @AppStorage("oma_engine_url") private var backendURL = ""
    @AppStorage("oma_evidence_url") private var evidenceURL = ""
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                VStack(alignment:.leading,spacing:13) {
                    Text("OMA ONE · Мой дом").font(.system(size:14,weight:.semibold))
                    Text("От задачи к готовому плану")
                        .font(.system(size:25,weight:.bold,design:.rounded)).fixedSize(horizontal:false,vertical:true)
                    Text("Подберите материалы, проверьте ограничения и сохраните проект.")
                        .font(.system(size:14)).foregroundStyle(.white.opacity(0.85))
                    NavigationLink { PlannerScreen(store:store,showONE:$showONE,selectedTab:$selectedTab) } label: {
                        HStack {Text("Составить план").font(.system(size:15,weight:.semibold)); Spacer(); Image(systemName:"arrow.right")}
                            .foregroundColor(Style.blue).padding(.horizontal,16).frame(height:46)
                            .background(.white,in:RoundedRectangle(cornerRadius:14))
                    }.padding(.top,3)
                }
                .foregroundColor(.white).padding(19)
                .background(Style.hero)
                .clipShape(RoundedRectangle(cornerRadius:22))
                HStack {
                    VStack(alignment:.leading,spacing:3) { Text("Мои проекты").font(.system(size:16,weight:.semibold)); Text("Сохранено: \(store.projects.count)").font(.system(size:13)).foregroundColor(.secondary) }
                    Spacer()
                    NavigationLink {ProjectsScreen(store:store)} label: {
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
                                        Text(feature.title).font(.system(size:15,weight:.semibold)).foregroundColor(Style.ink)
                                        Text(feature.description).font(.system(size:12)).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName:"chevron.right").font(.system(size:12,weight:.semibold)).foregroundColor(.secondary)
                                }.padding(15).frame(maxWidth:.infinity,minHeight:66,alignment:.leading)
                                    .modifier(OmaCardSurface(radius:18))
                            }.buttonStyle(.plain)
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
                                Text("Запустите node proof-server.mjs на Mac. В разделе «Профиль → Моя информация» укажите http://IP-вашего-Mac:8790/proof.html. На iPhone localhost не работает.")
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
            .navigationTitle("OMA ONE").navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented:$startPlanner) {
                PlannerScreen(store:store,showONE:$showONE,selectedTab:$selectedTab)
            }
            .toolbar {ToolbarItem(placement:.topBarTrailing){Button("Закрыть"){dismiss()}}}
    }
}

private struct PlannerScreen: View {
    @ObservedObject var store:Store
    @Binding var showONE:Bool
    @Binding var selectedTab:Tab
    @State private var scenario:Scenario = .faucet
    @State private var budget:Double = 250
    @State private var area:Double = 4
    @State private var hirePro = false
    @State private var useOwned = true
    @State private var substrate = "Бетон"
    @State private var success = false
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
                Picker("Что хотите сделать",selection:$scenario) {ForEach(Scenario.allCases){s in Label(s.title,systemImage:s.icon).tag(s)}}
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
                            Image(systemName:categorySymbol(product.category)).foregroundStyle(Style.blue).frame(width:26)
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
                        store.addKit(scenario.requirements,excludeOwned:useOwned)
                        selectedTab = .cart
                        showONE = false
                    } label: {
                        Label("Добавить комплект и открыть корзину",systemImage:"bag")
                            .font(.system(size:15,weight:.semibold))
                            .frame(maxWidth:.infinity).frame(height:50)
                            .foregroundStyle(.white).background(Style.blue,in:RoundedRectangle(cornerRadius:14))
                    }.disabled(wrongMaterial).opacity(wrongMaterial ? 0.55 : 1)
                    Button {store.save(scenario,amount:total);success=true} label: {
                        Text("Сохранить проект").font(.system(size:14,weight:.semibold)).frame(height:36)
                    }.disabled(wrongMaterial)
                }.padding(.horizontal,18).padding(.top,10).background(.white)
            }
            .navigationTitle("Решить задачу").navigationBarTitleDisplayMode(.inline)
            .alert("Готово",isPresented:$success) {Button("OK",role:.cancel){}} message:{Text(store.lastMessage)}
    }
}

private struct ProjectsScreen: View {
    @ObservedObject var store:Store
    var body: some View {
        List {
            if store.projects.isEmpty {Text("Пока нет сохранённых проектов. Начните с раздела «Решить задачу».").foregroundColor(.secondary)}
            ForEach(store.projects) {p in
                VStack(alignment:.leading,spacing:9) {
                    HStack {Text(Scenario(rawValue:p.scenario)?.title ?? "Проект").font(.headline);Spacer();Text(p.completed ? "Выполнен" : "В работе").font(.caption).foregroundColor(p.completed ? .green : Style.blue)}
                    Text("Смета: \(rub(p.amount)) · \(p.date.formatted(date:.abbreviated,time:.omitted))").font(.caption).foregroundColor(.secondary)
                    if let img=p.photoName, let data=try? Data(contentsOf:URL(fileURLWithPath:img)),let photo=UIImage(data:data) {
                        Image(uiImage:photo).resizable().scaledToFit().frame(height:120)
                    }
                }.padding(.vertical,6)
            }
        }.scrollContentBackground(.hidden).background(Style.soft).navigationTitle("Мой дом")
    }
}

private struct FeatureScreen: View {
    let feature: ONEFeature
    @ObservedObject var store:Store
    @State private var scenario:Scenario = .shelf
    @State private var wall = "Бетон"
    @State private var swapped = false
    @State private var roomArea:Double = 4
    @State private var photo:PhotosPickerItem?
    @State private var selectedProject:UUID?
    @State private var status = ""
    @State private var evidenceResult:[String:Any]?
    @State private var evidenceError = false
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
                    evidenceResult = EvidenceEngine.shared.run(feature.rawValue,input:evidenceInput)
                    evidenceError = evidenceResult == nil
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
            Section(footer:Text("OMA ONE · рабочий нативный демонстрационный сценарий. Сведения о ценах, соседях, ремонтах и неисправностях являются тестовыми.")) {EmptyView()}
        }
        .scrollContentBackground(.hidden).background(Style.soft)
        .navigationTitle(feature.title).navigationBarTitleDisplayMode(.inline)
        .alert("OMA ONE",isPresented:Binding(get:{!status.isEmpty},set:{if !$0 {status=""}})) {Button("ОК",role:.cancel){status=""}} message:{Text(status)}
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
        case .dna:
            return ["homeType":"panel","room":"bath","area":roomArea,"qtyPerM2":1.1,
                    "templates":[["id":"T-101","homeType":"panel","room":"bath","area":4,"inspection":"professional"]]]
        default: return nil // Explicit synthetic fixture for modules without equivalent local inputs.
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
                    Button {store.toggleOwned(p.id)} label:{HStack{Image(systemName:store.owned.contains(p.id) ? "checkmark.circle.fill" : "circle").foregroundColor(store.owned.contains(p.id) ? .green : Style.blue);Text(p.name).foregroundColor(Style.ink);Spacer();Text(rub(p.price)).font(.caption).foregroundColor(.secondary)}}
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
                Button(swapped ? "Восстановить порядок" : "Поменять местами 2-й и 3-й этап") {swapped.toggle()}
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
                Button(store.joinedSyncCity ? "Выйти из группы" : "Присоединиться к группе") {store.joinedSyncCity.toggle()}
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
                    try? converted.write(to:url,options:.atomic)
                    store.attachProofPhoto(id,photo:url.path)
                    status="Фото прикреплено. Выполнение нужно подтвердить отдельно; экспертной проверки нет."
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
                Button(store.votedForge ? "Отменить интерес" : "Мне интересен такой комплект") {store.votedForge.toggle()}
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
                Button(store.subscribedPulse ? "Отключить наблюдение" : "Включить наблюдение") {store.subscribedPulse.toggle()}
            }
            Section("Следующие действия") {
                Label("Проверить маркировку и модель",systemImage:"checkmark.circle")
                Label("При сомнениях обратиться к специалисту",systemImage:"person.crop.circle.badge.questionmark")
                Label("Не выполнять опасные работы по одному уведомлению",systemImage:"exclamationmark.shield")
            }
        }
    }
}
