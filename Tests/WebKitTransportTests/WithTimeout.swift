import Foundation

struct TimeoutError: Error {}

/// - Note: Loosely based on <https://forums.swift.org/t/running-an-async-task-with-a-timeout/49733>
func withTimeout<T: Sendable>(
	_ seconds: TimeInterval,
	@_inheritActorContext _ body: @escaping @Sendable () async throws -> T
) async throws -> T {
	try await withThrowingTaskGroup(of: T.self) { group in
		group.addTask {
			return try await body()
		}

		group.addTask {
			try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))

			throw TimeoutError()
		}

		defer { group.cancelAll() }

		guard let result = try await group.next() else {
			throw TimeoutError()
		}

		return result
	}
}

