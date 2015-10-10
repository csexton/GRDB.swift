import XCTest
import GRDB

class RecordWithCallbacks : Record {
    var id: Int64?
    var didInsertCompletions: [TransactionCompletion] = []
    var didUpdateCompletions: [TransactionCompletion] = []
    var didSaveCompletions: [TransactionCompletion] = []
    var didDeleteCompletions: [TransactionCompletion] = []
    var idInDidInsert: Int64?
    var idInDidSave: Int64?
    var idInDidDelete: Int64?
    
    func reset() {
        didInsertCompletions = []
        didUpdateCompletions = []
        didSaveCompletions = []
        didDeleteCompletions = []
        idInDidInsert = nil
        idInDidSave = nil
    }
    
    static func setupInDatabase(db: Database) throws {
        try db.execute("CREATE TABLE records (id INTEGER PRIMARY KEY)")
    }
    
    override static func databaseTableName() -> String {
        return "records"
    }
    
    override var storedDatabaseDictionary: [String: DatabaseValueConvertible?] {
        return ["id": id]
    }
    
    override func updateFromRow(row: Row) {
        if let dbv = row["id"] { id = dbv.value() }
        super.updateFromRow(row)
    }
    
    override func didInsert(db: Database, completion: TransactionCompletion) {
        super.didInsert(db, completion: completion)
        didInsertCompletions.append(completion)
        idInDidInsert = id
    }
    
    override func didUpdate(db: Database, completion: TransactionCompletion) {
        super.didUpdate(db, completion: completion)
        didUpdateCompletions.append(completion)
    }
    
    override func didSave(db: Database, completion: TransactionCompletion) {
        super.didSave(db, completion: completion)
        didSaveCompletions.append(completion)
        idInDidSave = id
    }
    
    override func didDelete(db: Database, completion: TransactionCompletion) {
        super.didDelete(db, completion: completion)
        didDeleteCompletions.append(completion)
        idInDidDelete = id
    }
}


class RecordTransactionCallbacks: GRDBTestCase {
    
    override func setUp() {
        super.setUp()
        
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createRecordWithCallbacks", RecordWithCallbacks.setupInDatabase)
        assertNoError {
            try migrator.migrate(dbQueue)
        }
    }
    
