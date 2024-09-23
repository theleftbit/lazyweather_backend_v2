import NIOSSL
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    try app.register(collection: PushRequestController())

#if os(macOS)
    app.databases.use(.sqlite(.memory), as: .sqlite)
#else
    try app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(url: Environment.get("DATABASE_URL") ?? "localhost")), as: .psql)
#endif

    app.migrations.add(PushRequest.Migration())

    try await app.autoMigrate()

    // register routes
    try routes(app)
}
