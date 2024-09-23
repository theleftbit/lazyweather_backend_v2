import NIOSSL
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import Vapor
import QueuesFluentDriver

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
    app.migrations.add(JobMetadataMigrate())

    try await app.autoMigrate()

    app.queues.use(.fluent())
    app.queues.schedule(SendPushJob())
        .minutely()
        .at(0)
    try app.queues.startInProcessJobs(on: .default)
    try app.queues.startScheduledJobs()

    // register routes
    try routes(app)
}
