import XCTest
import CoreGraphics
import GRDB

class CGFloatTests: GRDBTestCase {
    
    func testCGFLoat() {
        assertNoError {
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE points (x DOUBLE, y DOUBLE)")

                let x: CGFloat = 1
                let y: CGFloat? = nil
                try db.execute("INSERT INTO points VALUES (?,?)", arguments: [x, y])
                
                let row = Row.fetchOne(db, "SELECT * FROM points")!
                let fetchedX: CGFloat = row.value(named: "x")
                let fetchedY: CGFloat? = row.value(named: "y")
                XCTAssertEqual(x, fetchedX)
                XCTAssertTrue(fetchedY == nil)
            }
        }
    }
}
