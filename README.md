# WebKitTransport

A mechanism for loading and processing web pages along with their XHR payloads, utilising an off-screen `WKWebView` wrapped into a single interface that fully supports structured concurrency.

## Features
- Supports macOS and iOS.
- Interact with web content using structured concurrency (async/await) and AsyncSequence.
- Transparently fetch remote content and seamlessly process HTML, JavaScript, and in-page network requests via `WKWebView`.

### Why would anyone want this?

APIs are fickle creatures, and sometimes features present on websites are not available in the sanctioned third-party API. Sometimes there is no API! Sometimes you just want to scrape webpages because you're just built _different_. In any case, websites these days are loaded with javascript that can substantially alter the content of a page after the initial source is loaded, and in some case this is the difference between having content and _not_ having content.

In all of these instances, including the one where you just want to bend the internet to your whims, this library can be more useful than a plain `URLSession` data task, because it automatically loads the content and handles the JavaScript using WebKit, giving you all of the contents loaded with XMLHTTPRequests (private APIs, anyone?), and all of the different states of the webpage (until the timeout expires). It's not magic, but it's up there with a really good pastry.    

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

## Usage

Loading a webpage and listening to mutations and/or XHR responses is as easy as passing the appropriate URL into the `WebKitTask.load(_:)` method. There's also a variation of this method which can take a `URLRequest`, and both methods can take an optional `URLSession` and timeout, which allows complete control over how the system loads the content.

> **Note:** The given `URLSession` is used only for the _initial_ page load. After that, WebKit's internals handle subsequent loads. This may cause issues if you're attempting to use a custom `URLSession` to provide access to content behind an authentication, as the underlying `WKWebView` is ephemeral, and does not share any context with the given `URLSession`.

The page is first loaded using the given `URLSession`, and then, if the response is HTML, it's loaded into a hidden `WKWebView`, allowing JavaScript to execute and additional responses to be passed through via an `AsyncSequence`.

```swift
let url = URL(string: "https://example.com")!

for await (data, response) in try await WebKitTask.load(url, urlSession: customSession, timeout: 5) {
	// Process the data and/or `URLResponse`
}
```

If you'd like even more control over what is loaded into the `WKWebView`, you can also pass some `Data` and a `URLResponse` to load it directly into the hidden browser.  

```swift
let inputData = Data(#"<!DOCTYPE html><html>...</html>"#.utf8)
let inputResponse = URLResponse(
	url: URL(string: "http//example.com")!,
	mimeType: "text/html",
	expectedContentLength: inputData.count,
	textEncodingName: "UTF-8"
)

for try await (data, response) in WebKitTask.load(data: data, response: response, timeout: 5) {
	// Process the data and/or `URLResponse`
}
```

## License

This project is licensed under the BSD 2-Clause "Simplified" License. See the [LICENSE](LICENSE) file for details.
