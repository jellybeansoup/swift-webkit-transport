// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import Foundation

extension Payload {

	static var previews: [Payload] = [
		Payload(
			data: Data("""
				{
					data: []
				}
				""".utf8),
			response: HTTPURLResponse(
				url: URL(string: "https://example.com/api/v1/items")!,
				statusCode: 200,
				httpVersion: "HTTP/1.1",
				headerFields: [
					"Content-Encoding": "gzip",
					"Content-Type": "application/json; charset=utf-8",
					"Date": "Sat, 01 Jan 2000 00:00:00 GMT",
				]
			)!,
			relativeTo: URL(string: "https://example.com")
		),
		Payload(
			data: Data("""
				<!DOCTYPE html>
				<html lang="en">
				<head>
					<meta charset="utf-8">
					<title>Example</title>
				</head>
				<body>
					<h1>Hello world!</h1>
				</body>
				</html>
				""".utf8),
			response: HTTPURLResponse(
				url: URL(string: "https://example.com")!,
				statusCode: 200,
				httpVersion: "HTTP/1.1",
				headerFields: [
					"Content-Encoding": "gzip",
					"Content-Type": "text/html; charset=utf-8",
					"Date": "Sat, 01 Jan 2000 00:00:00 GMT",
				]
			)!,
			relativeTo: URL(string: "https://example.com")
		),
	]

}
