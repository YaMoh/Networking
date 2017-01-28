//
//  HttpSerializer.swift
//
//  Created by Yaser on 2017-01-11.
//  Copyright © 2017 Bespoke Code Ltd. All rights reserved.
//

import Foundation

/**
 *
 */
protocol HttpSerializer: class {
    func data(withObject: Any) throws -> Data
    func object(with: Data) throws -> Any
}

enum HttpSerializerErrors: Error {
    case invalidArgumentException
}

final class HttpJsonSerializer: HttpSerializer {
    
    func data(withObject object: Any) throws -> Data {
        if JSONSerialization.isValidJSONObject(object) {
            return try JSONSerialization.data(withJSONObject: object, options: [])
        }
        
        throw HttpSerializerErrors.invalidArgumentException
    }
    
    func object(with data: Data) throws -> Any {
        do {
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            throw HttpSerializerErrors.invalidArgumentException
        }
    }
}
