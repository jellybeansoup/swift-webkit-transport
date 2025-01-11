import Foundation

struct HTTPError: Error {

	var statusCode: Int

}

extension HTTPError: CustomNSError {

	var errorCode: Int {
		statusCode
	}

}

extension URLResponse {

	var httpError: HTTPError? {
		guard
			let httpResponse = self as? HTTPURLResponse,
			(400...599).contains(httpResponse.statusCode)
		else {
			return nil
		}

		return .init(statusCode: httpResponse.statusCode)
	}

}
