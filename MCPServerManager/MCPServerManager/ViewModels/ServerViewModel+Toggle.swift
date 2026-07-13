import Foundation

extension ServerViewModel {
    func toggleServer(_ server: ServerModel) {
        setServer(server, enabled: !server.enabled)
    }

    func setServer(_ server: ServerModel, enabled: Bool) {
        guard let index = servers.firstIndex(where: { $0.id == server.id }),
              servers[index].enabled != enabled else { return }

        let now = Date()
        servers[index].enabled = enabled
        servers[index].updatedAt = now
        servers[index].lastToggledAt = now
        syncToConfigs()

        let status = enabled ? "enabled" : "disabled"
        showToast(message: "\(server.name) \(status)", type: .success)
    }

    func toggleAllServers(_ enable: Bool) {
        let now = Date()

        for index in servers.indices {
            let didChange = servers[index].enabled != enable
            servers[index].enabled = enable
            servers[index].updatedAt = now
            if didChange {
                servers[index].lastToggledAt = now
            }
        }

        objectWillChange.send()
        syncToConfigs()

        let status = enable ? "enabled" : "disabled"
        showToast(message: "All servers \(status)", type: .success)
    }
}