    func testImplicitTransactionInsert() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = RecordWithCallbacks()
                try record.insert(db)
                XCTAssertTrue(record.id != nil)
                XCTAssertEqual(record.didInsertCompletions, [TransactionCompletion.Commit])
                XCTAssertEqual(record.didUpdateCompletions.count, 0)
                XCTAssertEqual(record.didSaveCompletions, [TransactionCompletion.Commit])
                XCTAssertEqual(record.didDeleteCompletions.count, 0)
                XCTAssertEqual(record.idInDidInsert!, record.id)
                XCTAssertEqual(record.idInDidSave!, record.id)
            }
        }
    }
    
    func testImplicitTransactionUpdate() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = RecordWithCallbacks()
                try record.insert(db)
                
                record.reset()
                try record.update(db)
                XCTAssertTrue(record.id != nil)
                XCTAssertEqual(record.didInsertCompletions.count, 0)
                XCTAssertEqual(record.didUpdateCompletions, [TransactionCompletion.Commit])
                XCTAssertEqual(record.didSaveCompletions, [TransactionCompletion.Commit])
                XCTAssertEqual(record.didDeleteCompletions.count, 0)
                XCTAssertEqual(record.idInDidSave!, record.id)
            }
        }
    }
    
    func testImplicitTransactionDelete() {
        assertNoError {
            try dbQueue.inDatabase { db in
                let record = RecordWithCallbacks()
                try record.insert(db)
                
                record.reset()
                try record.delete(db)
                XCTAssertTrue(record.id != nil)
                XCTAssertEqual(record.didInsertCompletions.count, 0)
                XCTAssertEqual(record.didUpdateCompletions.count, 0)
                XCTAssertEqual(record.didSaveCompletions.count, 0)
                XCTAssertEqual(record.didDeleteCompletions, [TransactionCompletion.Commit])
                XCTAssertEqual(record.idInDidDelete!, record.id)
            }
        }
    }
    
    func testExplicitTransactionCommitInsert() {
        assertNoError {
            let record = RecordWithCallbacks()
            
            try dbQueue.inTransaction { db in
                try record.insert(db)
                XCTAssertTrue(record.id != nil)
                XCTAssertEqual(record.didInsertCompletions.count, 0)
                XCTAssertEqual(record.didUpdateCompletions.count, 0)
                XCTAssertEqual(record.didSaveCompletions.count, 0)
                XCTAssertEqual(record.didDeleteCompletions.count, 0)
                return .Commit
            }
            XCTAssertTrue(record.id != nil)
            XCTAssertEqual(record.didInsertCompletions, [TransactionCompletion.Commit])
            XCTAssertEqual(record.didUpdateCompletions.count, 0)
            XCTAssertEqual(record.didSaveCompletions, [TransactionCompletion.Commit])
            XCTAssertEqual(record.didDeleteCompletions.count, 0)
            XCTAssertEqual(record.idInDidInsert!, record.id)
            XCTAssertEqual(record.idInDidSave!, record.id)
        }
    }
    
    func testExplicitTransactionCommitUpdate() {
        assertNoError {
            let record = RecordWithCallbacks()
            
            try dbQueue.inDatabase { db in
                try record.insert(db)
            }
            
            try dbQueue.inTransaction { db in
                record.reset()
                try record.update(db)
                XCTAssertEqual(record.didInsertCompletions.count, 0)
                XCTAssertEqual(record.didUpdateCompletions.count, 0)
                XCTAssertEqual(record.didSaveCompletions.count, 0)
                XCTAssertEqual(record.didDeleteCompletions.count, 0)
                return .Commit
            }
            XCTAssertTrue(record.id != nil)
            XCTAssertEqual(record.didInsertCompletions.count, 0)
            XCTAssertEqual(record.didUpdateCompletions, [TransactionCompletion.Commit])
            XCTAssertEqual(record.didSaveCompletions, [TransactionCompletion.Commit])
            XCTAssertEqual(record.didDeleteCompletions.count, 0)
            XCTAssertEqual(record.idInDidSave!, record.id)
        }
    }
    
    func testExplicitTransactionCommitDelete() {
        assertNoError {
            let record = RecordWithCallbacks()
            
            try dbQueue.inDatabase { db in
                try record.insert(db)
            }
            
            try dbQueue.inTransaction { db in
                record.reset()
                try record.delete(db)
                XCTAssertEqual(record.didInsertCompletions.count, 0)
                XCTAssertEqual(record.didUpdateCompletions.count, 0)
                XCTAssertEqual(record.didSaveCompletions.count, 0)
                XCTAssertEqual(record.didDeleteCompletions.count, 0)
                return .Commit
            }
            XCTAssertTrue(record.id != nil)
            XCTAssertEqual(record.didInsertCompletions.count, 0)
            XCTAssertEqual(record.didUpdateCompletions.count, 0)
            XCTAssertEqual(record.didSaveCompletions.count, 0)
            XCTAssertEqual(record.didDeleteCompletions, [TransactionCompletion.Commit])
            XCTAssertEqual(record.idInDidDelete!, record.id)
        }
    }
    
    func testExplicitTransactionRollbackInsert() {
        assertNoError {
            let record = RecordWithCallbacks()
            var rollbackedId: Int64?
            try dbQueue.inTransaction { db in
                try record.insert(db)
                rollbackedId = record.id
                XCTAssertEqual(record.didInsertCompletions.count, 0)
                XCTAssertEqual(record.didUpdateCompletions.count, 0)
                XCTAssertEqual(record.didSaveCompletions.count, 0)
                XCTAssertEqual(record.didDeleteCompletions.count, 0)
                return .Rollback
            }
            XCTAssertTrue(rollbackedId != nil)
            XCTAssertTrue(record.id == nil)
            XCTAssertEqual(record.didInsertCompletions, [TransactionCompletion.Rollback])
            XCTAssertEqual(record.didUpdateCompletions.count, 0)
            XCTAssertEqual(record.didSaveCompletions, [TransactionCompletion.Rollback])
            XCTAssertEqual(record.didDeleteCompletions.count, 0)
            XCTAssertEqual(record.idInDidInsert!, rollbackedId)   // This is particularly important: clean up after failed insert may require to know the RowID, even if the record.id turns eventually nil afterwards.
            XCTAssertEqual(record.idInDidSave!, rollbackedId)     // Idem.
        }
    }
    
    func testExplicitTransactionRollbackUpdate() {
        assertNoError {
            let record = RecordWithCallbacks()
            
            try dbQueue.inDatabase { db in
                try record.insert(db)
            }
            
            try dbQueue.inTransaction { db in
                record.reset()
                try record.update(db)
                XCTAssertEqual(record.didInsertCompletions.count, 0)
                XCTAssertEqual(record.didUpdateCompletions.count, 0)
                XCTAssertEqual(record.didSaveCompletions.count, 0)
                XCTAssertEqual(record.didDeleteCompletions.count, 0)
                return .Rollback
            }
            XCTAssertTrue(record.id != nil)
            XCTAssertEqual(record.didInsertCompletions.count, 0)
            XCTAssertEqual(record.didUpdateCompletions, [TransactionCompletion.Rollback])
            XCTAssertEqual(record.didSaveCompletions, [TransactionCompletion.Rollback])
            XCTAssertEqual(record.didDeleteCompletions.count, 0)
            XCTAssertEqual(record.idInDidSave!, record.id)
        }
    }
    
    func testExplicitTransactionRollbackDelete() {
        assertNoError {
            let record = RecordWithCallbacks()
            
            try dbQueue.inDatabase { db in
                try record.insert(db)
            }
            
            try dbQueue.inTransaction { db in
                record.reset()
                try record.delete(db)
                XCTAssertEqual(record.didInsertCompletions.count, 0)
                XCTAssertEqual(record.didUpdateCompletions.count, 0)
                XCTAssertEqual(record.didSaveCompletions.count, 0)
                XCTAssertEqual(record.didDeleteCompletions.count, 0)
                return .Rollback
            }
            XCTAssertTrue(record.id != nil)
            XCTAssertEqual(record.didInsertCompletions.count, 0)
            XCTAssertEqual(record.didUpdateCompletions.count, 0)
            XCTAssertEqual(record.didSaveCompletions.count, 0)
            XCTAssertEqual(record.didDeleteCompletions, [TransactionCompletion.Rollback])
            XCTAssertEqual(record.idInDidDelete!, record.id)
        }
    }
    
    func testExplicitTransactionCommitInsertLast() {
        assertNoError {
            let record = RecordWithCallbacks()
            
            try dbQueue.inTransaction { db in
                try record.insert(db)
                try record.update(db)
                try record.delete(db)
                try record.insert(db)
                return .Commit
            }
            XCTAssertEqual(record.didInsertCompletions, [TransactionCompletion.Commit])
            XCTAssertEqual(record.didUpdateCompletions.count, 0)
            XCTAssertEqual(record.didSaveCompletions, [TransactionCompletion.Commit])
            XCTAssertEqual(record.didDeleteCompletions.count, 0)
        }
    }
    
    func testExplicitTransactionCommitUpdateLast() {
        assertNoError {
            let record = RecordWithCallbacks()
            
            try dbQueue.inTransaction { db in
                try record.insert(db)
                try record.update(db)
                try record.update(db)
                return .Commit
            }
            XCTAssertEqual(record.didInsertCompletions.count, 0)
            XCTAssertEqual(record.didUpdateCompletions, [TransactionCompletion.Commit])
            XCTAssertEqual(record.didSaveCompletions, [TransactionCompletion.Commit])
            XCTAssertEqual(record.didDeleteCompletions.count, 0)
        }
    }
    
    func testExplicitTransactionCommitDeleteLast() {
        assertNoError {
            let record = RecordWithCallbacks()
            
            try dbQueue.inTransaction { db in
                try record.insert(db)
                try record.update(db)
                try record.update(db)
                try record.delete(db)
                return .Commit
            }
            XCTAssertEqual(record.didInsertCompletions.count, 0)
            XCTAssertEqual(record.didUpdateCompletions.count, 0)
            XCTAssertEqual(record.didSaveCompletions.count, 0)
            XCTAssertEqual(record.didDeleteCompletions, [TransactionCompletion.Commit])
        }
    }
    
    func testExample() {
        // Test that rowID is still set in didInsert() and didSave() after a rollbacked insert.
    }
}
