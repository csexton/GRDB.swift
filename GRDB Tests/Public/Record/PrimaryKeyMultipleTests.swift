import XCTest
import GRDB

// Citizenship has a multiple-column primary key.
class Citizenship: Record {
    var personName: String!
    var countryName: String!
    var native: Bool!
    
    override class func databaseTableName() -> String? {
        return "citizenships"
    }
    
    override var storedDatabaseDictionary: [String: DatabaseValueConvertible?] {
        return [
            "personName": personName,
            "countryName": countryName,
            "native": native]
    }
    
    override func updateFromRow(row: Row) {
        if let dbv = row["personName"] { personName = dbv.value() }
        if let dbv = row["countryName"] { countryName = dbv.value() }
        if let dbv = row["native"] { native = dbv.value() }
        super.updateFromRow(row) // Subclasses are required to call super.
    }
    
    init (personName: String? = nil, countryName: String? = nil, native: Bool? = nil) {
        self.personName = personName
        self.countryName = countryName
        self.native = native
        super.init()
    }
    
    required init(row: Row) {
        super.init(row: row)
    }
    
    static func setupInDatabase(db: Database) throws {
        try db.execute(
            "CREATE TABLE citizenships (" +
                "personName TEXT NOT NULL, " +
                "countryName TEXT NOT NULL, " +
                "native BOOLEAN NOT NULL, " +
                "PRIMARY KEY (personName, countryName)" +
            ")")
    }
}


class PrimaryKeyMultipleTests: GRDBTestCase {
    
    override func setUp() {
        super.setUp()
        
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createCitizenship", Citizenship.setupInDatabase)
        assertNoError {
            try migrator.migrate(dbQueue)
        }
    }
    
    
    // MARK: - Insert
    
