// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import Foundation
import SwiftUI
import WebKitTransport

struct Transport {

	typealias LoadHandler = (_ url: URL) -> any AsyncSequence<Payload, any Error>

	var load: LoadHandler

	init(load: @escaping LoadHandler) {
		self.load = load
	}

	static let previews = Transport(
		load: { url in
			AsyncThrowingStream { continuation in
				Task {
					try? await Task.sleep(nanoseconds: 1_000_000_000)

					for payload in Payload.previews {
						continuation.yield(payload)

						try? await Task.sleep(nanoseconds: 250_000_000)
					}

					continuation.finish()
				}
			}
		}
	)

	static let live = Transport(
		load: { url in
			AsyncThrowingStream { continuation in
				Task {
					do {
						for await (data, response) in try await WebKitTask.load(url) {
							continuation.yield(.init(data: data, response: response, relativeTo: url))
						}

						continuation.finish()
					}
					catch {
						continuation.finish(throwing: error)
					}
				}
			}
		}
	)

}

struct TransportKey: EnvironmentKey {

	static let defaultValue: Transport = .previews

}

extension EnvironmentValues {

	var transport: Transport {
		get { self[TransportKey.self] }
		set { self[TransportKey.self] = newValue }
	}

}
