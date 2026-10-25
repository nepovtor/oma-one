import SwiftUI
import SceneKit
import PhotosUI
import UIKit

// An actual interactive SceneKit scene; the plan is approximate and authored
// by the user. Photos are private references, NOT input to a 3D reconstruction.
struct HomeTwin3DView: View {
    let shelfEvidence: TwinShelfEvidence

    @State private var apartment = TwinApartment.load()
    @State private var selectedRoomID: UUID?
    @State private var showGoal = false
    @State private var editorVisible = false
    @State private var editingRoomID: UUID?
    @State private var editorName = ""
    @State private var editorKind: TwinRoomKind = .living
    @State private var editorWidth = 4.0
    @State private var editorDepth = 4.0
    @State private var confirmRemoval = false
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
                rooms
                if let room = selectedRoom { roomDetails(room) }
                shelfDetails
                Text("HOME TWIN — персональная схематичная 3D-модель, а не точный обмер квартиры. Размеры и прогресс вводятся вами; фото остаются на устройстве. Отметка задачи и фото не означают экспертную проверку ремонта.")
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
        .sheet(isPresented: $editorVisible) { roomEditor }
        .confirmationDialog("Удалить комнату из 3D-плана?", isPresented: $confirmRemoval, titleVisibility: .visible) {
            Button("Удалить комнату", role: .destructive) {
                if let room = selectedRoom {
                    if let photo = room.referencePhotoName {
                        TwinPhotoStore.remove(name: photo)
                    }
                    apartment.removeRoom(id: room.id)
                    selectedRoomID = apartment.rooms.first?.id
                }
            }
        } message: {
            Text("Отметки этой комнаты будут удалены. Сохранённые проекты OMA ONE останутся без изменений.")
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
            Text("Ваш ремонт становится видимым")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            Text("Настройте комнаты, отмечайте реально сделанное и наблюдайте за изменениями квартиры.")
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
        .background(LinearGradient(colors: [dark, accent], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 23))
    }

