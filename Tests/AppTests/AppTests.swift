@testable import App
import XCTVapor
import Fluent

final class AppTests: XCTestCase {
    var app: Application!
    
    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try await configure(app)
        try await app.autoMigrate()
    }
    
    override func tearDown() async throws { 
        try await app.autoRevert()
        try await self.app.asyncShutdown()
        self.app = nil
    }
    
    func testHelloWorld() async throws {
        try await self.app.test(.GET, "hello", afterResponse: { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "Hello, world!")
        })
    }
    
    func testPushRequestRegisted() async throws {
        let userID = UUID()
        let pushToken = "0000"
        var _pushRequestID: PushRequest.IDValue?
        
        /// First, we create a PushRequest
        try self.app.test(.POST, "push_request", beforeRequest: { req in
            let request = IncomingPushRequest(
                userID: userID,
                hour: 9,
                minute: 30,
                pushToken: pushToken
            )
            try req.content.encode(request)
        }, afterResponse: { res in
            XCTAssert(res.status == .ok)
            let response = try res.content.decode(PushRequest.self)
            XCTAssert(response.userID == userID)
            _pushRequestID = response.id
            XCTAssertNotNil(_pushRequestID)
        })

        /// Then, we change the time PushRequest
        try self.app.test(.POST, "push_request", beforeRequest: { req in
            let request = IncomingPushRequest(
                userID: userID,
                hour: 7,
                minute: 30,
                pushToken: pushToken
            )
            try req.content.encode(request)
        }, afterResponse: { res in
            XCTAssert(res.status == .ok)
            let response = try res.content.decode(PushRequest.self)
            XCTAssert(response.userID == userID)
            let newPushRequestID = try XCTUnwrap(response.id)
            XCTAssert(newPushRequestID == _pushRequestID)
        })

        /// Then we delete this PushRequest
        try self.app.test(.DELETE, "push_request", beforeRequest: { req in
            let request = IncomingDeleteRequest(userID: userID)
            try req.content.encode(request)
        }, afterResponse: { res in
            XCTAssert(res.status == .accepted)
        })

    }
}
