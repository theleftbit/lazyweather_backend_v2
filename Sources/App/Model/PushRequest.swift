import Fluent
import Vapor

final class PushRequest: Model, Content, @unchecked Sendable {
    
    static let schema = "push_request"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "hour")
    var hour: Int
    
    @Field(key: "minute")
    var minute: Int

    @Field(key: "user_id")
    var userID: UUID

    @Field(key: "push_token")
    var pushToken: String
    
    init() { }
    
    init(id: UUID? = nil, userID: UUID, pushToken: String, hour: Int, minute: Int) {
        self.id = id
        self.hour = hour
        self.pushToken = pushToken
        self.userID = userID
        self.minute = minute
    }

    struct Migration: AsyncMigration {
      func prepare(on database: Database) async throws {
        try await database.schema(PushRequest.schema)
          .id()
          .field("hour", .int64, .required)
          .field("minute", .int64, .required)
          .field("user_id", .uuid, .required)
          .field("push_token", .string, .required)
          .create()
      }
      
      func revert(on database: Database) async throws {
        try await database.schema(PushRequest.schema).delete()
      }
    }
    
    static func fromUserID(_ userID: UUID, on db: any Database) async throws -> PushRequest? {
        try await PushRequest.query(on: db)
            .filter(\.$userID == userID)
            .first()
    }

    static func allRequestsAt(hour: Int, minute: Int, on db: any Database) async throws -> [PushRequest] {
        try await PushRequest.query(on: db)
            .filter(\.$hour == hour)
            .filter(\.$minute == minute)
            .all()
    }
}
