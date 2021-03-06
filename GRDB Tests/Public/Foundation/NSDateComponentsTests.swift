import XCTest
import GRDB

class NSDateComponentsTests : GRDBTestCase {
    
    override func setUp() {
        super.setUp()
        
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createDates") { db in
            try db.execute(
                "CREATE TABLE dates (" +
                    "ID INTEGER PRIMARY KEY, " +
                    "creationDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP" +
                ")")
        }
        assertNoError {
            try migrator.migrate(dbQueue)
        }
    }
    
    func testDatabaseDateComponentsFormatHM() {
        assertNoError {
            try dbQueue.inDatabase { db in
                
                let dateComponents = NSDateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: [DatabaseDateComponents(dateComponents, format: .HM)])
                
                let string = String.fetchOne(db, "SELECT creationDate from dates")!
                XCTAssertEqual(string, "10:11")
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.HM)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, NSDateComponentUndefined)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, NSDateComponentUndefined)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, NSDateComponentUndefined)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, NSDateComponentUndefined)
                XCTAssertEqual(databaseDateComponents.dateComponents.nanosecond, NSDateComponentUndefined)
            }
        }
    }
    
    func testDatabaseDateComponentsFormatHMS() {
        assertNoError {
            try dbQueue.inDatabase { db in
                
                let dateComponents = NSDateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: [DatabaseDateComponents(dateComponents, format: .HMS)])
                
                let string = String.fetchOne(db, "SELECT creationDate from dates")!
                XCTAssertEqual(string, "10:11:12")
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.HMS)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, NSDateComponentUndefined)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, NSDateComponentUndefined)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, NSDateComponentUndefined)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, dateComponents.second)
                XCTAssertEqual(databaseDateComponents.dateComponents.nanosecond, NSDateComponentUndefined)
            }
        }
    }
    
    func testDatabaseDateComponentsFormatHMSS() {
        assertNoError {
            try dbQueue.inDatabase { db in
                
                let dateComponents = NSDateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: [DatabaseDateComponents(dateComponents, format: .HMSS)])
                
                let string = String.fetchOne(db, "SELECT creationDate from dates")!
                XCTAssertEqual(string, "10:11:12.123")
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.HMSS)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, NSDateComponentUndefined)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, NSDateComponentUndefined)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, NSDateComponentUndefined)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, dateComponents.second)
                XCTAssertEqual(round(Double(databaseDateComponents.dateComponents.nanosecond) / 1.0e6), round(Double(dateComponents.nanosecond) / 1.0e6))
            }
        }
    }
    
    func testDatabaseDateComponentsFormatYMD() {
        assertNoError {
            try dbQueue.inDatabase { db in
                
                let dateComponents = NSDateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: [DatabaseDateComponents(dateComponents, format: .YMD)])
                
                let string = String.fetchOne(db, "SELECT creationDate from dates")!
                XCTAssertEqual(string, "1973-09-18")
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.YMD)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, dateComponents.year)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, dateComponents.month)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, dateComponents.day)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, NSDateComponentUndefined)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, NSDateComponentUndefined)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, NSDateComponentUndefined)
                XCTAssertEqual(databaseDateComponents.dateComponents.nanosecond, NSDateComponentUndefined)
            }
        }
    }
    
    func testDatabaseDateComponentsFormatYMD_HM() {
        assertNoError {
            try dbQueue.inDatabase { db in
                
                let dateComponents = NSDateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: [DatabaseDateComponents(dateComponents, format: .YMD_HM)])
                
                let string = String.fetchOne(db, "SELECT creationDate from dates")!
                XCTAssertEqual(string, "1973-09-18 10:11")
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.YMD_HM)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, dateComponents.year)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, dateComponents.month)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, dateComponents.day)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, NSDateComponentUndefined)
                XCTAssertEqual(databaseDateComponents.dateComponents.nanosecond, NSDateComponentUndefined)
            }
        }
    }

    func testDatabaseDateComponentsFormatYMD_HMS() {
        assertNoError {
            try dbQueue.inDatabase { db in
                
                let dateComponents = NSDateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: [DatabaseDateComponents(dateComponents, format: .YMD_HMS)])
                
                let string = String.fetchOne(db, "SELECT creationDate from dates")!
                XCTAssertEqual(string, "1973-09-18 10:11:12")

                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.YMD_HMS)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, dateComponents.year)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, dateComponents.month)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, dateComponents.day)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, dateComponents.second)
                XCTAssertEqual(databaseDateComponents.dateComponents.nanosecond, NSDateComponentUndefined)
            }
        }
    }
    
    func testDatabaseDateComponentsFormatYMD_HMSS() {
        assertNoError {
            try dbQueue.inDatabase { db in
                
                let dateComponents = NSDateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: [DatabaseDateComponents(dateComponents, format: .YMD_HMSS)])
                
                let string = String.fetchOne(db, "SELECT creationDate from dates")!
                XCTAssertEqual(string, "1973-09-18 10:11:12.123")
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.YMD_HMSS)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, dateComponents.year)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, dateComponents.month)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, dateComponents.day)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, dateComponents.second)
                XCTAssertEqual(round(Double(databaseDateComponents.dateComponents.nanosecond) / 1.0e6), round(Double(dateComponents.nanosecond) / 1.0e6))
            }
        }
    }
    
    func testUndefinedDatabaseDateComponentsFormatYMD_HMSS() {
        assertNoError {
            try dbQueue.inDatabase { db in
                
                let dateComponents = NSDateComponents()
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: [DatabaseDateComponents(dateComponents, format: .YMD_HMSS)])
                
                let string = String.fetchOne(db, "SELECT creationDate from dates")!
                XCTAssertEqual(string, "0000-01-01 00:00:00.000")
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.YMD_HMSS)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, 0)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, 1)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, 1)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, 0)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, 0)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, 0)
                XCTAssertEqual(databaseDateComponents.dateComponents.nanosecond, 0)
            }
        }
    }
    
    func testDatabaseDateComponentsFormatIso8601YMD_HM() {
        assertNoError {
            try dbQueue.inDatabase { db in
                
                let dateComponents = NSDateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: ["1973-09-18T10:11"])
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.YMD_HM)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, dateComponents.year)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, dateComponents.month)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, dateComponents.day)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, NSDateComponentUndefined)
                XCTAssertEqual(databaseDateComponents.dateComponents.nanosecond, NSDateComponentUndefined)
            }
        }
    }
    
    func testDatabaseDateComponentsFormatIso8601YMD_HMS() {
        assertNoError {
            try dbQueue.inDatabase { db in
                
                let dateComponents = NSDateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: ["1973-09-18T10:11:12"])
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.YMD_HMS)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, dateComponents.year)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, dateComponents.month)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, dateComponents.day)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, dateComponents.second)
                XCTAssertEqual(databaseDateComponents.dateComponents.nanosecond, NSDateComponentUndefined)
            }
        }
    }
    
    func testDatabaseDateComponentsFormatIso8601YMD_HMSS() {
        assertNoError {
            try dbQueue.inDatabase { db in
                
                let dateComponents = NSDateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: ["1973-09-18T10:11:12.123"])
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.YMD_HMSS)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, dateComponents.year)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, dateComponents.month)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, dateComponents.day)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, dateComponents.second)
                XCTAssertEqual(round(Double(databaseDateComponents.dateComponents.nanosecond) / 1.0e6), round(Double(dateComponents.nanosecond) / 1.0e6))
            }
        }
    }
    
    func testFormatYMD_HMSIsLexicallyComparableToCURRENT_TIMESTAMP() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
                calendar.timeZone = NSTimeZone(forSecondsFromGMT: 0)
                do {
                    let date = NSDate().dateByAddingTimeInterval(-1)
                    let dateComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute, .Second], fromDate: date)
                    try db.execute(
                        "INSERT INTO dates (id, creationDate) VALUES (?,?)",
                        arguments: [1, DatabaseDateComponents(dateComponents, format: .YMD_HMS)])
                }
                do {
                    try db.execute(
                        "INSERT INTO dates (id) VALUES (?)",
                        arguments: [2])
                }
                do {
                    let date = NSDate().dateByAddingTimeInterval(1)
                    let dateComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute, .Second], fromDate: date)
                    try db.execute(
                        "INSERT INTO dates (id, creationDate) VALUES (?,?)",
                        arguments: [3, DatabaseDateComponents(dateComponents, format: .YMD_HMS)])
                }
                
                let ids = Int.fetchAll(db, "SELECT id FROM dates ORDER BY creationDate")
                XCTAssertEqual(ids, [1,2,3])
            }
        }
    }
    
    func testDatabaseDateComponentsFromUnparsableString() {
        let databaseDateComponents = DatabaseDateComponents.fromDatabaseValue(DatabaseValue(string: "foo"))
        XCTAssertTrue(databaseDateComponents == nil)
    }
}
