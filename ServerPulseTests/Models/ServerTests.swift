import Testing
@testable import ServerPulse

@Suite("Server Model Tests")
struct ServerTests {
    @Test func testServerInitDefaults() {
        let server = Server(name: "TestPi", hostname: "192.168.1.100")

        #expect(server.name == "TestPi")
        #expect(server.hostname == "192.168.1.100")
        #expect(server.port == 22)
        #expect(server.username == "pi")
        #expect(server.authMethod == .password)
        #expect(server.dockerEnabled == true)
        #expect(server.pollingInterval == 5)
        #expect(server.connectionTimeout == 10)
        #expect(server.keepAliveInterval == 30)
        #expect(server.isEnabled == true)
        #expect(server.connectionState == .disconnected)
    }

    @Test func testServerCustomInit() {
        let server = Server(
            name: "Prod",
            hostname: "10.0.0.1",
            port: 2222,
            username: "admin",
            authMethod: .key,
            dockerEnabled: false
        )

        #expect(server.port == 2222)
        #expect(server.username == "admin")
        #expect(server.authMethod == .key)
        #expect(server.dockerEnabled == false)
    }

    @Test func testConnectionStates() {
        let server = Server(name: "Test", hostname: "localhost")

        #expect(server.connectionState == .disconnected)

        server.connectionState = .connecting
        #expect(server.connectionState == .connecting)

        server.connectionState = .connected
        #expect(server.connectionState == .connected)

        server.connectionState = .error
        #expect(server.connectionState == .error)
    }
}