    private var model: some View {
        VStack(spacing: 9) {
            ZStack(alignment: .topLeading) {
                SceneView(
                    scene: TwinSceneFactory.make(
                        apartment: apartment,
                        selectedRoomID: selectedRoom?.id,
                        goalPreview: showGoal,
                        shelf: shelfEvidence
                    ),
                    options: [.allowsCameraControl, .autoenablesDefaultLighting]
                )
                .frame(height: 316)
                .accessibilityLabel("Трёхмерная модель квартиры. Поворачивайте одним пальцем, приближайте двумя.")
                VStack(alignment: .leading, spacing: 4) {
                    Text(showGoal ? "ВИД ЦЕЛИ" : "ТЕКУЩИЙ ВИД")
                        .font(.system(size: 11, weight: .bold))
                    Text(showGoal ? "Предполагаемый результат" : "По вашим отметкам")
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
                    Label(showGoal ? "К прогрессу" : "Показать цель",
                          systemImage: showGoal ? "checkmark.circle" : "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("homeTwin.preview")
            }
            if showGoal {
                Text("Это визуализация возможного результата, не отметка о завершении и не доказательство работ.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
    }

    private var rooms: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("Мои комнаты")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                Spacer()
                Button {
                    startNewRoom()
                } label: {
                    Label("Добавить", systemImage: "plus.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                }
                .disabled(apartment.rooms.count >= TwinApartment.maximumRooms)
                .accessibilityIdentifier("homeTwin.addRoom")
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
            if apartment.rooms.count == TwinApartment.maximumRooms {
                Text("В этом MVP поддерживаются четыре комнаты — для наглядного показа.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func roomDetails(_ room: TwinRoom) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(room.name).font(.system(size: 19, weight: .bold, design: .rounded))
                    Text("\(room.kind.title) · \(room.sizeLabel) · отмечено пользователем")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    startEditing(room)
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 19))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Изменить название и размеры комнаты")
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
                Spacer()
                if apartment.rooms.count > 1 {
                    Button(role: .destructive) {
                        confirmRemoval = true
                    } label: {
                        Label("Удалить", systemImage: "trash")
                            .font(.system(size: 13))
                    }
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

    private func startNewRoom() {
        guard apartment.rooms.count < TwinApartment.maximumRooms else { return }
        editingRoomID = nil
        editorName = "Комната"
        editorKind = .bedroom
        editorWidth = 4
        editorDepth = 4
        editorVisible = true
    }

    private func startEditing(_ room: TwinRoom) {
        editingRoomID = room.id
        editorKind = room.kind
        editorName = room.name
        editorWidth = room.width
        editorDepth = room.depth
        editorVisible = true
    }

    private var roomEditor: some View {
        NavigationStack {
            Form {
                Section("Комната") {
                    TextField("Название комнаты", text: $editorName)
                        .textInputAutocapitalization(.sentences)
                    Picker("Назначение", selection: $editorKind) {
                        ForEach(TwinRoomKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                }
                Section("Примерные размеры") {
                    Stepper(value: $editorWidth, in: 2.5...5.8, step: 0.1) {
                        Text("Ширина: \(editorWidth.formatted(.number.precision(.fractionLength(1)))) м")
                    }
                    Stepper(value: $editorDepth, in: 2.5...5.8, step: 0.1) {
                        Text("Длина: \(editorDepth.formatted(.number.precision(.fractionLength(1)))) м")
                    }
                    Text("Расположение комнат задаётся автоматически сеткой. Это схематичная модель, а не точный архитектурный план.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(editingRoomID == nil ? "Новая комната" : "Настройки комнаты")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { editorVisible = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") {
                        if let editingRoomID {
                            apartment.updateRoom(id: editingRoomID, kind: editorKind,
                                                 name: editorName, width: editorWidth, depth: editorDepth)
                        } else if apartment.addRoom(kind: editorKind),
                                  let newID = apartment.rooms.last?.id {
                            apartment.updateRoom(id: newID, kind: editorKind,
                                                 name: editorName, width: editorWidth, depth: editorDepth)
                            selectedRoomID = newID
                        }
                        editorVisible = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
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

    static func remove(name: String) {
        guard let dir = directory, name.hasSuffix(".jpg"),
              UUID(uuidString: String(name.dropLast(4))) != nil else { return }
        try? FileManager.default.removeItem(at: dir.appendingPathComponent(name))
    }
}

private enum TwinSceneFactory {
    private static func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: 1)
    }

    @discardableResult
    private static func cuboid(
        _ parent: SCNNode, width: CGFloat, height: CGFloat, depth: CGFloat,
        x: Float, y: Float, z: Float, tint: UIColor, transparency: CGFloat = 1
    ) -> SCNNode {
        let shape = SCNBox(width: width, height: height, length: depth, chamferRadius: 0.025)
        let surface = SCNMaterial()
        surface.diffuse.contents = tint
        surface.lightingModel = .blinn
        surface.transparency = transparency
        surface.isDoubleSided = true
        shape.materials = [surface]
        let node = SCNNode(geometry: shape)
        node.position = SCNVector3(x, y, z)
        parent.addChildNode(node)
        return node
    }

    static func make(apartment: TwinApartment, selectedRoomID: UUID?,
                     goalPreview: Bool, shelf: TwinShelfEvidence) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = color(0.88, 0.93, 0.98)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 550
        ambient.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambient)

        let sunlight = SCNNode()
        sunlight.light = SCNLight()
        sunlight.light?.type = .directional
        sunlight.light?.intensity = 850
        sunlight.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 5, -Float.pi / 6)
        scene.rootNode.addChildNode(sunlight)

        let rowCount = max(1, (apartment.rooms.count + 1) / 2)
        for (index, room) in apartment.rooms.enumerated() {
            let column = index % 2
            let row = index / 2
            let centerX = apartment.rooms.count == 1 ? 0 : (Float(column) - 0.5) * 6.35
            let centerZ = (Float(row) - Float(rowCount - 1) / 2) * 6.35
            let foundation = SCNNode()
            foundation.position = SCNVector3(centerX, 0, centerZ)
            scene.rootNode.addChildNode(foundation)
            makeRoom(
                room, in: foundation, selected: selectedRoomID == room.id,
                goalPreview: goalPreview,
                shelfPlanned: apartment.shelfRoomID == room.id && shelf != .none,
                shelfShown: apartment.shelfRoomID == room.id && shelf.isRecorded
            )
        }

        let distance: Float = rowCount > 1 ? 18 : 12.5
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.zFar = 150
        camera.camera?.fieldOfView = 44
        camera.position = SCNVector3(distance * 0.65, distance * 0.9, distance)
        camera.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(camera)
        return scene
    }

    private static func makeRoom(
        _ room: TwinRoom, in node: SCNNode, selected: Bool,
        goalPreview: Bool, shelfPlanned: Bool, shelfShown: Bool
    ) {
        let w = Float(room.width), d = Float(room.depth)
        let wallDone = goalPreview || room.finishedStages.contains(.walls)
        let floorDone = goalPreview || room.finishedStages.contains(.floor)
        let lightDone = goalPreview || room.finishedStages.contains(.lights)
        let furnished = goalPreview || room.finishedStages.contains(.furniture)
        let concrete = color(0.61, 0.65, 0.67)
        let paint = color(0.97, 0.95, 0.89)
        let timber = color(0.74, 0.55, 0.37)
        let tiles = color(0.83, 0.87, 0.86)
        let floorTint = floorDone ? ((room.kind == .bathroom || room.kind == .kitchen) ? tiles : timber) : concrete

        cuboid(node, width: CGFloat(w) + 0.28, height: 0.22, depth: CGFloat(d) + 0.28,
               x: 0, y: -0.17, z: 0, tint: color(0.35, 0.43, 0.52))
        cuboid(node, width: CGFloat(w), height: 0.12, depth: CGFloat(d),
               x: 0, y: 0, z: 0, tint: floorTint)

        if floorDone {
            let number = Int(d / 0.48)
            for index in 1..<max(2, number) {
                let z = -d / 2 + Float(index) * d / Float(max(2, number))
                cuboid(node, width: CGFloat(w - 0.08), height: 0.007, depth: 0.014,
                       x: 0, y: 0.067, z: z, tint: color(0.56, 0.45, 0.34),
                       transparency: 0.44)
            }
        }

        let wallTint = wallDone ? paint : concrete
        cuboid(node, width: CGFloat(w), height: 2.1, depth: 0.11,
               x: 0, y: 1.05, z: -d / 2, tint: wallTint)
        cuboid(node, width: 0.11, height: 2.1, depth: CGFloat(d),
               x: -w / 2, y: 1.05, z: 0, tint: wallTint)
        cuboid(node, width: 0.11, height: 0.35, depth: CGFloat(d),
               x: w / 2, y: 0.18, z: 0, tint: wallTint)

        // Stylized daylight window on the far wall; only the front/right walls
        // are open to allow an isometric cutaway view.
        cuboid(node, width: 0.92, height: 0.64, depth: 0.02,
               x: -w / 4, y: 1.40, z: -d / 2 + 0.068,
               tint: color(0.52, 0.75, 0.87), transparency: 0.89)
        cuboid(node, width: 0.98, height: 0.05, depth: 0.05,
               x: -w / 4, y: 1.73, z: -d / 2 + 0.09, tint: UIColor.white)
        cuboid(node, width: 0.98, height: 0.05, depth: 0.05,
               x: -w / 4, y: 1.07, z: -d / 2 + 0.09, tint: UIColor.white)

        let lampColor = lightDone ? color(1, 0.83, 0.45) : color(0.45, 0.49, 0.55)
        let fixture = SCNSphere(radius: 0.13)
        fixture.firstMaterial?.diffuse.contents = lampColor
        let bulb = SCNNode(geometry: fixture)
        bulb.position = SCNVector3(0.55, 1.83, -0.15)
        node.addChildNode(bulb)
        if lightDone {
            let glow = SCNNode()
            glow.light = SCNLight()
            glow.light?.type = .omni
            glow.light?.intensity = 240
            glow.light?.color = color(1, 0.86, 0.64)
            glow.position = bulb.position
            node.addChildNode(glow)
        }

        if furnished { makeFurniture(room.kind, in: node, w: w, d: d) }

        if shelfShown || (goalPreview && shelfPlanned) {
            let alpha: CGFloat = shelfShown ? 1 : 0.42
            cuboid(node, width: 1.23, height: 0.095, depth: 0.30,
                   x: 0.58, y: 1.36, z: -d / 2 + 0.31,
                   tint: color(0.51, 0.31, 0.19), transparency: alpha)
            cuboid(node, width: 0.15, height: 0.32, depth: 0.14,
                   x: 0.22, y: 1.56, z: -d / 2 + 0.31,
                   tint: color(0.18, 0.49, 0.63), transparency: alpha)
            cuboid(node, width: 0.14, height: 0.23, depth: 0.14,
                   x: 0.43, y: 1.52, z: -d / 2 + 0.31,
                   tint: color(0.85, 0.51, 0.25), transparency: alpha)
        }

        if selected {
            let highlight = color(0.10, 0.51, 0.98)
            cuboid(node, width: CGFloat(w) + 0.18, height: 0.045, depth: 0.06,
                   x: 0, y: -0.035, z: d / 2 + 0.06, tint: highlight)
            cuboid(node, width: 0.06, height: 0.045, depth: CGFloat(d) + 0.18,
                   x: w / 2 + 0.06, y: -0.035, z: 0, tint: highlight)
        }
    }

    private static func makeFurniture(_ kind: TwinRoomKind, in node: SCNNode, w: Float, d: Float) {
        switch kind {
        case .living:
            let couch = color(0.27, 0.49, 0.57)
            cuboid(node, width: 1.55, height: 0.40, depth: 0.70, x: -0.35, y: 0.28, z: 0.38, tint: couch)
            cuboid(node, width: 1.55, height: 0.64, depth: 0.15, x: -0.35, y: 0.64, z: 0.10, tint: couch)
            cuboid(node, width: 0.72, height: 0.25, depth: 0.57, x: 0.34, y: 0.24, z: -0.73,
                   tint: color(0.52, 0.35, 0.23))
        case .kitchen:
            cuboid(node, width: CGFloat(w * 0.72), height: 0.83, depth: 0.52,
                   x: 0.25, y: 0.45, z: -d / 2 + 0.42, tint: color(0.82, 0.83, 0.76))
            cuboid(node, width: CGFloat(w * 0.75), height: 0.08, depth: 0.58,
                   x: 0.25, y: 0.90, z: -d / 2 + 0.42, tint: color(0.39, 0.44, 0.48))
            cuboid(node, width: 0.73, height: 0.10, depth: 0.73, x: 0.25, y: 0.72, z: 0.65,
                   tint: color(0.61, 0.42, 0.28))
        case .bedroom:
            cuboid(node, width: 1.85, height: 0.34, depth: 2.20, x: 0, y: 0.25, z: 0.23,
                   tint: color(0.42, 0.34, 0.31))
            cuboid(node, width: 1.73, height: 0.19, depth: 2.03, x: 0, y: 0.47, z: 0.25,
                   tint: color(0.90, 0.89, 0.83))
            cuboid(node, width: 1.82, height: 0.65, depth: 0.18, x: 0, y: 0.64, z: -0.86,
                   tint: color(0.45, 0.42, 0.51))
        case .bathroom:
            cuboid(node, width: 1.58, height: 0.45, depth: 0.83, x: -0.25, y: 0.31, z: -0.54,
                   tint: color(0.96, 0.97, 0.97))
            cuboid(node, width: 0.68, height: 0.42, depth: 0.64, x: 0.93, y: 0.33, z: 0.73,
                   tint: color(0.96, 0.96, 0.94))
        case .hallway:
            cuboid(node, width: 1.35, height: 0.82, depth: 0.43, x: 0.23, y: 0.44, z: -0.70,
                   tint: color(0.58, 0.42, 0.31))
            cuboid(node, width: 0.74, height: 0.27, depth: 0.52, x: -0.40, y: 0.20, z: 0.86,
                   tint: color(0.30, 0.46, 0.57))
        }
    }
}
