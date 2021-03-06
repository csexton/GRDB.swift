import XCTest
import GRDB

class DetachedRowTests: GRDBTestCase {
    
    func testRowAsSequence() {
        assertNoError {
            let dbQueue = DatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE ints (a INTEGER, b INTEGER, c INTEGER)")
                try db.execute("INSERT INTO ints (a,b,c) VALUES (0, 1, 2)")
                let row = Row.fetchOne(db, "SELECT * FROM ints")!
                
                var columnNames = [String]()
                var ints = [Int]()
                var bools = [Bool]()
                for (columnName, databaseValue) in row {
                    columnNames.append(columnName)
                    ints.append(databaseValue.value() as Int)
                    bools.append(databaseValue.value() as Bool)
                }
                
                XCTAssertEqual(columnNames, ["a", "b", "c"])
                XCTAssertEqual(ints, [0, 1, 2])
                XCTAssertEqual(bools, [false, true, true])
            }
        }
    }
    
    func testRowValueAtIndex() {
        assertNoError {
            let dbQueue = DatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE ints (a INTEGER, b INTEGER, c INTEGER)")
                try db.execute("INSERT INTO ints (a,b,c) VALUES (0, 1, 2)")
                let row = Row.fetchOne(db, "SELECT * FROM ints")!
                
                // Int extraction, form 1
                XCTAssertEqual(row.value(atIndex: 0) as Int, 0)
                XCTAssertEqual(row.value(atIndex: 1) as Int, 1)
                XCTAssertEqual(row.value(atIndex: 2) as Int, 2)
                
                // Int extraction, form 2
                XCTAssertEqual(row.value(atIndex: 0)! as Int, 0)
                XCTAssertEqual(row.value(atIndex: 1)! as Int, 1)
                XCTAssertEqual(row.value(atIndex: 2)! as Int, 2)
                
                // Int? extraction
                XCTAssertEqual((row.value(atIndex: 0) as Int?), 0)
                XCTAssertEqual((row.value(atIndex: 1) as Int?), 1)
                XCTAssertEqual((row.value(atIndex: 2) as Int?), 2)
                
                // Bool extraction, form 1
                XCTAssertEqual(row.value(atIndex: 0) as Bool, false)
                XCTAssertEqual(row.value(atIndex: 1) as Bool, true)
                XCTAssertEqual(row.value(atIndex: 2) as Bool, true)
                
                // Bool extraction, form 2
                XCTAssertEqual(row.value(atIndex: 0)! as Bool, false)
                XCTAssertEqual(row.value(atIndex: 1)! as Bool, true)
                XCTAssertEqual(row.value(atIndex: 2)! as Bool, true)
                
                // Bool? extraction
                XCTAssertEqual((row.value(atIndex: 0) as Bool?), false)
                XCTAssertEqual((row.value(atIndex: 1) as Bool?), true)
                XCTAssertEqual((row.value(atIndex: 2) as Bool?), true)
                
                // Expect fatal error:
                //
                // row.value(atIndex: -1)
                // row.value(atIndex: 3)
            }
        }
    }
    
    func testRowValueNamed() {
        assertNoError {
            let dbQueue = DatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE ints (a INTEGER, b INTEGER, c INTEGER)")
                try db.execute("INSERT INTO ints (a,b,c) VALUES (0, 1, 2)")
                let row = Row.fetchOne(db, "SELECT * FROM ints")!
                
                // Int extraction, form 1
                XCTAssertEqual(row.value(named: "a") as Int, 0)
                XCTAssertEqual(row.value(named: "b") as Int, 1)
                XCTAssertEqual(row.value(named: "c") as Int, 2)
                
                // Int extraction, form 2
                XCTAssertEqual(row.value(named: "a")! as Int, 0)
                XCTAssertEqual(row.value(named: "b")! as Int, 1)
                XCTAssertEqual(row.value(named: "c")! as Int, 2)
                
                // Int? extraction
                XCTAssertEqual((row.value(named: "a") as Int?)!, 0)
                XCTAssertEqual((row.value(named: "b") as Int?)!, 1)
                XCTAssertEqual((row.value(named: "c") as Int?)!, 2)
                
                // Bool extraction, form 1
                XCTAssertEqual(row.value(named: "a") as Bool, false)
                XCTAssertEqual(row.value(named: "b") as Bool, true)
                XCTAssertEqual(row.value(named: "c") as Bool, true)
                
                // Bool extraction, form 2
                XCTAssertEqual(row.value(named: "a")! as Bool, false)
                XCTAssertEqual(row.value(named: "b")! as Bool, true)
                XCTAssertEqual(row.value(named: "c")! as Bool, true)
                
                // Bool? extraction
                XCTAssertEqual((row.value(named: "a") as Bool?)!, false)
                XCTAssertEqual((row.value(named: "b") as Bool?)!, true)
                XCTAssertEqual((row.value(named: "c") as Bool?)!, true)
                
                // Expect fatal error:
                // row.value(named: "foo")
                // row.value(named: "foo") as Int?
            }
        }
    }
    
    func testRowCount() {
        assertNoError {
            let dbQueue = DatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE ints (a INTEGER, b INTEGER, c INTEGER)")
                try db.execute("INSERT INTO ints (a,b,c) VALUES (0, 1, 2)")
                let row = Row.fetchOne(db, "SELECT * FROM ints")!
                
                XCTAssertEqual(row.count, 3)
            }
        }
    }
    
    func testRowColumnNames() {
        assertNoError {
            let dbQueue = DatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE ints (a INTEGER, b INTEGER, c INTEGER)")
                try db.execute("INSERT INTO ints (a,b,c) VALUES (0, 1, 2)")
                let row = Row.fetchOne(db, "SELECT a, b, c FROM ints")!
                
                XCTAssertEqual(Array(row.columnNames), ["a", "b", "c"])
            }
        }
    }
    
    func testRowDatabaseValues() {
        assertNoError {
            let dbQueue = DatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE ints (a INTEGER, b INTEGER, c INTEGER)")
                try db.execute("INSERT INTO ints (a,b,c) VALUES (0, 1, 2)")
                let row = Row.fetchOne(db, "SELECT a, b, c FROM ints")!
                
                XCTAssertEqual(Array(row.databaseValues), [0.databaseValue, 1.databaseValue, 2.databaseValue])
            }
        }
    }
    
    func testRowSubscriptIsCaseInsensitive() {
        assertNoError {
            let dbQueue = DatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE stuffs (name TEXT)")
                try db.execute("INSERT INTO stuffs (name) VALUES ('foo')")
                let row = Row.fetchOne(db, "SELECT nAmE FROM stuffs")!
                XCTAssertEqual(row["name"], "foo".databaseValue)
                XCTAssertEqual(row["NAME"], "foo".databaseValue)
                XCTAssertEqual(row["NaMe"], "foo".databaseValue)
                XCTAssertEqual(row.value(named: "name") as String, "foo")
                XCTAssertEqual(row.value(named: "NAME") as String, "foo")
                XCTAssertEqual(row.value(named: "NaMe") as String, "foo")
            }
        }
    }
    
    func testRowHasColumnIsCaseInsensitive() {
        assertNoError {
            let dbQueue = DatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE stuffs (name TEXT)")
                try db.execute("INSERT INTO stuffs (name) VALUES ('foo')")
                let row = Row.fetchOne(db, "SELECT nAmE, 1 AS foo FROM stuffs")!
                XCTAssertTrue(row.hasColumn("name"))
                XCTAssertTrue(row.hasColumn("NAME"))
                XCTAssertTrue(row.hasColumn("Name"))
                XCTAssertTrue(row.hasColumn("NaMe"))
                XCTAssertTrue(row.hasColumn("foo"))
                XCTAssertTrue(row.hasColumn("Foo"))
                XCTAssertTrue(row.hasColumn("FOO"))
            }
        }
    }
}
