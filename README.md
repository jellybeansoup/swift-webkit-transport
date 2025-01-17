# WebKitTransport

A mechanism for loading and processing web pages along with their XHR payloads, utilising an off-screen `WKWebView` wrapped into a single interface that fully supports structured concurrency.

## Features
- Supports macOS and iOS.
- Interact with web content using structured concurrency (async/await) and AsyncSequence.
- Transparently fetch remote content and seamlessly process HTML, JavaScript, and in-page network requests via `WKWebView`.

## Installation

In your `Package.swift` Swift Package Manager manifest, add the following dependency to your `dependencies` argument:

```swift
.package(url: "https://github.com/jellybeansoup/swift-webkit-transport.git", from: "1.0.0"),
```

Add the dependency to any targets you've declared in your manifest:

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "WebKitTransport", package: "swift-webkit-transport"),
    ]
),
```

## License

This project is licensed under the BSD 2-Clause "Simplified" License. See the [LICENSE](LICENSE) file for details.
