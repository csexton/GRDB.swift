import XCTest
import GRDB

// Tests about how minimal can class go regarding their initializers

// What happens for a class without property, without any initializer?
class EmptyRecordWithoutInitializer : Record {
    // nothing is required
}

// What happens if we add a mutable property, still without any initializer?
// A compiler error: class 'RecordWithoutInitializer' has no initializers
//
//    class RecordWithoutInitializer : Record {
//        let name: String?
//    }

// What happens with a mutable property, and init(row: Row)?
class RecordWithMutablePropertyAndRowInitializer : Record {
    var name: String?
    
    required init(row: Row) {
        super.init(row: row)        // super.init(row: row) is required
        self.name = "toto"          // property can be set before or after super.init
    }
}

// What happens with a mutable property, and init()?
class RecordWithMutablePropertyAndEmptyInitializer : Record {
    var name: String?
    
    override init() {
        super.init()                // super.init() is required
        self.name = "toto"          // property can be set before or after super.init
    }
    
    required init(row: Row) {       // init(row: row) is required
        super.init(row: row)        // super.init(row: row) is required
    }
}

// What happens with a mutable property, and a custom initializer()?
class RecordWithMutablePropertyAndCustomInitializer : Record {
    var name: String?
    
    init(name: String? = nil) {
        self.name = name
        super.init()                // super.init() is required
    }

    required init(row: Row) {       // init(row: row) is required
        super.init(row: row)        // super.init(row: row) is required
    }
}

// What happens with an immutable property?
class RecordWithImmutableProperty : Record {
    let initializedFromRow: Bool
    
    required init(row: Row) {       // An initializer is required, and the minimum is init(row: row)
        initializedFromRow = true   // property must bet set before super.init(row: row)
        super.init(row: row)        // super.init(row: row) is required
    }
}

// What happens with an immutable property and init()?
class RecordWithPedigree : Record {
    let initializedFromRow: Bool
    
    override init() {
        initializedFromRow = false  // property must bet set before super.init(row: row)
        super.init()                // super.init() is required
    }
    
    required init(row: Row) {       // An initializer is required, and the minimum is init(row: row)
        initializedFromRow = true   // property must bet set before super.init(row: row)
        super.init(row: row)        // super.init(row: row) is required
    }
}

// What happens with an immutable property and a custom initializer()?
class RecordWithImmutablePropertyAndCustomInitializer : Record {
    let initializedFromRow: Bool
    
    init(name: String? = nil) {
        initializedFromRow = false  // property must bet set before super.init(row: row)
        super.init()                // super.init() is required
    }
    
    required init(row: Row) {       // An initializer is required, and the minimum is init(row: row)
        initializedFromRow = true   // property must bet set before super.init(row: row)
        super.init(row: row)        // super.init(row: row) is required
    }
}

class RecordForDictionaryInitializerTest : Record {
    var firstName: String?
    var lastName: String?
    
    override func updateFromRow(row: Row) {
        firstName = row.value(named: "firstName")
        lastName = row.value(named: "lastName")
        super.updateFromRow(row)
    }
}

class RecordInitializersTests : GRDBTestCase {
    
    func testFetchedRecordAreInitializedFromRow() {
        
        // Here we test that Record.init(row: Row) can be overriden independently from Record.init().
        // People must be able to perform some initialization work when fetching records from the database.
        
        XCTAssertFalse(RecordWithPedigree().initializedFromRow)
        
        assertNoError {
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE pedigrees (foo INTEGER)")
                try db.execute("INSERT INTO pedigrees (foo) VALUES (NULL)")
                
                let pedigree = RecordWithPedigree.fetchOne(db, "SELECT * FROM pedigrees")!
                XCTAssertTrue(pedigree.initializedFromRow)  // very important
            }
        }
    }
    
    func testDictionaryInitializer() {
        let record = RecordForDictionaryInitializerTest(dictionary: ["firstName": "Arthur", "lastName": "Martin"])
        XCTAssertEqual(record.firstName!, "Arthur")
        XCTAssertEqual(record.lastName!, "Martin")
    }
}
