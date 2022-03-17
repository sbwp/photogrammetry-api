import Vapor

func routes(_ app: Application) throws {
    // Note: EventLoopFuture is a temporary solution to use async/await until Vapor 5 completes async/await integration
    app.get("photogrammetry") { req async -> String in
        guard let result = await doObjectCapture() else {
            return "It failed!"
        }
        return "It works!"
    }

    app.get("health") { req -> String in
        return "Up!"
    }
}
