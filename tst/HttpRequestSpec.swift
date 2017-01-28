//
//  HttpRequestSpec.swift
//
//  Created by Yaser on 2017-01-10.
//  Copyright © 2017 Bespoke Code Ltd. All rights reserved.
//

import XCTest
import Foundation

@testable import 

class HttpRequestSpec: XCTestCase {
    
    private var testObject: HttpRequest?
    
    private let testUrl = URL(string: "http://www.google.com")!
    private var testRequest: NSMutableURLRequest?
    private var testSession: TestURLSession?
    private var testSerializer: TestSerializer?
    private var testDelegate: TestDelegate?
    
    override func setUp() {
        super.setUp()
        
        testRequest = NSMutableURLRequest()
        testSession = TestURLSession()
        testSerializer = TestSerializer()
        testDelegate = TestDelegate()
        
        testObject = HttpRequest(url: testUrl,
                                 request: testRequest!,
                                 session: testSession!,
                                 serializer: testSerializer!)
    }
    
    /**
     *  When:   Setting the cache policy
     *  Then:   The provided request should change
     */
    func testSetCachePolicy() {
        testObject?.set(cachePolicy: .useProtocolCachePolicy)
        
        XCTAssert(testRequest?.cachePolicy == .useProtocolCachePolicy)
    }

    
    /**
     *  When:   Setting the http method
     *  Then:   The provided request should change
     */
    func testSetHttpMethod() {
        testObject?.set(method: .post)
        
        XCTAssert(testRequest?.httpMethod == HttpMethod.post.rawValue)
    }

    
    /**
     *  When:   Setting the timeout
     *  Then:   The provided request should change
     */
    func testSetTimeout() {
        let testTimeout: TimeInterval = 128
        testObject?.set(timeout: testTimeout)
        
        XCTAssert(testRequest?.timeoutInterval == testTimeout)
    }

    /**
     *  When:   Setting the headers
     *  Then:   The provided request should contain the headers
     */
    func testSendHeaders() {
        let headers = ["TestHeader1": "TestContent2"]
        
        testObject?.set(headers: headers)
  
        XCTAssert(testRequest?.allHTTPHeaderFields?.count == headers.count)
        for (key, value) in testRequest!.allHTTPHeaderFields! {
            XCTAssert(headers[key] == value)
        }
    }
    
    /**
     *  When:   Setting parameters
     *  Then:   The provided request should contain the parameters
     */
    func testSetParameters() {
        let parameters = ["TestParam1": "TestContent1",
                          "TestParam2": 2] as [String : Any]
        
        try! testObject?.set(parameters: parameters)
        
        XCTAssert(testRequest?.httpBody == testSerializer?.dataToReturn)
        
    }
    
    /**
     *  When:   Setting nil parameters
     *  Then:   The provided request should contain the parameters
     */
    func testSetNilParameters() {
        try! testObject?.set(parameters: nil)
        
        XCTAssert(testRequest?.httpBody == nil)
        
    }

    /**
     *  When:   Attempting to set invalid parameters
     *  Then:   The function should throw an exception
     */
    func testInvalidParameters() {
        let invalidParameters = ["SomeParameter": "invalid object"]
        
        testSerializer?.errorToThrow = TestError()
        do {
            try testObject?.set(parameters: invalidParameters)
            XCTFail() // Should throw due to invalid parameters
        } catch {
            XCTAssert(true)
        }
    }
    
    /**
     *  Given:  That a request have been sent
     *  When:   The request succeeds with valid data
     *  Then:   The provided success closure should be called with the response 
     *          data
     */
    func testSuccessCallbackValidData() {
        testObject?.set(delegate: testDelegate)
        testObject?.send()
        
        let successData = Data()
        let key = "hej"
        let value = "hallo"
        let deserializedResponse = [key: value]
        testSerializer?.objectToReturn = deserializedResponse
        testSession?.succeed(data: successData)
        
        XCTAssert(testSerializer!.dataReceived! == successData)
        XCTAssert(testDelegate!.successData![key] as! String == value)
        XCTAssert(testDelegate!.urlResponse == testSession?.urlResponseToReturn)
    }
    
    /**
     *  Given:  That a request have been sent
     *  When:   The request succeeds with invalid data
     *  Then:   The provided success closure should be called without any data
     */
    func testSuccessCallbackInvalidData() {
        testObject?.set(delegate: testDelegate)
        testObject?.send()
        
        let successData = Data()
        testSerializer?.errorToThrow = TestError()
        testSession?.succeed(data: successData)
        
        XCTAssert(testSerializer!.dataReceived! == successData)
        XCTAssert(testDelegate?.successData == nil)
        XCTAssert(testDelegate?.successCalled == true)
    }
    
    /**
     *  Given:  That a request have been sent
     *  When:   The request succeeds without data
     *  Then:   The provided success closure should be called without any data
     */
    func testSuccessCallbackNoData() {
        testObject?.set(delegate: testDelegate)
        testObject?.send()

        testSession?.succeed(data: nil)
        
        XCTAssert(testDelegate?.successData == nil)
        XCTAssert(testDelegate?.successCalled == true)
    }
    
    /**
     *  Given:  That a request have been sent
     *  When:   The request fails
     *  Then:   The provided failure closure should be called with the error
     */
    func testFailureCallback() {
        testObject?.set(delegate: testDelegate)
        testObject?.send()
        
        let testError = TestError()
        testSession?.failWithError(error: testError)
        
        XCTAssert(testDelegate?.error as! TestError === testError)
        XCTAssert(testDelegate?.urlResponse == testSession?.urlResponseToReturn)
    }
}

fileprivate class TestURLSession: URLSession {
    let dataTaskToReturn = TestDataTask()
    let urlResponseToReturn = TestURLResponse()
    
    var dataTaskUrl: URL?
    var completionHandler: ((Data?, URLResponse?, Error?) -> ())?
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        self.completionHandler = completionHandler
        
        return dataTaskToReturn
    }
    
    func succeed(data: Data?) {
        completionHandler?(data, urlResponseToReturn, nil)
    }
    
    func failWithError(error: Error) {
        completionHandler?(nil, urlResponseToReturn, error)
    }
}

fileprivate class TestDataTask: URLSessionDataTask {
    var resumeCalled = false
    
    override func resume() {
        resumeCalled = true
    }
}

fileprivate class TestSerializer: HttpSerializer {
    var dataToReturn: Data = Data()
    var objectReceived: Any?
    
    var objectToReturn: Any = 2
    var dataReceived: Data?
    
    var errorToThrow: Error?
    
    func data(withObject: Any) throws -> Data {
        objectReceived = withObject
        
        if let errorToThrow = errorToThrow {
            throw errorToThrow
        }
        
        return dataToReturn
    }
    
    func object(with: Data) throws -> Any {
        dataReceived = with
        
        if let errorToThrow = errorToThrow {
            throw errorToThrow
        }
        
        return objectToReturn
    }
}

fileprivate class TestDelegate: HttpRequestableDelegate {
    var successData: [String: Any]?
    var successCalled = false
    
    var error: Error?
    var failureCalled = false
    
    var urlResponse: HTTPURLResponse?
    
    func success(data: [String: Any]?, response: URLResponse?) {
        successData = data
        successCalled = true
        urlResponse = response as? HTTPURLResponse
    }
    
    func failure(error: Error?, response: URLResponse?) {
        self.error = error
        failureCalled = true
        urlResponse = response as? HTTPURLResponse
    }
}

fileprivate class TestError: Error { }


