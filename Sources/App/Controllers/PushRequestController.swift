import Vapor
import Fluent

struct PushRequestController: RouteCollection, Sendable {
    
    func boot(routes: any Vapor.RoutesBuilder) throws {
        let requests = routes.grouped("push_request")
        requests.post(use: create)
        requests.delete(use: delete)
    }
    
    @Sendable
    private func create(req: Request) async throws -> PushRequest {
        let incomingPushRequest = try req.content.decode(IncomingPushRequest.self)
        let _pushRequest: PushRequest
        if let pushRequest = try await PushRequest.fromUserID(incomingPushRequest.userID, on: req.db) {
            _pushRequest = pushRequest
            pushRequest.hour = incomingPushRequest.hour
            pushRequest.minute = incomingPushRequest.minute
            pushRequest.pushToken = incomingPushRequest.pushToken
        } else {
            _pushRequest = .init(userID: incomingPushRequest.userID, pushToken: incomingPushRequest.pushToken, hour: incomingPushRequest.hour, minute: incomingPushRequest.minute)
        }        
        try await _pushRequest.save(on: req.db)
        return _pushRequest
    }
    
    @Sendable
    private func delete(req: Request) async throws -> HTTPStatus {
        let incomingDeleteRequest = try req.content.decode(IncomingDeleteRequest.self)
        if let pushRequest = try await PushRequest.fromUserID(incomingDeleteRequest.userID, on: req.db) {
            try await pushRequest.delete(on: req.db)
        }
        return .accepted
    }
    
}

public struct IncomingPushRequest: Content {
    public let userID: UUID
    public let hour: Int
    public let minute: Int
    public let pushToken: String
}

public struct IncomingDeleteRequest: Content {    
    public let userID: UUID
}
