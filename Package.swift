// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-webkit-transport",
	platforms: [
		.iOS(.v14),
		.macOS(.v11),
	],
    products: [
        .library(
            name: "WebKitTransport",
			targets: ["WebKitTransport"]
		),
    ],
    targets: [
        .target(
			name: "WebKitTransport"
		),
        .testTarget(
            name: "WebKitTransportTests",
            dependencies: ["WebKitTransport"]
        ),
    ]
)
