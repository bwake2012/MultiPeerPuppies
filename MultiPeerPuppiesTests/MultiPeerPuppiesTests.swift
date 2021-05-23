//
//  MultiPeerPuppiesTests.swift
//  MultiPeerPuppiesTests
//
//  Created by Bob Wakefield on 5/29/19.
//  Copyright © 2019 Bob Wakefield. All rights reserved.
//

import XCTest
@testable import MultiPeerPuppies

class MultiPeerPuppiesTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testArchivedUIImages() {

        let originalImage = UIImage(named: "Buddy.png")

        XCTAssertNotNil(originalImage)

        let sessionCoordinator = PeerSessionCoordinator()

        let data = sessionCoordinator.archiveImage(image: originalImage!)
        XCTAssertNotNil(data)

        let unarchivedImage = sessionCoordinator.unarchiveImage(data: data!)

        XCTAssertEqual(unarchivedImage?.pngData(), originalImage?.pngData())
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
