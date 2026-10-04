import SwiftUI
import AVKit

struct ContentView: View {
    @EnvironmentObject var coordinator: InteractionCoordinator
    @State private var showPicker = false

    var body: some View {
        VStack(spacing: 20) {
            Text(coordinator.selectedName ?? "Point at a device")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.updatesFrequently)
            Text(coordinator.lastAction).foregroundStyle(.secondary)

            switch coordinator.phase {
            case .idle:
                Button("Start pointing") { coordinator.startPointing() }.buttonStyle(.borderedProminent)
                NavigationLink("Set up room") { RoomSetupView() }
            case .pointing:
                if coordinator.selectedName != nil {
                    ControlDialView()
                    HStack {
                        Button("On / Off") { coordinator.togglePower() }.buttonStyle(.bordered)
                        Button("No-look pinch") { coordinator.startNoLook() }.buttonStyle(.bordered)
                    }
                }
                Button("Stop") { coordinator.stop() }
            case .noLook:
                Text("Pinch in the air to switch it on or off.").multilineTextAlignment(.center)
                Button("Back to pointing") { coordinator.startPointing() }
            }

            if showPicker { AirPlayPicker().frame(width: 60, height: 60) }
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: .auraLinkShowAirPlayPicker)) { _ in showPicker = true }
    }
}

/// A large 270° dial driven by the thumb. Every 5% step plays a haptic tick.
struct ControlDialView: View {
    @EnvironmentObject var coordinator: InteractionCoordinator
    private let size: CGFloat = 240

    var body: some View {
        ZStack {
            Circle().trim(from: 0, to: 0.75)
                .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 22, lineCap: .round))
                .rotationEffect(.degrees(135))
            Circle().trim(from: 0, to: 0.75 * coordinator.dial.value)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 22, lineCap: .round))
                .rotationEffect(.degrees(135))
            Text("\(Int((coordinator.dial.value * 100).rounded()))%").font(.system(size: 44, weight: .bold))
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    let dx = g.location.x - size / 2, dy = g.location.y - size / 2
                    // Angle from the top of the dial, clockwise positive.
                    let degrees = atan2(dx, -dy) * 180 / .pi
                    coordinator.dialMoved(to: DetentDial.position(forAngleDegrees: degrees))
                }
                .onEnded { _ in coordinator.dialReleased() }
        )
        .accessibilityElement()
        .accessibilityLabel("Brightness")
        .accessibilityValue("\(Int((coordinator.dial.value * 100).rounded())) percent")
        .accessibilityAdjustableAction { direction in
            let step = direction == .increment ? 0.05 : -0.05
            coordinator.dialMoved(to: coordinator.dial.value + step)
        }
    }
}

/// Room setup: aim at each accessory and tap to drop an anchor at that spot.
struct RoomSetupView: View {
    @EnvironmentObject var coordinator: InteractionCoordinator
    @State private var spotName = ""
    var body: some View {
        List {
            Section("Devices") {
                ForEach(coordinator.anchors.unplacedAccessories, id: \.id) { accessory in
                    Button("Place \(accessory.name) where I'm pointing") {
                        coordinator.anchors.placeAnchor(for: accessory)
                    }
                }
            }
            Section("Spots for Apple Watch") {
                TextField("Where you're standing, e.g. Sofa", text: $spotName)
                Button("Save this spot") { coordinator.saveSpot(named: spotName); spotName = "" }
                    .disabled(spotName.isEmpty)
            }
        }
        .navigationTitle("Set up room")
        .onAppear { coordinator.anchors.start() }
        .onDisappear {
            coordinator.anchors.saveWorldMap()
            coordinator.syncRoomMapToWatch()
        }
    }
}

struct AirPlayPicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView { AVRoutePickerView() }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
