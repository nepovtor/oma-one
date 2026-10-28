import SwiftUI
import PhotosUI
import UIKit

private enum TwinViewMode: String, CaseIterable {
    case overview, interior
}

// Photorealistic local renders replace the former primitive SceneKit geometry.
// Personal photos stay on-device and are shown only as the recorded current state.
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

    private var selectedSpace: TwinPlanSpace? {
        selectedRoom.flatMap { TwinPlan.space(for: $0) }
    }

    private var renderAssetName: String {
        viewMode == .overview ? "TwinOverview" : (selectedSpace?.renderAssetName ?? "TwinLiving")
    }

    private var recordedPhoto: UIImage? {
        guard !showGoal, viewMode == .interior,
              let name = selectedRoom?.referencePhotoName else { return nil }
        return TwinPhotoStore.load(name: name)
    }

    private var displayedProgress: Int {
        guard viewMode == .interior, let room = selectedRoom else {
            return apartment.totalProgress(shelf: shelfEvidence)
        }
        return apartment.progress(in: room.id, shelf: shelfEvidence)
    }

    private var previewIdentity: String {
        "\(viewMode.rawValue)-\(selectedRoom?.planKey ?? "all")-\(showGoal)-\(selectedRoom?.referencePhotoName ?? "none")"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                intro
                visualPreview
                planDimensions
                rooms
                if let room = selectedRoom { roomDetails(room) }
                shelfDetails
                Text("Синтетические рендеры показывают дизайн-концепцию, а не фактическое состояние или точный обмер. Личные фото остаются на устройстве. Отметка задачи и фото не означают экспертную проверку ремонта.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 3)
            }
            .padding(16)
        }
        .background(Color(red: 0.96, green: 0.97, blue: 0.99))
        .navigationTitle("Мой дом · визуализация")
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
                Label("OMA HOME TWIN", systemImage: "photo.on.rectangle.angled")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Text("OFFLINE · PHOTO").font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.white.opacity(0.14), in: Capsule())
            }
            Text("Квартира по плану · 58,67 м²")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text("Фотореалистичная дизайн-концепция всех помещений по присланной схеме.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.84))
            HStack(alignment: .firstTextBaseline) {
                Text("\(apartment.totalProgress(shelf: shelfEvidence))%")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
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

    private var visualPreview: some View {
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

            TwinPhotoViewer(
                assetName: renderAssetName,
                userImage: recordedPhoto,
                showGoal: showGoal,
                progress: displayedProgress
            )
            .id(previewIdentity)
            .frame(height: viewMode == .interior ? 410 : 390)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .accessibilityIdentifier("homeTwin.previewImage")

            HStack {
                Label("Разведите пальцы · перетащите · двойное касание", systemImage: "hand.draw")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer(minLength: 3)
                Button {
                    showGoal.toggle()
                } label: {
                    Label(showGoal ? "К прогрессу" : "Готовый вид",
                          systemImage: showGoal ? "checkmark.circle" : "photo")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("homeTwin.preview")
            }

            Text(previewNote)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
    }

    private var previewNote: String {
        if showGoal {
            return "Синтетический фотореалистичный рендер возможного интерьера. Это не фотография готового ремонта."
        }
        if recordedPhoto != nil {
            return "Показано личное фото выбранной комнаты, сохранённое только на устройстве."
        }
        return "Фото текущего состояния не добавлено. Целевой рендер затемнён пропорционально записанному прогрессу (\(displayedProgress)%); это только визуальная индикация."
    }

    private var planDimensions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("План по изображению")
                .font(.system(size: 19, weight: .bold, design: .rounded))
            HStack(alignment: .firstTextBaseline) {
                Text("6 070 × 9 820 мм")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Spacer()
                Text("58,67 м² по схеме").font(.system(size: 12)).foregroundStyle(.secondary)
            }
            topDownPlan
            ForEach(apartment.rooms) { room in
                HStack(spacing: 8) {
                    Text(room.name).lineLimit(1)
                    Spacer(minLength: 4)
                    Text(room.dimensionsLabel).monospacedDigit()
                    Text(room.sizeLabel).frame(width: 58, alignment: .trailing)
                }
                .font(.system(size: 12))
                .foregroundStyle(dark)
            }
            Text("Часть размеров считана с изображения низкого разрешения и помечена знаком ≈. Перед работами нужен профессиональный обмер.")
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
                        ForEach(Array(space.planRects.enumerated()), id: \.element.id) { item in
                            let rect = item.element
                            let selected = selectedRoom?.id == room.id
                            Button {
                                selectedRoomID = room.id
                                photoMessage = ""
                            } label: {
                                ZStack {
                                    Rectangle().fill(selected ? accent : Color(red: 0.86, green: 0.89, blue: 0.85))
                                    if item.offset == 0 {
                                        VStack(spacing: 2) {
                                            Text(room.name)
                                            Text(room.sizeLabel).font(.system(size: 8, weight: .regular))
                                        }
                                        .font(.system(size: 10, weight: .semibold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.65)
                                        .foregroundStyle(selected ? .white : dark)
                                        .padding(2)
                                    }
                                }
                                .frame(width: max(4, CGFloat(rect.widthMM) * unit - 2),
                                       height: max(4, CGFloat(rect.depthMM) * unit - 2))
                            }
                            .buttonStyle(.plain)
                            .position(x: (CGFloat(rect.xMM) + CGFloat(rect.widthMM) / 2) * unit,
                                      y: (CGFloat(rect.zMM) + CGFloat(rect.depthMM) / 2) * unit)
                            .accessibilityHidden(item.offset != 0)
                            .accessibilityLabel("\(room.name), \(room.dimensionsLabel), \(room.sizeLabel)")
                        }
                    }
                }
            }
        }
        .aspectRatio(CGFloat(TwinPlan.widthMM) / CGFloat(TwinPlan.depthMM), contentMode: .fit)
        .accessibilityIdentifier("homeTwin.dimensionPlan")
    }

    private var rooms: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("Помещения")
                .font(.system(size: 19, weight: .bold, design: .rounded))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(apartment.rooms) { room in
                        let isSelected = selectedRoom?.id == room.id
                        Button {
                            selectedRoomID = room.id
                            viewMode = .interior
                            photoMessage = ""
                        } label: {
                            VStack(alignment: .leading, spacing: 7) {
                                Image(systemName: room.kind.symbol).font(.system(size: 20))
                                Text(room.name).font(.system(size: 13, weight: .semibold)).lineLimit(1)
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
                        .accessibilityIdentifier("homeTwin.room.\(room.planKey ?? room.kind.rawValue)")
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
                        Image(systemName: stage.symbol).frame(width: 27).foregroundStyle(accent)
                        Text(stage.title).font(.system(size: 14))
                    }
                }
                .tint(accent)
                .accessibilityIdentifier("homeTwin.stage.\(stage.rawValue)")
            }
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label(room.referencePhotoName == nil ? "Добавить фото текущего состояния" : "Заменить фото",
                      systemImage: "photo.on.rectangle")
                    .font(.system(size: 13, weight: .medium))
            }
            if let name = room.referencePhotoName, let image = TwinPhotoStore.load(name: name) {
                Image(uiImage: image)
                    .resizable().scaledToFill()
                    .frame(maxWidth: .infinity).frame(height: 130).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Личное фото этой комнаты, сохранённое на устройстве")
            }
            if !photoMessage.isEmpty { Text(photoMessage).font(.caption).foregroundStyle(.secondary) }
            Text("Отметки и фото отражают данные пользователя, но не подтверждают качество работ.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 21))
    }

    private var shelfDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Связь с Proof: установка полки", systemImage: "checkmark.shield")
                .font(.system(size: 16, weight: .bold))
            Text(shelfEvidence.caption).font(.system(size: 13)).foregroundStyle(.secondary)
            if shelfEvidence != .none, let fallbackID = apartment.rooms.first?.id {
                Picker("Комната проекта полки", selection: Binding(
                    get: { apartment.shelfRoomID ?? fallbackID },
                    set: { apartment.shelfRoomID = $0 }
                )) {
                    ForEach(apartment.rooms) { room in Text(room.name).tag(room.id) }
                }
                .font(.system(size: 13))
                .accessibilityIdentifier("homeTwin.shelfRoom")
                Text("Статус Proof влияет на процент комнаты, но не изменяет синтетический рендер и не означает экспертное подтверждение.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            } else {
                Text("Создайте проект «Повесить полку» в ОМА, чтобы связать его выполнение с комнатой.")
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
                    photoMessage = "Фото сохранено только на устройстве и доступно в режиме «К прогрессу»."
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

private struct TwinPhotoViewer: View {
    let assetName: String
    let userImage: UIImage?
    let showGoal: Bool
    let progress: Int

    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1
    @GestureState private var gestureOffset: CGSize = .zero

    private var currentScale: CGFloat { min(max(scale * gestureScale, 1), 4) }
    private var hasRecordedPhoto: Bool { userImage != nil && !showGoal }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                image
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(currentScale)
                    .offset(x: offset.width + gestureOffset.width,
                            y: offset.height + gestureOffset.height)
                    .saturation(showGoal || hasRecordedPhoto ? 1 : 0.38)
                    .brightness(showGoal || hasRecordedPhoto ? 0 : -0.10)

                if !showGoal && !hasRecordedPhoto {
                    Color.black.opacity(max(0.05, 0.28 * (1 - Double(progress) / 100)))
                }

                Text(statusText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(Color.black.opacity(0.68), in: Capsule())
                    .padding(12)
            }
            .contentShape(Rectangle())
            .clipped()
            .gesture(zoomGesture.simultaneously(with: panGesture))
            .onTapGesture(count: 2) {
                withAnimation(.easeOut(duration: 0.2)) {
                    if scale > 1.05 { scale = 1; offset = .zero } else { scale = 2 }
                }
            }
        }
        .background(Color(red: 0.13, green: 0.14, blue: 0.13))
    }

    @ViewBuilder private var image: some View {
        if let userImage, !showGoal {
            Image(uiImage: userImage).resizable().scaledToFill()
        } else {
            Image(assetName).resizable().scaledToFill()
        }
    }

    private var statusText: String {
        if showGoal { return "СИНТЕТИЧЕСКИЙ РЕНДЕР" }
        if hasRecordedPhoto { return "ЛИЧНОЕ ФОТО · НА УСТРОЙСТВЕ" }
        return "ЗАПИСАННЫЙ ПРОГРЕСС · \(progress)%"
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureScale) { value, state, _ in state = value }
            .onEnded { value in
                scale = min(max(scale * value, 1), 4)
                if scale <= 1.01 { scale = 1; offset = .zero }
            }
    }

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .updating($gestureOffset) { value, state, _ in
                if currentScale > 1 { state = value.translation }
            }
            .onEnded { value in
                guard scale > 1 else { offset = .zero; return }
                offset.width += value.translation.width
                offset.height += value.translation.height
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
