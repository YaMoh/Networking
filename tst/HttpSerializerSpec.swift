//
//  HttpSerializerSpec.swift
//
//  Created by Yaser on 2017-01-11.
//  Copyright © 2017 Bespoke Code Ltd. All rights reserved.
//

import XCTest

@testable import 

class HttpSerializerSpec: XCTestCase {
    
    private var testObject: HttpJsonSerializer?
    
    override func setUp() {
        super.setUp()
        
        testObject = HttpJsonSerializer()
    }
    
    /**
     *  When:   Attempting to serialize a serializable object
     *  Then:   The seialized data should be returned
     */
    func testSerializeSuccess() {
        let serializeObject = ["SomeString": "String",
                               "SomeInt": 1,
                               "SomeFloat": 0.5,
                               "SomeCGFloat": CGFloat(33)] as [String : Any]
        
        let data = try? testObject!.data(withObject: serializeObject)
        XCTAssert(data != nil)
    }
    
    /**
     *  When:   Attempting to serialize an unserializable object
     *  Then:   An exception should be thrown
     */
    func testSerializeFailure() {
        let unserializableObject = ["SomeClass": UnSerializable()] as [String : Any]
        
        do {
            _ = try testObject!.data(withObject: unserializableObject)
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }
    
    /**
     *  When:   Attempting to deserialize a deserializable object
     *  Then:   The deseialized data should be returned
     */
    func testDeSerializeSuccess() {
        let serializeObject = ["SomeString": "String",
                               "SomeInt": 1,
                               "SomeFloat": 0.5,
                               "SomeCGFloat": CGFloat(33)] as [String : Any]
        let data = try! JSONSerialization.data(withJSONObject: serializeObject, options: [])
        
        let deSerializedData = try! testObject!.object(with: data) as! [String : Any]
        XCTAssert(deSerializedData.count == serializeObject.count)
    }
    
    /**
     *  When:   Attempting to deserialize an undeserializable object
     *  Then:   An exception should be thrown
     */
    func testDeSerializeFailure() {
        let data = Data()
        
        do {
            _ = try testObject!.object(with: data) as! [String : Any]
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }
    
    
    func data(withObject object: Any) throws -> Data {
        return try JSONSerialization.data(withJSONObject: object, options: [])
    }
    
    func object(with data: Data) throws -> Any {
        return try JSONSerialization.jsonObject(with: data, options: [])
    }
}

fileprivate class UnSerializable { }

