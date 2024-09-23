import Queues
import Vapor

struct SendPushJob: AsyncScheduledJob {

    func run(context: Queues.QueueContext) async throws {
        let (hour, minute) = try getCurrentHourAndMinute()
        let allRequests = try await PushRequest.allRequestsAt(hour: hour, minute: minute, on: context.application.db)
        await withTaskGroup(of: Void.self) { group in
            for request in allRequests {
                group.addTask {
                    await sendPush(request: request, app: context.application)
                }
            }
        }
    }
    
    func sendPush(request: PushRequest, app: Application) async {
        // TODO:
        print("Sending push to \(request.pushToken)")
    }
    
    private func getCurrentHourAndMinute() throws -> (hour: Int, minute: Int) {
        let calendar = Calendar.platformCalendar
        let components = calendar.dateComponents([.hour, .minute], from: .init())
        guard let hour = components.hour, let minute = components.minute else {
            throw Abort(.notFound)
        }
        return (hour, minute)
    }
}

extension Calendar {
    static var platformCalendar: Calendar {
        var calendar = Calendar.current
        #if os(macOS)
        calendar.timeZone = .gmt
        #else
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        #endif
        return calendar
    }
}
