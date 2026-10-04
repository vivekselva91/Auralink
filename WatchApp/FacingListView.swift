import SwiftUI
import AuraLinkCore

/// The list that "rises up": devices in the direction you're facing, closest first.
/// Double-tap (Apple Watch Series 9 and later) opens the top device.
struct FacingListView: View {
    @EnvironmentObject var model: WatchModel

    var body: some View {
        List {
            if model.inFront.isEmpty {
                Text("Face a device").foregroundStyle(.secondary)
            }
            ForEach(Array(model.inFront.enumerated()), id: \.element.device.id) { index, item in
                NavigationLink {
                    DeviceControlView(id: item.device.id, name: item.device.name)
                } label: {
                    HStack {
                        Text(item.device.name).font(index == 0 ? .headline : .body)
                        Spacer()
                        Text(arrow(item.offsetDegrees)).foregroundStyle(.orange)
                    }
                }
                .handGestureShortcut(.primaryAction, isEnabled: index == 0)
            }
            if model.spots.count > 1 {
                Picker("I'm at", selection: $model.currentSpot) {
                    ForEach(model.spots, id: \.name) { Text($0.name).tag(Optional($0)) }
                }
            }
        }
        .navigationTitle("AuraLink")
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    private func arrow(_ offset: Double) -> String {
        switch HapticDirection.zone(forOffsetDegrees: offset) {
        case .ahead: return "Ahead"
        case .left: return "Left"
        case .right: return "Right"
        case .behind: return "Behind"
        }
    }
}

extension RoomMap.Spot: Hashable {
    static func == (a: RoomMap.Spot, b: RoomMap.Spot) -> Bool { a.name == b.name }
    func hash(into h: inout Hasher) { h.combine(name) }
}
