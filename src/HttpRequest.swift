//
//  HttpRequest.swift
//  [PROJECT]
//
//  Created by Yaser on 2017-01-10.
//  Copyright © 2017 Bespoke Code Ltd. All rights reserved.
//

import Foundation

enum HttpMethod: String {
    case post = "POST"
    case get = "GET"
}

protocol HttpRequestableDelegate: class {
    func success(data: [String: Any]?, response: URLResponse?)
    func failure(error: Error?, response: URLResponse?)
}

protocol HttpRequestable {
    func set(delegate: HttpRequestableDelegate?)
    func send()
}

class HttpRequest: HttpRequestable {
    
    private let standardTimeoutInterval: TimeInterval = 10
    
    private let request: NSMutableURLRequest
    private let session: URLSession
    private let serializer: HttpSerializer
    
    private weak var delegate: HttpRequestableDelegate?
    
    init(url: URL,
         request: NSMutableURLRequest = NSMutableURLRequest(),
         session: URLSession = URLSession.shared,
         serializer: HttpSerializer = HttpJsonSerializer()) {
        
        request.url = url
        request.httpMethod = HttpMethod.post.rawValue
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = standardTimeoutInterval
    
        self.request = request
        self.session = session
        self.serializer = serializer
    }
    
    func set(cachePolicy: NSURLRequest.CachePolicy) {
        request.cachePolicy = cachePolicy
    }
    
    func set(method: HttpMethod) {
        request.httpMethod = method.rawValue
    }
    
    func set(timeout: TimeInterval) {
        request.timeoutInterval = timeout
    }
    
    func set(headers: [String: String]?) {
        guard let headers = headers else {
            return
        }
        
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
    }
    
    func set(parameters: [String: Any]?) throws {
        guard let parameters = parameters else {
            return
        }
        
        do {
            let data = try serializer.data(withObject: parameters)
            request.httpBody = data
        } catch let error {
            throw error
        }
    }
    
    func set(delegate: HttpRequestableDelegate?) {
        self.delegate = delegate
    }
    
    func send() {
        let task = session.dataTask(with: request as URLRequest, completionHandler: requestCompleted)
        task.resume()
    }
    
    private func requestCompleted(data: Data?, response: URLResponse?, error: Error?) {
        if error != nil {
            delegate?.failure(error: error, response: response as? HTTPURLResponse)
        } else {
            let deSerialized = deSerialize(data: data)
            delegate?.success(data: deSerialized, response: response as? HTTPURLResponse)
        }
    }
    
    private func deSerialize(data: Data?) -> [String: Any]? {
        guard let data = data else {
            return nil
        }
        
        do {
            let dictionary = try serializer.object(with: data) as? [String: Any]
            return dictionary
        } catch {
            NSLog("Unable to deserialize data")
        }
        
        return nil
    }
}