    func testInsertWithNilPrimaryKeyThrowsDatabaseError() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(native: true)
                XCTAssertTrue(record.personName == nil && record.countryName == nil)
                do {
                    try record.insert(db)
                    XCTFail("Expected DatabaseError")
                } catch is DatabaseError {
                    // Expected DatabaseError
                }
            }
        }
    }
    
    func testInsertWithNotNilPrimaryKeyThatDoesNotMatchAnyRowInsertsARow() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record.insert(db)
                
                let row = Row.fetchOne(db, "SELECT * FROM citizenships WHERE personName = ? AND countryName = ?", arguments: [record.personName, record.countryName])!
                for (key, value) in record.storedDatabaseDictionary {
                    if let dbv = row[key] {
                        XCTAssertEqual(dbv, value?.databaseValue ?? .Null)
                    } else {
                        XCTFail("Missing column \(key) in fetched row")
                    }
                }
            }
        }
    }
    
    func testInsertWithNotNilPrimaryKeyThatMatchesARowThrowsDatabaseError() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record.insert(db)
                do {
                    try record.insert(db)
                    XCTFail("Expected DatabaseError")
                } catch is DatabaseError {
                    // Expected DatabaseError
                }
            }
        }
    }
    
    func testInsertAfterDeleteInsertsARow() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record.insert(db)
                try record.delete(db)
                try record.insert(db)
                
                let row = Row.fetchOne(db, "SELECT * FROM citizenships WHERE personName = ? AND countryName = ?", arguments: [record.personName, record.countryName])!
                for (key, value) in record.storedDatabaseDictionary {
                    if let dbv = row[key] {
                        XCTAssertEqual(dbv, value?.databaseValue ?? .Null)
                    } else {
                        XCTFail("Missing column \(key) in fetched row")
                    }
                }
            }
        }
    }
    
    
    // MARK: - Update
    
    func testUpdateWithNotNilPrimaryKeyThatDoesNotMatchAnyRowThrowsRecordNotFound() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                do {
                    try record.update(db)
                    XCTFail("Expected RecordError.RecordNotFound")
                } catch RecordError.RecordNotFound {
                    // Expected RecordError.RecordNotFound
                }
            }
        }
    }
    
    func testUpdateWithNotNilPrimaryKeyThatMatchesARowUpdatesThatRow() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record.insert(db)
                record.native = false
                try record.update(db)
                
                let row = Row.fetchOne(db, "SELECT * FROM citizenships WHERE personName = ? AND countryName = ?", arguments: [record.personName, record.countryName])!
                for (key, value) in record.storedDatabaseDictionary {
                    if let dbv = row[key] {
                        XCTAssertEqual(dbv, value?.databaseValue ?? .Null)
                    } else {
                        XCTFail("Missing column \(key) in fetched row")
                    }
                }
            }
        }
    }
    
    func testUpdateAfterDeleteThrowsRecordNotFound() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record.insert(db)
                try record.delete(db)
                do {
                    try record.update(db)
                    XCTFail("Expected RecordError.RecordNotFound")
                } catch RecordError.RecordNotFound {
                    // Expected RecordError.RecordNotFound
                }
            }
        }
    }
    
    
    // MARK: - Save
    
    func testSaveWithNilPrimaryKeyThrowsDatabaseError() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(native: true)
                XCTAssertTrue(record.personName == nil && record.countryName == nil)
                do {
                    try record.save(db)
                    XCTFail("Expected DatabaseError")
                } catch is DatabaseError {
                    // Expected DatabaseError
                }
            }
        }
    }
    
    func testSaveWithNotNilPrimaryKeyThatDoesNotMatchAnyRowInsertsARow() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record.save(db)
                
                let row = Row.fetchOne(db, "SELECT * FROM citizenships WHERE personName = ? AND countryName = ?", arguments: [record.personName, record.countryName])!
                for (key, value) in record.storedDatabaseDictionary {
                    if let dbv = row[key] {
                        XCTAssertEqual(dbv, value?.databaseValue ?? .Null)
                    } else {
                        XCTFail("Missing column \(key) in fetched row")
                    }
                }
            }
        }
    }
    
    func testSaveWithNotNilPrimaryKeyThatMatchesARowUpdatesThatRow() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record.insert(db)
                try record.save(db)   // Test that useless update succeeds. It is a proof that save() has performed an UPDATE statement, and not an INSERT statement: INSERT would have throw a database error for duplicated key.
                record.native = false
                try record.save(db)   // Actual update
                
                let row = Row.fetchOne(db, "SELECT * FROM citizenships WHERE personName = ? AND countryName = ?", arguments: [record.personName, record.countryName])!
                for (key, value) in record.storedDatabaseDictionary {
                    if let dbv = row[key] {
                        XCTAssertEqual(dbv, value?.databaseValue ?? .Null)
                    } else {
                        XCTFail("Missing column \(key) in fetched row")
                    }
                }
            }
        }
    }
    
    func testSaveAfterDeleteInsertsARow() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record.insert(db)
                try record.delete(db)
                try record.save(db)
                
                let row = Row.fetchOne(db, "SELECT * FROM citizenships WHERE personName = ? AND countryName = ?", arguments: [record.personName, record.countryName])!
                for (key, value) in record.storedDatabaseDictionary {
                    if let dbv = row[key] {
                        XCTAssertEqual(dbv, value?.databaseValue ?? .Null)
                    } else {
                        XCTFail("Missing column \(key) in fetched row")
                    }
                }
            }
        }
    }
    
    
    // MARK: - Delete
    
    func testDeleteWithNotNilPrimaryKeyThatDoesNotMatchAnyRowDoesNothing() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                let deleted = try record.delete(db)
                XCTAssertFalse(deleted)
            }
        }
    }
    
    func testDeleteWithNotNilPrimaryKeyThatMatchesARowDeletesThatRow() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record.insert(db)
                let deleted = try record.delete(db)
                XCTAssertTrue(deleted)
                
                let row = Row.fetchOne(db, "SELECT * FROM citizenships WHERE personName = ? AND countryName = ?", arguments: [record.personName, record.countryName])
                XCTAssertTrue(row == nil)
            }
        }
    }
    
    func testDeleteAfterDeleteDoesNothing() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record.insert(db)
                var deleted = try record.delete(db)
                XCTAssertTrue(deleted)
                deleted = try record.delete(db)
                XCTAssertFalse(deleted)
            }
        }
    }
    
    
    // MARK: - Reload
    
    func testReloadWithNotNilPrimaryKeyThatDoesNotMatchAnyRowThrowsRecordNotFound() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                do {
                    try record.reload(db)
                    XCTFail("Expected RecordError.RecordNotFound")
                } catch RecordError.RecordNotFound {
                    // Expected RecordError.RecordNotFound
                }
            }
        }
    }
    
    func testReloadWithNotNilPrimaryKeyThatMatchesARowFetchesThatRow() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record.insert(db)
                record.native = false
                try record.reload(db)
                
                let row = Row.fetchOne(db, "SELECT * FROM citizenships WHERE personName = ? AND countryName = ?", arguments: [record.personName, record.countryName])!
                for (key, value) in record.storedDatabaseDictionary {
                    if let dbv = row[key] {
                        XCTAssertEqual(dbv, value?.databaseValue ?? .Null)
                    } else {
                        XCTFail("Missing column \(key) in fetched row")
                    }
                }
            }
        }
    }
    
    func testReloadAfterDeleteThrowsRecordNotFound() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record.insert(db)
                try record.delete(db)
                do {
                    try record.reload(db)
                    XCTFail("Expected RecordError.RecordNotFound")
                } catch RecordError.RecordNotFound {
                    // Expected RecordError.RecordNotFound
                }
            }
        }
    }
    
    
    
    
    // MARK: - Fetch With Key
    
    func testFetchWithKeys() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record1 = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record1.insert(db)
                let record2 = Citizenship(personName: "Barbara", countryName: "France", native: false)
                try record2.insert(db)
                
                do {
                    let fetchedRecords = Array(Citizenship.fetch(db, keys: []))
                    XCTAssertEqual(fetchedRecords.count, 0)
                }
                
                do {
                    let fetchedRecords = Array(Citizenship.fetch(db, keys: [["personName": record1.personName, "countryName": record1.countryName], ["personName": record2.personName, "countryName": record2.countryName]]))
                    XCTAssertEqual(fetchedRecords.count, 2)
                    XCTAssertEqual(Set(fetchedRecords.map { $0.personName }), Set([record1.personName, record2.personName]))
                }
                
                do {
                    let fetchedRecords = Array(Citizenship.fetch(db, keys: [["personName": record1.personName, "countryName": record1.countryName], ["personName": nil, "countryName": nil]]))
                    XCTAssertEqual(fetchedRecords.count, 1)
                    XCTAssertEqual(fetchedRecords.first!.personName, record1.personName!)
                }
            }
        }
    }
    
    func testFetchAllWithKeys() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record1 = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record1.insert(db)
                let record2 = Citizenship(personName: "Barbara", countryName: "France", native: false)
                try record2.insert(db)
                
                do {
                    let fetchedRecords = Citizenship.fetchAll(db, keys: [])
                    XCTAssertEqual(fetchedRecords.count, 0)
                }
                
                do {
                    let fetchedRecords = Citizenship.fetchAll(db, keys: [["personName": record1.personName, "countryName": record1.countryName], ["personName": record2.personName, "countryName": record2.countryName]])
                    XCTAssertEqual(fetchedRecords.count, 2)
                    XCTAssertEqual(Set(fetchedRecords.map { $0.personName }), Set([record1.personName, record2.personName]))
                }
                
                do {
                    let fetchedRecords = Citizenship.fetchAll(db, keys: [["personName": record1.personName, "countryName": record1.countryName], ["personName": nil, "countryName": nil]])
                    XCTAssertEqual(fetchedRecords.count, 1)
                    XCTAssertEqual(fetchedRecords.first!.personName, record1.personName!)
                }
            }
        }
    }
    
    func testFetchOneWithKey() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record.insert(db)
                
                let fetchedRecord = Citizenship.fetchOne(db, key: ["personName": record.personName, "countryName": record.countryName])!
                XCTAssertTrue(fetchedRecord.personName == record.personName)
                XCTAssertTrue(fetchedRecord.countryName == record.countryName)
                XCTAssertTrue(fetchedRecord.native == record.native)
            }
        }
    }
    
    
    // MARK: - Exists
    
    func testExistsWithNotNilPrimaryKeyThatDoesNotMatchAnyRowReturnsFalse() {
        dbQueue.inDatabase { db in
            let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
            XCTAssertFalse(record.exists(db))
        }
    }
    
    func testExistsWithNotNilPrimaryKeyThatMatchesARowReturnsTrue() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record.insert(db)
                XCTAssertTrue(record.exists(db))
            }
        }
    }
    
    func testExistsAfterDeleteReturnsTrue() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = Citizenship(personName: "Arthur", countryName: "France", native: true)
                try record.insert(db)
                try record.delete(db)
                XCTAssertFalse(record.exists(db))
            }
        }
    }
}
