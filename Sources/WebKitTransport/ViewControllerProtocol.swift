import Foundation

@MainActor
protocol ViewControllerProtocol: AnyObject, Sendable {

	func load(data: Data, response: URLResponse) -> AsyncStream<WebKitTask.Payload>

	func stopLoading()

}
