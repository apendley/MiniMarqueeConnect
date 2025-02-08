//
//  NetworkClient.swift
//
//  ISC Licence
//
//  Copyright (c) 2025 Aaron Pendley
//
//  Permission to use, copy, modify, and/or distribute this software for any purpose with or
//  without fee is hereby granted, provided that the above copyright notice and this permission
//  notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
//  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

import Foundation

// HTTP Network client with configurable host and url session
struct NetworkClient {
    let host: URL
    
    private let urlSession: URLSession
    private let successRange = (200...299)
    
    enum ResponseError: Error {
        case badResponse
        case statusError(code: Int)
    }
    
    init(host: URL, urlSession: URLSession = URLSession.shared) {
        self.host = host
        self.urlSession = urlSession
    }
    
    func data(from path: String) async throws -> Data {
        let url = host.appending(path: path)
        let result = try await urlSession.data(from: url)
        return try unpack(result: result)
    }
    
    func post(data: Data, to path: String, contentType: String) async throws -> Data {
        let url = host.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let result = try await urlSession.data(for: request)
        return try unpack(result: result)
    }

    private func unpack(result: (Data, URLResponse)) throws -> Data {
        guard let (data, response) = result as? (Data, HTTPURLResponse) else {
            throw ResponseError.badResponse
        }
        
        guard successRange.contains(response.statusCode) else {
            throw ResponseError.statusError(code: response.statusCode)
        }
                
        return data
    }
}

// JSON helpers
extension NetworkClient {
    func json<ResponseType: Decodable>(_ responseType: ResponseType.Type = ResponseType.self,
                            from path: String,
                            with decoder: JSONDecoder = .init()
    ) async throws -> ResponseType {
        let data = try await data(from: path)
        return try decoder.decode(responseType, from: data)
    }
    
    func post<ParamType: Encodable, ResponseType: Decodable>(json: ParamType,
                                                             to path: String,
                                                             with encoder: JSONEncoder = .init(),
                                                             responseType: ResponseType.Type = ResponseType.self,
                                                             responseDecoder: JSONDecoder = .init()
    ) async throws -> ResponseType {
        let encoded = try encoder.encode(json)
        let data = try await post(data: encoded, to: path, contentType: "application/json")
        return try responseDecoder.decode(responseType, from: data)
    }
}
