import SwiftUI
import SceneKit
import PhotosUI
import UIKit

private enum TwinViewMode: String, CaseIterable {
    case overview, interior
}

// Interactive SceneKit rendering of the fixed, synthetic TwinPlan layout.
// Private reference photos are never used to reconstruct geometry.
struct HomeTwin3DView: View {
    let shelfEvidence: TwinShelfEvidence

    @State private var apartment = TwinApartment.load()
    @State private var selectedRoomID: UUID?
    @State private var showGoal = true
    @State private var viewMode: TwinViewMode = {
        #if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["OMA_TWIN_INTERIOR_PREVIEW"] == "1" ? .interior : .overview
        #else
        return .overview
        #endif
    }()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoMessage = ""

    private let dark = Color(red: 0.06, green: 0.14, blue: 0.25)
    private let accent = Color(red: 0.12, green: 0.42, blue: 0.88)

    private var selectedRoom: TwinRoom? {
        apartment.rooms.first(where: { $0.id == selectedRoomID }) ?? apartment.rooms.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                intro
                model
                planDimensions
                rooms
                if let room = selectedRoom { roomDetails(room) }
                shelfDetails
                Text("Синтетический пример планировки: размеры в мм условные, для просмотра, не для закупки или строительных работ. Фото остаются на устройстве. Отметка задачи и фото не означают экспертную проверку ремонта.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 3)
            }
            .padding(16)
        }
        .background(Color(red: 0.96, green: 0.97, blue: 0.99))
        .navigationTitle("Мой дом · 3D")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedRoomID == nil { selectedRoomID = apartment.rooms.first?.id }
        }
        .onChange(of: apartment) { updated in updated.save() }
        .onChange(of: selectedPhoto) { item in
            guard let item, let id = selectedRoom?.id else { return }
            Task { await importPhoto(item, for: id) }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("OMA HOME TWIN", systemImage: "cube.transparent.fill")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Text("OFFLINE · 3D").font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.white.opacity(0.14), in: Capsule())
            }
            Text("Типовая трёшка · 80 м²")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            Text("Синтетический план в миллиметрах. Отмечайте выполненное и смотрите, как меняется квартира.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.84))
            HStack(alignment: .firstTextBaseline) {
                Text("\(apartment.totalProgress(shelf: shelfEvidence))%")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                VStack(alignment: .leading, spacing: 5) {
                    ProgressView(value: Double(apartment.totalProgress(shelf: shelfEvidence)), total: 100)
                        .tint(Color(red: 0.45, green: 0.88, blue: 0.75))
                    Text("Записанный прогресс ремонта").font(.system(size: 11))
                }
            }
        }
        .padding(19)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .background(dark, in: RoundedRectangle(cornerRadius: 23))
    }

    private var model: some View {
        VStack(spacing: 9) {
            Picker("Ракурс", selection: $viewMode) {
                Text("Вся квартира").tag(TwinViewMode.overview)
                Text("Внутри комнаты").tag(TwinViewMode.interior)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("homeTwin.viewMode")
            if viewMode == .interior {
                Menu {
                    ForEach(apartment.rooms) { room in
                        Button(room.name) {
                            selectedRoomID = room.id
                            photoMessage = ""
                        }
                    }
                } label: {
                    HStack {
                        Label(selectedRoom?.name ?? "Комната", systemImage: "door.left.hand.open")
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(Color(red: 0.95, green: 0.96, blue: 0.96), in: RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityIdentifier("homeTwin.interiorRoom")
            }
            ZStack(alignment: .topLeading) {
                SceneView(
                    scene: TwinSceneFactory.make(
                        apartment: apartment,
                        selectedRoomID: selectedRoom?.id,
                        goalPreview: showGoal,
                        shelf: shelfEvidence,
                        mode: viewMode
                    ),
                    options: [.allowsCameraControl]
                )
                .frame(height: viewMode == .interior ? 410 : 360)
                .accessibilityLabel(viewMode == .interior
                    ? "Трёхмерный вид комнаты изнутри. Поворачивайте одним пальцем, приближайте двумя."
                    : "Трёхмерная модель квартиры. Поворачивайте одним пальцем, приближайте двумя.")
                VStack(alignment: .leading, spacing: 4) {
                    Text(showGoal ? "ГОТОВЫЙ ВИД" : "ПО ОТМЕТКАМ")
                        .font(.system(size: 11, weight: .bold))
                    Text(showGoal ? "Синтетический пример" : "Записанный прогресс")
                        .font(.system(size: 10))
                }
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
            HStack {
                Label("Повернуть · приблизить · отдалить", systemImage: "hand.draw")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer(minLength: 3)
                Button {
                    showGoal.toggle()
                } label: {
                    Label(showGoal ? "К прогрессу" : "Готовый вид",
                          systemImage: showGoal ? "checkmark.circle" : "square.3.layers.3d")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("homeTwin.preview")
            }
            if showGoal {
                Text("Синтетическая визуализация возможного интерьера по референсу. Она не подтверждает выполнение работ и не заменяет обмер.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
    }

    private var planDimensions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Размерная схема")
                .font(.system(size: 19, weight: .bold, design: .rounded))
            HStack(alignment: .firstTextBaseline) {
                Text("10 000 × 8 000 мм")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Spacer()
                Text("80 м² внутри").font(.system(size: 12)).foregroundStyle(.secondary)
            }
            topDownPlan
            ForEach(apartment.rooms) { room in
                HStack(spacing: 8) {
                    Text(room.name).lineLimit(1)
                    Spacer(minLength: 4)
                    Text(room.dimensionsLabel).monospacedDigit()
                    Text(room.sizeLabel).frame(width: 48, alignment: .trailing)
                }
                .font(.system(size: 12))
                .foregroundStyle(dark)
            }
            HStack {
                Text("Балкон")
                Spacer()
                Text("1 600 × 3 000 мм · отдельно от 80 м²")
            }
            .font(.system(size: 12)).foregroundStyle(.secondary)
            Text("Толщина стен и положение проёмов условные. Перед работами нужен обмер помещения.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 21))
    }

    private var topDownPlan: some View {
        GeometryReader { geometry in
            let unit = geometry.size.width / CGFloat(TwinPlan.widthMM)
            ZStack(alignment: .topLeading) {
                ForEach(TwinPlan.spaces, id: \.key) { space in
                    if let room = apartment.rooms.first(where: { $0.planKey == space.key }) {
                        let selected = selectedRoom?.id == room.id
                        Button {
                            selectedRoomID = room.id
                            photoMessage = ""
                        } label: {
                            Text(room.name).font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .foregroundStyle(selected ? .white : dark)
                            .frame(width: CGFloat(space.widthMM) * unit - 2,
                                   height: CGFloat(space.depthMM) * unit - 2)
                            .background(selected ? accent : Color(red: 0.86, green: 0.89, blue: 0.85))
                        }
                        .buttonStyle(.plain)
                        .position(x: (CGFloat(space.xMM) + CGFloat(space.widthMM) / 2) * unit,
                                  y: (CGFloat(space.zMM) + CGFloat(space.depthMM) / 2) * unit)
                        .accessibilityLabel("\(room.name), \(room.dimensionsLabel), \(room.sizeLabel)")
                    }
                }
            }
        }
        .aspectRatio(CGFloat(TwinPlan.widthMM) / CGFloat(TwinPlan.depthMM), contentMode: .fit)
        .accessibilityIdentifier("homeTwin.dimensionPlan")
    }

    private var rooms: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("Помещения")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(apartment.rooms) { room in
                        let isSelected = selectedRoom?.id == room.id
                        Button {
                            selectedRoomID = room.id
                            photoMessage = ""
                        } label: {
                            VStack(alignment: .leading, spacing: 7) {
                                Image(systemName: room.kind.symbol)
                                    .font(.system(size: 20))
                                Text(room.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .lineLimit(1)
                                Text("\(apartment.progress(in: room.id, shelf: shelfEvidence))% · \(room.sizeLabel)")
                                    .font(.system(size: 11))
                            }
                            .frame(width: 128, alignment: .leading)
                            .padding(12)
                            .foregroundStyle(isSelected ? .white : dark)
                            .background(isSelected ? accent : Color(red: 0.92, green: 0.95, blue: 0.98),
                                        in: RoundedRectangle(cornerRadius: 15))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("homeTwin.room.\(room.kind.rawValue)")
                    }
                }
            }
        }
    }

    private func roomDetails(_ room: TwinRoom) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            VStack(alignment: .leading, spacing: 3) {
                Text(room.name).font(.system(size: 19, weight: .bold, design: .rounded))
                Text("\(room.dimensionsLabel) · \(room.sizeLabel) · отметки пользователя")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            ForEach(TwinStage.allCases) { stage in
                Toggle(isOn: Binding(
                    get: { apartment.rooms.first(where: { $0.id == room.id })?.finishedStages.contains(stage) == true },
                    set: { apartment.mark(stage, in: room.id, completed: $0) }
                )) {
                    HStack(spacing: 10) {
                        Image(systemName: stage.symbol)
                            .frame(width: 27)
                            .foregroundStyle(accent)
                        Text(stage.title).font(.system(size: 14))
                    }
                }
                .tint(accent)
                .accessibilityIdentifier("homeTwin.stage.\(stage.rawValue)")
            }
            HStack {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label(room.referencePhotoName == nil ? "Добавить фото комнаты" : "Заменить фото",
                          systemImage: "photo.on.rectangle")
                        .font(.system(size: 13, weight: .medium))
                }
            }
            if let name = room.referencePhotoName,
               let image = TwinPhotoStore.load(name: name) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 130)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Личное фото этой комнаты, сохранённое на устройстве")
            }
            if !photoMessage.isEmpty {
                Text(photoMessage).font(.caption).foregroundStyle(.secondary)
            }
            Text("Изменение этапов вручную отображает ваш прогресс, но не подтверждает качество работ.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 21))
    }

    private var shelfDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Связь с Proof: установка полки", systemImage: "checkmark.shield")
                .font(.system(size: 16, weight: .bold))
            Text(shelfEvidence.caption)
                .font(.system(size: 13)).foregroundStyle(.secondary)
            if shelfEvidence != .none {
                Picker("Показывать полку в комнате", selection: Binding(
                    get: { apartment.shelfRoomID ?? apartment.rooms[0].id },
                    set: { apartment.shelfRoomID = $0 }
                )) {
                    ForEach(apartment.rooms) { room in
                        Text(room.name).tag(room.id)
                    }
                }
                .font(.system(size: 13))
                .accessibilityIdentifier("homeTwin.shelfRoom")
                Text("Полка появится в 3D после записи о выполнении в существующем проекте OMA ONE; фото не означает экспертное подтверждение.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            } else {
                Text("Создайте проект «Повесить полку» в OMA ONE, чтобы связать его выполнение с моделью.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 21))
    }

    private func importPhoto(_ item: PhotosPickerItem, for roomID: UUID) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            let fileName = try TwinPhotoStore.save(data: data, roomID: roomID)
            await MainActor.run {
                if let index = apartment.rooms.firstIndex(where: { $0.id == roomID }) {
                    apartment.rooms[index].referencePhotoName = fileName
                    photoMessage = "Фото сохранено только на устройстве. 3D-геометрия создаётся по размерам, а не из снимка."
                }
                selectedPhoto = nil
            }
        } catch {
            await MainActor.run {
                photoMessage = "Не удалось сохранить фото. Выберите изображение до 15 МБ."
                selectedPhoto = nil
            }
        }
    }
}

private enum TwinPhotoStore {
    private static var directory: URL? {
        guard let document = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return document.appendingPathComponent("OMAHomeTwinPhotos", isDirectory: true)
    }

    static func save(data: Data, roomID: UUID) throws -> String {
        guard data.count <= 15_000_000, let image = UIImage(data: data),
              let dir = directory else { throw CocoaError(.fileReadCorruptFile) }
        let ratio = min(1, 1200 / max(1, max(image.size.width, image.size.height)))
        let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let render = UIGraphicsImageRenderer(size: size, format: format)
        let resized = render.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        guard let jpeg = resized.jpegData(compressionQuality: 0.70) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let name = "\(roomID.uuidString).jpg"
        try jpeg.write(to: dir.appendingPathComponent(name), options: .atomic)
        return name
    }

    static func load(name: String) -> UIImage? {
        guard let dir = directory, UUID(uuidString: String(name.dropLast(4))) != nil,
              name.hasSuffix(".jpg") else { return nil }
        return UIImage(contentsOfFile: dir.appendingPathComponent(name).path)
    }

}

private enum TwinSceneFactory {
    private static let plaster = UIColor(red: 0.89, green: 0.88, blue: 0.83, alpha: 1)
    private static let concrete = UIColor(red: 0.65, green: 0.68, blue: 0.68, alpha: 1)
    private static let oak = UIColor(red: 0.69, green: 0.49, blue: 0.32, alpha: 1)
    private static let softOak = UIColor(red: 0.82, green: 0.68, blue: 0.49, alpha: 1)
    private static let sage = UIColor(red: 0.31, green: 0.47, blue: 0.44, alpha: 1)
    private static let linen = UIColor(red: 0.92, green: 0.88, blue: 0.80, alpha: 1)
    private static let porcelain = UIColor(red: 0.92, green: 0.94, blue: 0.92, alpha: 1)
    private static let metal = UIColor(red: 0.31, green: 0.37, blue: 0.39, alpha: 1)
    private static let forest = UIColor(red: 0.075, green: 0.13, blue: 0.095, alpha: 1)
    private static let olive = UIColor(red: 0.12, green: 0.20, blue: 0.15, alpha: 1)
    private static let walnut = UIColor(red: 0.28, green: 0.16, blue: 0.095, alpha: 1)
    private static let brass = UIColor(red: 0.65, green: 0.46, blue: 0.25, alpha: 1)
    private static let warmWhite = UIColor(red: 1, green: 0.79, blue: 0.53, alpha: 1)

    private static let walnutGrain: UIImage = {
        let size = CGSize(width: 128, height: 128)
        return UIGraphicsImageRenderer(size: size).image { context in
            walnut.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let cg = context.cgContext
            for line in 0..<42 {
                let x = CGFloat(line) * 3.1
                let variation = CGFloat((line * 17) % 11)
                cg.setStrokeColor(UIColor(red: 0.43, green: 0.27, blue: 0.16,
                                          alpha: line.isMultiple(of: 3) ? 0.45 : 0.24).cgColor)
                cg.setLineWidth(line.isMultiple(of: 7) ? 1.8 : 0.6)
                cg.move(to: CGPoint(x: x, y: 0))
                cg.addCurve(to: CGPoint(x: x + variation - 5, y: 128),
                            control1: CGPoint(x: x + variation, y: 43),
                            control2: CGPoint(x: x - variation / 2, y: 86))
                cg.strokePath()
            }
        }
    }()

    private static let wallArt: UIImage = {
        let size = CGSize(width: 192, height: 160)
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor(red: 0.85, green: 0.81, blue: 0.72, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let cg = context.cgContext
            cg.setStrokeColor(UIColor(red: 0.30, green: 0.29, blue: 0.25, alpha: 0.72).cgColor)
            for index in 0..<10 {
                let rootX = CGFloat(37 + index * 13)
                let topX = rootX + CGFloat((index * 19) % 25) - 12
                cg.setLineWidth(index.isMultiple(of: 3) ? 1.5 : 0.7)
                cg.move(to: CGPoint(x: rootX, y: 145))
                cg.addQuadCurve(to: CGPoint(x: topX, y: 30 + CGFloat(index % 4) * 9),
                                control: CGPoint(x: rootX + 15, y: 90))
                cg.strokePath()
                for branch in 0..<3 {
                    let height = CGFloat(55 + branch * 22)
                    cg.move(to: CGPoint(x: rootX + 8, y: height + 27))
                    cg.addLine(to: CGPoint(x: rootX + CGFloat(branch * 13) - 18, y: height))
                    cg.strokePath()
                }
            }
        }
    }()

    private static func material(_ color: UIColor, roughness: CGFloat = 0.77,
                                 opacity: CGFloat = 1) -> SCNMaterial {
        let result = SCNMaterial()
        result.lightingModel = .physicallyBased
        result.diffuse.contents = color
        result.roughness.contents = roughness
        result.transparency = opacity
        result.isDoubleSided = true
        return result
    }

    @discardableResult
    private static func box(_ parent: SCNNode, _ w: CGFloat, _ h: CGFloat, _ d: CGFloat,
                            _ x: Float, _ y: Float, _ z: Float, _ tint: UIColor,
                            opacity: CGFloat = 1, radius: CGFloat = 0.015) -> SCNNode {
        let shape = SCNBox(width: w, height: h, length: d, chamferRadius: radius)
        shape.materials = [material(tint, opacity: opacity)]
        let node = SCNNode(geometry: shape)
        node.position = SCNVector3(x, y, z)
        parent.addChildNode(node)
        return node
    }

    @discardableResult
    private static func woodBox(_ parent: SCNNode, _ w: CGFloat, _ h: CGFloat, _ d: CGFloat,
                                _ x: Float, _ y: Float, _ z: Float,
                                radius: CGFloat = 0.014) -> SCNNode {
        let node = box(parent, w, h, d, x, y, z, walnut, radius: radius)
        let grain = material(walnut)
        grain.diffuse.contents = walnutGrain
        grain.diffuse.wrapS = .repeat
        grain.diffuse.wrapT = .repeat
        grain.diffuse.contentsTransform = SCNMatrix4MakeScale(2, 1, 1)
        node.geometry?.materials = [grain]
        return node
    }

    @discardableResult
    private static func cylinder(_ parent: SCNNode, radius: CGFloat, height: CGFloat,
                                 x: Float, y: Float, z: Float, color: UIColor,
                                 orientation: SCNVector3 = SCNVector3Zero) -> SCNNode {
        let shape = SCNCylinder(radius: radius, height: height)
        shape.radialSegmentCount = 16
        shape.materials = [material(color, roughness: color == brass ? 0.32 : 0.75)]
        let node = SCNNode(geometry: shape)
        node.position = SCNVector3(x, y, z)
        node.eulerAngles = orientation
        parent.addChildNode(node)
        return node
    }

    @discardableResult
    private static func sphere(_ parent: SCNNode, radius: CGFloat,
                               x: Float, y: Float, z: Float, color: UIColor) -> SCNNode {
        let shape = SCNSphere(radius: radius)
        shape.segmentCount = 12
        shape.materials = [material(color)]
        let node = SCNNode(geometry: shape)
        node.position = SCNVector3(x, y, z)
        parent.addChildNode(node)
        return node
    }

    private static func light(_ parent: SCNNode, x: Float, y: Float, z: Float,
                              intensity: CGFloat, color: UIColor = warmWhite) {
        let node = SCNNode()
        let lamp = SCNLight()
        lamp.type = .omni
        lamp.intensity = intensity
        lamp.color = color
        lamp.attenuationEndDistance = 5
        node.light = lamp
        node.position = SCNVector3(x, y, z)
        parent.addChildNode(node)
    }

    private static func wallAtX(_ parent: SCNNode, x: Float, from: Float, to: Float,
                                height: CGFloat = 0.95, tint: UIColor = plaster) {
        guard to > from else { return }
        box(parent, 0.12, height, CGFloat(to - from),
            x, Float(height / 2), (from + to) / 2, tint)
    }

    private static func wallAtZ(_ parent: SCNNode, z: Float, from: Float, to: Float,
                                height: CGFloat = 0.95, tint: UIColor = plaster) {
        guard to > from else { return }
        box(parent, CGFloat(to - from), height, 0.12,
            (from + to) / 2, Float(height / 2), z, tint)
    }

    private static func verticalDoor(_ parent: SCNNode, x: Float, range: ClosedRange<Float>,
                                     opening: ClosedRange<Float>, tint: UIColor = plaster) {
        wallAtX(parent, x: x, from: range.lowerBound, to: opening.lowerBound, tint: tint)
        wallAtX(parent, x: x, from: opening.upperBound, to: range.upperBound, tint: tint)
        box(parent, 0.06, 0.03, CGFloat(opening.upperBound - opening.lowerBound),
            x, 0.08, (opening.lowerBound + opening.upperBound) / 2, oak)
        // Open leaf shows the hinge side without obstructing the 900 mm passage.
        box(parent, 0.52, 0.035, 0.04,
            x + 0.27, 0.10, opening.lowerBound + 0.02, softOak)
    }

    private static func horizontalDoor(_ parent: SCNNode, z: Float, range: ClosedRange<Float>,
                                       opening: ClosedRange<Float>, tint: UIColor = plaster) {
        wallAtZ(parent, z: z, from: range.lowerBound, to: opening.lowerBound, tint: tint)
        wallAtZ(parent, z: z, from: opening.upperBound, to: range.upperBound, tint: tint)
        box(parent, CGFloat(opening.upperBound - opening.lowerBound), 0.03, 0.06,
            (opening.lowerBound + opening.upperBound) / 2, 0.08, z, oak)
        box(parent, 0.04, 0.035, 0.52,
            opening.lowerBound + 0.02, 0.10, z - 0.27, softOak)
    }

    private static func windowAtX(_ parent: SCNNode, x: Float, z: Float, width: Float) {
        let glass = UIColor(red: 0.60, green: 0.76, blue: 0.78, alpha: 1)
        box(parent, 0.025, 0.66, CGFloat(width), x, 1.26, z, glass, opacity: 0.52)
        for offset in [-width / 2, 0, width / 2] {
            box(parent, 0.055, 0.75, 0.035, x, 1.26, z + offset, porcelain)
        }
        for y: Float in [0.87, 1.64] {
            box(parent, 0.065, 0.035, CGFloat(width) + 0.06, x, y, z, porcelain)
        }
        box(parent, 0.17, 0.23, CGFloat(width) * 0.70,
            x + (x < 5 ? 0.11 : -0.11), 0.42, z, porcelain) // radiator
        for offset in stride(from: -width * 0.25, through: width * 0.25, by: 0.12) {
            box(parent, 0.18, 0.17, 0.014,
                x + (x < 5 ? 0.12 : -0.12), 0.42, z + offset, metal)
        }
    }

    private static func windowAtZ(_ parent: SCNNode, z: Float, x: Float, width: Float) {
        let glass = UIColor(red: 0.60, green: 0.76, blue: 0.78, alpha: 1)
        box(parent, CGFloat(width), 0.68, 0.025, x, 1.27, z, glass, opacity: 0.52)
        for offset in [-width / 2, 0, width / 2] {
            box(parent, 0.035, 0.76, 0.05, x + offset, 1.27, z, porcelain)
        }
        for y: Float in [0.87, 1.65] {
            box(parent, CGFloat(width) + 0.06, 0.035, 0.065, x, y, z, porcelain)
        }
        box(parent, CGFloat(width) * 0.70, 0.23, 0.17, x, 0.42, z + 0.12, porcelain)
    }

    static func make(apartment: TwinApartment, selectedRoomID: UUID?,
                     goalPreview: Bool, shelf: TwinShelfEvidence,
                     mode: TwinViewMode) -> SCNScene {
        if mode == .interior,
           let room = apartment.rooms.first(where: { $0.id == selectedRoomID }) ?? apartment.rooms.first,
           let space = TwinPlan.space(for: room) {
            return makeInterior(room: room, space: space, apartment: apartment,
                                goalPreview: goalPreview, shelf: shelf)
        }
        let scene = SCNScene()
        scene.background.contents = UIColor(red: 0.91, green: 0.93, blue: 0.92, alpha: 1)
        let stage = SCNNode()
        stage.position = SCNVector3(-5, 0, -4)
        scene.rootNode.addChildNode(stage)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 120
        scene.rootNode.addChildNode(ambient)
        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 230
        sun.light?.castsShadow = true
        sun.light?.shadowRadius = 5
        sun.eulerAngles = SCNVector3(-Float.pi / 3, -Float.pi / 5, 0)
        scene.rootNode.addChildNode(sun)

        box(stage, 10.3, 0.22, 8.3, 5, -0.19, 4, metal)
        for room in apartment.rooms {
            guard let space = TwinPlan.space(for: room) else { continue }
            let floorReady = goalPreview || room.finishedStages.contains(.floor)
            let furnished = goalPreview || room.finishedStages.contains(.furniture)
            let wallsReady = goalPreview || room.finishedStages.contains(.walls)
            let lightReady = goalPreview || room.finishedStages.contains(.lights)
            let x = Float(space.xMM) / 1000
            let z = Float(space.zMM) / 1000
            let w = Float(space.widthMM) / 1000
            let d = Float(space.depthMM) / 1000
            let centerX = x + w / 2
            let centerZ = z + d / 2
            let floorColor: UIColor = !floorReady ? concrete :
                (room.kind == .kitchen || room.kind == .bathroom ? porcelain : softOak)
            box(stage, CGFloat(w) - 0.035, 0.08, CGFloat(d) - 0.035,
                centerX, -0.04, centerZ, floorColor)
            if floorReady {
                makeFloorDetail(stage, room: room, x: x, z: z, w: w, d: d)
            }
            if selectedRoomID == room.id {
                box(stage, CGFloat(w) - 0.18, 0.018, CGFloat(d) - 0.18,
                    centerX, 0.014, centerZ, UIColor(red: 0.23, green: 0.53, blue: 0.63, alpha: 1),
                    opacity: 0.13)
            }
            if furnished { makeFurniture(stage, key: space.key, x: x, z: z) }
            if lightReady {
                let lamp = SCNNode()
                lamp.light = SCNLight()
                lamp.light?.type = .omni
                lamp.light?.intensity = 28
                lamp.light?.color = UIColor(red: 1, green: 0.87, blue: 0.72, alpha: 1)
                lamp.position = SCNVector3(centerX, 1.6, centerZ)
                stage.addChildNode(lamp)
                box(stage, 0.25, 0.04, 0.25, centerX, 1.78, centerZ, linen)
            }
            // Painted skirting replaces raw concrete as the room's wall stage changes.
            let trim = wallsReady ? porcelain : concrete
            wallAtZ(stage, z: z + 0.08, from: x + 0.12, to: x + w - 0.12,
                    height: 0.07, tint: trim)
            wallAtX(stage, x: x + 0.08, from: z + 0.12, to: z + d - 0.12,
                    height: 0.07, tint: trim)
            if apartment.shelfRoomID == room.id && (shelf.isRecorded || goalPreview && shelf != .none) {
                let opacity: CGFloat = shelf.isRecorded ? 1 : 0.42
                box(stage, 1.15, 0.08, 0.28, x + 2.1, 1.18, z + 0.30, oak, opacity: opacity)
                box(stage, 0.10, 0.20, 0.10, x + 1.78, 1.31, z + 0.32, sage, opacity: opacity)
            }
        }

        // One connected set of perimeter and partition walls, with visible door gaps.
        let exterior = plaster
        wallAtX(stage, x: 0, from: 0, to: 2.20, height: 0.78, tint: exterior)
        wallAtX(stage, x: 0, from: 3.10, to: 8, height: 0.78, tint: exterior)
        box(stage, 0.10, 0.04, 0.90, 0, 0.08, 2.65, softOak) // balcony threshold
        wallAtX(stage, x: 10, from: 0, to: 8, height: 0.48, tint: exterior)
        wallAtZ(stage, z: 0, from: 0, to: 10, height: 0.82, tint: exterior)
        horizontalDoor(stage, z: 8, range: 0...10, opening: 4.55...5.45, tint: exterior)
        verticalDoor(stage, x: 4, range: 0...5, opening: 2.0...2.9)
        verticalDoor(stage, x: 4, range: 5...8, opening: 6.2...7.1)
        verticalDoor(stage, x: 6, range: 0...3.5, opening: 1.25...2.15)
        verticalDoor(stage, x: 6, range: 3.5...6, opening: 4.25...5.15)
        verticalDoor(stage, x: 6, range: 6...8, opening: 6.55...7.45)
        wallAtZ(stage, z: 5, from: 0, to: 4)
        wallAtZ(stage, z: 3.5, from: 6, to: 10)
        wallAtZ(stage, z: 6, from: 6, to: 10)
        windowAtX(stage, x: 0, z: 1.65, width: 1.6)
        windowAtX(stage, x: 0, z: 6.5, width: 1.35)
        windowAtX(stage, x: 10, z: 1.6, width: 1.45)
        windowAtX(stage, x: 10, z: 4.7, width: 1.35)
        windowAtZ(stage, z: 0, x: 5, width: 0.95)

        makeBalcony(stage)

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.zFar = 120
        camera.camera?.fieldOfView = 40
        camera.camera?.wantsHDR = true
        camera.camera?.wantsExposureAdaptation = false
        camera.camera?.exposureOffset = -1.3
        camera.position = SCNVector3(8.8, 13.4, 13.4)
        camera.look(at: SCNVector3(-0.45, 0, 0))
        scene.rootNode.addChildNode(camera)
        return scene
    }

    private static func makeInterior(room: TwinRoom, space: TwinPlanSpace,
                                     apartment: TwinApartment, goalPreview: Bool,
                                     shelf: TwinShelfEvidence) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor(red: 0.79, green: 0.76, blue: 0.70, alpha: 1)
        let stage = SCNNode()
        stage.position = SCNVector3(-5, 0, -4)
        scene.rootNode.addChildNode(stage)
        let x = Float(space.xMM) / 1000
        let z = Float(space.zMM) / 1000
        let w = Float(space.widthMM) / 1000
        let d = Float(space.depthMM) / 1000
        let wallsReady = goalPreview || room.finishedStages.contains(.walls)
        let floorReady = goalPreview || room.finishedStages.contains(.floor)
        let furnished = goalPreview || room.finishedStages.contains(.furniture)
        let lightReady = goalPreview || room.finishedStages.contains(.lights)
        let darkWall = room.kind == .living && wallsReady
        let back = darkWall ? forest : (wallsReady ? plaster : concrete)
        let side = wallsReady ? UIColor(red: 0.73, green: 0.72, blue: 0.66, alpha: 1) : concrete
        box(stage, CGFloat(w), 0.13, CGFloat(d), x + w / 2, -0.08, z + d / 2,
            floorReady ? (room.kind == .bathroom ? porcelain : softOak) : concrete)
        if floorReady { makeFloorDetail(stage, room: room, x: x, z: z, w: w, d: d) }
        let backWall = box(stage, CGFloat(w), 2.65, 0.09,
                           x + w / 2, 1.325, z, back, radius: 0)
        if darkWall {
            backWall.geometry?.firstMaterial?.emission.contents =
                UIColor(red: 0.018, green: 0.038, blue: 0.023, alpha: 1)
        }
        box(stage, 0.09, 2.65, CGFloat(d), x, 1.325, z + d / 2, side, radius: 0)
        box(stage, 0.09, 2.65, CGFloat(d), x + w, 1.325, z + d / 2, side, radius: 0)
        box(stage, CGFloat(w), 0.07, CGFloat(d), x + w / 2, 2.69, z + d / 2,
            plaster, radius: 0)
        for edgeX in [x + 0.07, x + w - 0.07] {
            box(stage, 0.035, 0.12, CGFloat(d), edgeX, 0.06, z + d / 2, porcelain, radius: 0)
        }
        box(stage, CGFloat(w), 0.12, 0.06, x + w / 2, 0.06, z + 0.08, porcelain, radius: 0)
        if wallsReady && space.key == "living" {
            makeLivingWalls(stage, x: x, z: z, w: w, d: d)
        } else if wallsReady {
            makeRoomWallDetails(stage, key: space.key, x: x, z: z, w: w, d: d)
        }
        if furnished { makeFurniture(stage, key: space.key, x: x, z: z) }
        if lightReady {
            if space.key == "living" {
                makeLivingLighting(stage, x: x, z: z, w: w, d: d)
            } else {
                light(stage, x: x + w / 2, y: 2.34, z: z + d / 2, intensity: 32)
            }
        }
        if apartment.shelfRoomID == room.id && (shelf.isRecorded || goalPreview && shelf != .none) {
            woodBox(stage, 0.68, 0.055, 0.27, x + w - 0.45, 1.52, z + 0.22)
        }
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 95
        scene.rootNode.addChildNode(ambient)
        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.intensity = 190
        fill.light?.color = UIColor(red: 0.95, green: 0.91, blue: 0.82, alpha: 1)
        fill.eulerAngles = SCNVector3(-Float.pi / 3, -Float.pi / 5, 0)
        scene.rootNode.addChildNode(fill)
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = space.key == "living" ? 69 : 72
        camera.camera?.wantsHDR = true
        camera.camera?.wantsExposureAdaptation = false
        camera.camera?.exposureOffset = -1.25
        camera.camera?.zNear = 0.03
        camera.camera?.zFar = 45
        camera.position = SCNVector3(x + w * 0.78 - 5, 1.54, z + d - 0.15 - 4)
        camera.look(at: SCNVector3(x + w * 0.48 - 5, 1.17, z + d * 0.23 - 4))
        scene.rootNode.addChildNode(camera)
        return scene
    }

    private static func makeFloorDetail(_ node: SCNNode, room: TwinRoom,
                                        x: Float, z: Float, w: Float, d: Float) {
        if room.kind == .kitchen || room.kind == .bathroom {
            for index in 1..<Int(w / 0.50) {
                box(node, 0.006, 0.003, CGFloat(d) - 0.08,
                    x + Float(index) * 0.50, 0.003, z + d / 2, concrete, opacity: 0.28)
            }
            for index in 1..<Int(d / 0.50) {
                box(node, CGFloat(w) - 0.08, 0.003, 0.006,
                    x + w / 2, 0.003, z + Float(index) * 0.50, concrete, opacity: 0.28)
            }
        } else {
            for index in 1..<Int(d / 0.46) {
                box(node, CGFloat(w) - 0.08, 0.003, 0.008,
                    x + w / 2, 0.003, z + Float(index) * 0.46, oak, opacity: 0.26)
            }
        }
    }

    private static func makeBalcony(_ node: SCNNode) {
        box(node, 1.6, 0.16, 3, -0.8, -0.12, 2.4, softOak)
        for index in 0..<8 {
            box(node, 1.5, 0.005, 0.012, -0.8, -0.02, 0.95 + Float(index) * 0.40, oak)
        }
        wallAtX(node, x: -1.6, from: 0.9, to: 3.9, height: 0.65, tint: metal)
        wallAtZ(node, z: 0.9, from: -1.6, to: 0, height: 0.65, tint: metal)
        wallAtZ(node, z: 3.9, from: -1.6, to: 0, height: 0.65, tint: metal)
        // Balcony doorway in the living room exterior, behind the cutaway wall.
        box(node, 0.03, 1.25, 0.82, -0.035, 0.72, 2.65, porcelain)
    }

    private static func makeLivingWalls(_ node: SCNNode, x: Float, z: Float,
                                        w: Float, d: Float) {
        // A luminous window, two curtain layers and timber slats echo the supplied reference.
        let window = box(node, 0.018, 1.83, 1.62, x + 0.052, 1.43, z + 1.43,
                         UIColor(red: 0.94, green: 0.95, blue: 0.91, alpha: 1), radius: 0)
        window.geometry?.firstMaterial?.emission.contents = UIColor(white: 0.20, alpha: 1)
        box(node, 0.045, 1.89, 0.035, x + 0.085, 1.43, z + 0.63, walnut)
        box(node, 0.045, 1.89, 0.035, x + 0.085, 1.43, z + 2.23, walnut)
        for index in 0..<14 {
            let curtainZ = z + 0.67 + Float(index) * 0.115
            box(node, 0.021, 2.10, 0.065, x + 0.11, 1.37, curtainZ,
                UIColor(red: 0.98, green: 0.95, blue: 0.87, alpha: 1),
                opacity: 0.64, radius: 0.025)
        }
        for curtainZ in [z + 0.55, z + 2.35] {
            for fold in 0..<4 {
                box(node, 0.045, 2.32, 0.078, x + 0.17, 1.38,
                    curtainZ + Float(fold) * 0.055, olive, radius: 0.03)
            }
        }
        woodBox(node, 0.84, 2.52, 0.10, x + 0.61, 1.26, z + 0.13, radius: 0)
        for index in 0..<12 {
            woodBox(node, 0.027, 2.5, 0.035, x + 0.22 + Float(index) * 0.067,
                    1.26, z + 0.20, radius: 0.005)
        }
        // TV, frame, floating shelf, cove and warm shelf lighting.
        box(node, 1.41, 0.81, 0.035, x + 2.22, 1.38, z + 0.11,
            UIColor(white: 0.07, alpha: 1), radius: 0.025)
        let screen = box(node, 1.30, 0.69, 0.004, x + 2.22, 1.38, z + 0.139,
                         UIColor(white: 0.012, alpha: 1), radius: 0.004)
        screen.geometry?.firstMaterial?.lightingModel = .constant
        woodBox(node, 2.00, 0.055, 0.23, x + 2.53, 1.94, z + 0.19)
        woodBox(node, 0.50, 0.47, 0.025, x + 2.62, 2.20, z + 0.13)
        let art = SCNPlane(width: 0.44, height: 0.41)
        art.materials = [material(linen)]
        art.firstMaterial?.diffuse.contents = wallArt
        let artNode = SCNNode(geometry: art)
        artNode.position = SCNVector3(x + 2.62, 2.20, z + 0.15)
        node.addChildNode(artNode)
        cylinder(node, radius: 0.065, height: 0.16,
                 x: x + 3.29, y: 2.05, z: z + 0.20, color: porcelain)
        makePlant(node, x: x + 3.35, z: z + 0.23, height: 0.47)
        woodBox(node, CGFloat(w) - 0.22, 0.075, 0.11,
                x + w / 2, 2.56, z + 0.10, radius: 0)
        box(node, CGFloat(w) - 0.26, 0.015, 0.025,
            x + w / 2, 2.52, z + 0.20, warmWhite, radius: 0)
        for sideX in [x + 0.11, x + w - 0.11] {
            box(node, 0.08, 0.07, CGFloat(d) - 0.05, sideX, 2.58, z + d / 2,
                porcelain, radius: 0)
        }
    }

    private static func makeRoomWallDetails(_ node: SCNNode, key: String,
                                            x: Float, z: Float, w: Float, d: Float) {
        let wallColor = key == "bath" ? porcelain : sage
        box(node, CGFloat(w) * 0.58, 1.07, 0.015,
            x + w * 0.62, 1.50, z + 0.063, wallColor, opacity: 0.64, radius: 0)
        if key == "kitchen" {
            for index in 0..<5 {
                woodBox(node, 0.56, 0.69, 0.32, x + 0.52 + Float(index) * 0.61,
                        2.15, z + 0.22, radius: 0.02)
            }
            box(node, 2.9, 0.035, 0.025, x + 2.0, 1.55, z + 0.09, warmWhite)
        } else if key == "bed1" || key == "bed2" {
            for index in 0..<6 {
                woodBox(node, 0.05, 1.12, 0.04, x + 0.42 + Float(index) * 0.13,
                        1.61, z + 0.12, radius: 0.01)
            }
            box(node, 0.73, 0.56, 0.025, x + w - 0.78, 1.77, z + 0.09,
                linen, radius: 0.025)
        } else if key == "bath" {
            box(node, 0.84, 0.94, 0.035, x + 2.16, 1.52, z + 0.10,
                metal, radius: 0.30)
            box(node, 0.75, 0.86, 0.04, x + 2.16, 1.52, z + 0.13,
                UIColor(red: 0.69, green: 0.77, blue: 0.76, alpha: 1), radius: 0.30)
        } else {
            woodBox(node, 1.25, 1.82, 0.10, x + w * 0.58, 0.91, z + 0.13)
        }
    }

    private static func makeLivingLighting(_ node: SCNNode, x: Float, z: Float,
                                           w: Float, d: Float) {
        let ring = SCNTorus(ringRadius: 0.38, pipeRadius: 0.011)
        ring.ringSegmentCount = 36
        ring.pipeSegmentCount = 8
        ring.materials = [material(metal, roughness: 0.35)]
        let ringNode = SCNNode(geometry: ring)
        ringNode.position = SCNVector3(x + 1.95, 2.19, z + d * 0.57)
        node.addChildNode(ringNode)
        for index in 0..<5 {
            let angle = Float(index) * .pi * 2 / 5
            let bulbX = x + 1.95 + cos(angle) * 0.38
            let bulbZ = z + d * 0.57 + sin(angle) * 0.38
            cylinder(node, radius: 0.006, height: 0.27,
                     x: bulbX, y: 2.46, z: bulbZ, color: metal)
            sphere(node, radius: 0.033, x: bulbX, y: 2.18, z: bulbZ, color: warmWhite)
        }
        light(node, x: x + 1.95, y: 2.19, z: z + d * 0.57, intensity: 18)
    }

    private static func makePlant(_ node: SCNNode, x: Float, z: Float,
                                  height: Float = 0.65) {
        cylinder(node, radius: 0.12, height: 0.19,
                 x: x, y: 0.12, z: z, color: walnut)
        cylinder(node, radius: 0.014, height: CGFloat(height),
                 x: x, y: 0.23 + height / 2, z: z, color: walnut)
        for index in 0..<7 {
            let angle = Float(index) * 2.4
            let spread = 0.15 + Float(index % 3) * 0.045
            let leaf = sphere(node, radius: 0.11,
                              x: x + cos(angle) * spread,
                              y: 0.40 + Float(index % 4) * height * 0.20,
                              z: z + sin(angle) * spread,
                              color: index.isMultiple(of: 3) ? forest : olive)
            leaf.scale = SCNVector3(1.35, 0.40, 0.63)
            leaf.eulerAngles.y = angle
        }
    }

    private static func makeFurniture(_ node: SCNNode, key: String, x: Float, z: Float) {
        switch key {
        case "living":
            box(node, 2.78, 0.035, 2.22, x + 2.05, 0.023, z + 2.55,
                linen, radius: 0.018) // soft-edged wool rug
            for stripe in 0..<16 {
                box(node, 2.55, 0.003, 0.004,
                    x + 2.05, 0.044, z + 1.52 + Float(stripe) * 0.13,
                    softOak, opacity: 0.38, radius: 0)
            }
            // Upholstery has separate rounded seat, back cushions, arms and piping.
            box(node, 2.27, 0.31, 0.84, x + 2.42, 0.37, z + 3.64,
                olive, radius: 0.13)
            for offset: Float in [-0.70, 0, 0.70] {
                box(node, 0.68, 0.17, 0.66, x + 2.42 + offset, 0.57,
                    z + 3.49, forest, radius: 0.08)
                let cushion = box(node, 0.62, 0.48, 0.18,
                                  x + 2.42 + offset, 0.76, z + 3.94,
                                  olive, radius: 0.075)
                cushion.eulerAngles.x = -0.13
            }
            for armX in [x + 1.18, x + 3.66] {
                box(node, 0.22, 0.54, 0.88, armX, 0.49, z + 3.65,
                    olive, radius: 0.10)
            }
            for offset: Float in [-0.82, 0.82] {
                cylinder(node, radius: 0.025, height: 0.17,
                         x: x + 2.42 + offset, y: 0.09, z: z + 3.88, color: walnut)
            }
            box(node, 0.43, 0.11, 0.41, x + 1.96, 0.75, z + 3.60,
                linen, radius: 0.05)
            box(node, 0.40, 0.11, 0.41, x + 3.08, 0.75, z + 3.63,
                sage, radius: 0.05)
            // Low walnut table with rounded corners, shelf, books and a ceramic vase.
            woodBox(node, 1.39, 0.13, 0.76, x + 2.22, 0.39, z + 2.31,
                    radius: 0.11)
            woodBox(node, 1.18, 0.045, 0.54, x + 2.22, 0.19, z + 2.31,
                    radius: 0.025)
            for legX in [x + 1.65, x + 2.79] {
                for legZ in [z + 2.02, z + 2.60] {
                    cylinder(node, radius: 0.024, height: 0.35,
                             x: legX, y: 0.20, z: legZ, color: walnut)
                }
            }
            box(node, 0.31, 0.027, 0.20, x + 1.99, 0.48, z + 2.39, linen)
            cylinder(node, radius: 0.075, height: 0.12,
                     x: x + 2.45, y: 0.52, z: z + 2.24, color: walnut)
            sphere(node, radius: 0.085, x: x + 2.45, y: 0.63,
                   z: z + 2.24, color: olive)
            woodBox(node, 2.22, 0.43, 0.42, x + 2.26, 0.28, z + 0.43,
                    radius: 0.035) // media console
            for index in 0..<25 {
                box(node, 0.018, 0.25, 0.018,
                    x + 1.22 + Float(index) * 0.084, 0.30, z + 0.66,
                    walnut, radius: 0.005)
            }
            // Curved lounge chair with timber frame.
            box(node, 0.75, 0.16, 0.68, x + 0.55, 0.43, z + 2.87,
                olive, radius: 0.08)
            let chairBack = box(node, 0.70, 0.68, 0.15,
                                x + 0.55, 0.73, z + 3.18,
                                olive, radius: 0.07)
            chairBack.eulerAngles.x = -0.20
            for armX in [x + 0.17, x + 0.93] {
                woodBox(node, 0.065, 0.42, 0.72, armX, 0.42, z + 2.92,
                        radius: 0.03)
            }
            makePlant(node, x: x + 0.39, z: z + 4.47, height: 0.72)
        case "kitchen":
            woodBox(node, 3.20, 0.82, 0.55, x + 2.12, 0.44, z + 0.45)
            box(node, 3.24, 0.06, 0.61, x + 2.12, 0.88, z + 0.45,
                porcelain, radius: 0.02)
            box(node, 0.56, 1.85, 0.60, x + 0.52, 0.96, z + 0.48, porcelain) // fridge
            box(node, 0.51, 0.018, 0.35, x + 2.55, 0.924, z + 0.43, porcelain) // sink
            cylinder(node, radius: 0.018, height: 0.19,
                     x: x + 2.77, y: 1.04, z: z + 0.43, color: brass)
            for offset: Float in [-0.15, 0.15] {
                cylinder(node, radius: 0.09, height: 0.012,
                         x: x + 1.55 + offset, y: 0.925, z: z + 0.43, color: metal)
            }
            woodBox(node, 1.15, 0.07, 0.72, x + 2.1, 0.76, z + 1.85,
                    radius: 0.06) // table
            for offset: Float in [-0.7, 0.7] {
                cylinder(node, radius: 0.20, height: 0.10,
                         x: x + 2.1 + offset, y: 0.47, z: z + 1.85, color: olive)
                cylinder(node, radius: 0.026, height: 0.42,
                         x: x + 2.1 + offset, y: 0.23, z: z + 1.85, color: walnut)
            }
        case "bed1":
            makeBed(node, x: x + 2.2, z: z + 1.8, tint: linen)
            woodBox(node, 1.12, 1.52, 0.54, x + 0.48, 0.80, z + 2.58)
            woodBox(node, 0.38, 0.48, 0.38, x + 3.45, 0.27, z + 0.8)
            makePlant(node, x: x + 0.58, z: z + 0.65, height: 0.48)
        case "bed2":
            makeBed(node, x: x + 2.7, z: z + 1.25, tint: sage)
            woodBox(node, 1.10, 0.08, 0.54, x + 0.85, 0.69, z + 0.54) // desk
            cylinder(node, radius: 0.21, height: 0.13,
                     x: x + 0.85, y: 0.43, z: z + 1.25, color: linen)
            woodBox(node, 0.92, 1.35, 0.38, x + 0.52, 0.70, z + 2.10) // shelves
        case "bath":
            box(node, 1.65, 0.47, 0.75, x + 1.05, 0.32, z + 1.22,
                porcelain, radius: 0.20) // rounded bath
            box(node, 1.44, 0.012, 0.55, x + 1.05, 0.562, z + 1.22,
                UIColor(red: 0.52, green: 0.69, blue: 0.70, alpha: 1), radius: 0.20)
            woodBox(node, 0.72, 0.75, 0.49, x + 2.15, 0.41, z + 0.45) // vanity
            cylinder(node, radius: 0.24, height: 0.10,
                     x: x + 2.15, y: 0.84, z: z + 0.45, color: porcelain)
            box(node, 0.42, 0.49, 0.54, x + 3.25, 0.30, z + 1.38,
                porcelain, radius: 0.16) // toilet
            box(node, 0.52, 0.76, 0.54, x + 3.28, 0.40, z + 0.42, porcelain) // washer
            cylinder(node, radius: 0.20, height: 0.012,
                     x: x + 3.28, y: 0.81, z: z + 0.42, color: metal)
        case "hall":
            woodBox(node, 0.52, 1.66, 1.55, x + 0.43, 0.86, z + 1.05) // wardrobe
            woodBox(node, 0.42, 0.42, 0.90, x + 1.55, 0.26, z + 5.85) // bench
            box(node, 0.42, 0.17, 0.90, x + 1.55, 0.13, z + 7.42,
                olive, radius: 0.06) // shoe bench
        default: break
        }
    }

    private static func makeBed(_ node: SCNNode, x: Float, z: Float, tint: UIColor) {
        woodBox(node, 1.65, 0.32, 1.90, x, 0.24, z, radius: 0.05)
        box(node, 1.52, 0.18, 1.76, x, 0.46, z, tint, radius: 0.07)
        box(node, 1.68, 0.62, 0.13, x, 0.54, z - 1.0,
            olive, radius: 0.06)
        box(node, 1.45, 0.07, 0.93, x, 0.57, z + 0.37,
            tint == sage ? sage : linen, radius: 0.035)
        box(node, 1.43, 0.055, 0.48, x, 0.62, z + 0.58,
            softOak, radius: 0.025) // folded throw
        for offset: Float in [-0.42, 0.42] {
            box(node, 0.59, 0.12, 0.35, x + offset, 0.63,
                z - 0.58, porcelain, radius: 0.055)
        }
        for offsetX: Float in [-0.69, 0.69] {
            for offsetZ: Float in [-0.79, 0.79] {
                cylinder(node, radius: 0.03, height: 0.18,
                         x: x + offsetX, y: 0.10, z: z + offsetZ, color: walnut)
            }
        }
    }
}
