//
//  StatusBar.swift
//  MSI Display Switch
//
//  Created by Валерий Агишев on 09.01.2025.
//

import SwiftUI

struct StatusBar: Scene {
    var onHdmi1: () -> Void
    var onHdmi2: () -> Void
    var onDisplayPort: () -> Void
    var onTypeC: () -> Void
    
    @State private var _connected: Bool = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some Scene {
        MenuBarExtra("a", systemImage: "gift.circle") {
            VStack {
                Button("DisplayPort") { self.onDisplayPort() }
                    .disabled(!self._connected)
                Button("HDMI 1") { self.onHdmi1() }
                    .disabled(!self._connected)
                Button("HDMI 2") { self.onHdmi2() }
                    .disabled(!self._connected)
                Button("Type-C") { self.onTypeC() }
                    .disabled(!self._connected)
                Divider()
                Button("Exit") { NSApplication.shared.terminate(nil) }
            }
            .onReceive(timer, perform: { _ in
                self._connected = DisplayController.singleton.isConnected
            })
        }
    }
}
