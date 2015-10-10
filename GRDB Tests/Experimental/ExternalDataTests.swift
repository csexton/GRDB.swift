import XCTest
import GRDB

class ExternalData {
    
    // The path to the external data. May be nil.
    var path: String? { return buildPath() }
    
    // The data
    var data: NSData? {
        get {
            return dataValue.data(path, dataReadingOptions: dataReadingOptions)
        }
        set {
            if let data = newValue where data.length > 0 {
                dataValue = .DirtyData(data)
            } else {
                dataValue = .DirtyData(nil)
            }
        }
    }
    
    init(@autoclosure(escaping) _ path: () -> String?) {
        self.buildPath = path
    }
    
    
    // MARK: - Configuration
    
    // See NSFileManager.createDirectoryAtPath(_:withIntermediateDirectories:attributes:)
    var directoryAttributes: [String : AnyObject]?
    
    // Options for reading data. See NSData(contentsOfFile:options:)
    var dataReadingOptions: NSDataReadingOptions = []
    
    func onWrite(writeCallback: (path: String) throws -> ()) {
        self.writeCallback = writeCallback
    }
    
    private var writeCallback: ((path: String) throws -> ())?
    
    
    // MARK: - CRUD
    
    func save() throws {
        let fm = NSFileManager.defaultManager()
        
        switch dataValue {
        case .Unresolved:
            break
        case .CleanData:
            break
        case .DirtyData(let data):
            try backupIfNeeded(fm)
            if let data = data {
                try writeFile(fm, data: data, path: storagePath)
            } else {
                try deleteFileIfExist(fm, path: storagePath)
            }
        }
    }
    
    func delete() throws {
        let fm = NSFileManager.defaultManager()
        try backupIfNeeded(fm)
        try deleteFileIfExist(fm, path: storagePath)
    }
    
    func transactionDidComplete(completion: TransactionCompletion) {
        let fm = NSFileManager.defaultManager()
        
        guard let finalPath = path else {
            try! deleteFileIfExist(fm, path: storagePath)
            try! deleteFileIfExist(fm, path: backupPath)
            return
        }
        
        switch completion {
        case .Commit:
            try! deleteFileIfExist(fm, path: backupPath)
            try! moveFileIfNeeded(fm, fromPath: storagePath, toPath: finalPath)
            dataValue.setClean()
            _storagePath = finalPath
        case .Rollback:
            // TODO: test that a failed insert does not leave any remaining data file
            if fm.fileExistsAtPath(backupPath) {
                let backupSize = try! (fm.attributesOfItemAtPath(backupPath)[NSFileSize] as! NSNumber).integerValue
                if backupSize == 0 {
                    try! deleteFileIfExist(fm, path: backupPath)
                    try! deleteFileIfExist(fm, path: finalPath)
                    try! deleteFileIfExist(fm, path: storagePath)
                } else {
                    try! deleteFileIfExist(fm, path: storagePath)
                    try! moveFileIfNeeded(fm, fromPath: backupPath, toPath: finalPath)
                }
            }
            _storagePath = finalPath
        }
    }
    
    
    // Data
    
    private enum DataValue {
        case Unresolved
        case CleanData(NSData?)
        case DirtyData(NSData?)
        
        mutating func data(path: String?, dataReadingOptions: NSDataReadingOptions) -> NSData? {
            switch self {
            case .Unresolved:
                if let path = path {
                    let fm = NSFileManager.defaultManager()
                    if fm.fileExistsAtPath(path) {
                        let data = try! NSData(contentsOfFile: path, options: dataReadingOptions)
                        self = .CleanData(data)
                        return data
                    } else {
                        self = .CleanData(nil)
                        return nil
                    }
                } else {
                    return nil
                }
            case .CleanData(let data):
                return data
            case .DirtyData(let data):
                return data
            }
        }
        
        mutating func reset() {
            self = .Unresolved
        }
        
        mutating func setClean() {
            switch self {
            case .Unresolved:
                break
            case .CleanData:
                break
            case .DirtyData(let data):
                self = .CleanData(data)
            }
        }
    }
    
    private var dataValue: DataValue = .Unresolved
    
    
    // Paths
    
    private static var tempStoragePathTemplate = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent("ExternalData.XXXXXX")
    private var buildPath: () -> String?
    private var storagePath: String {
        if let storagePath = _storagePath {
            return storagePath
        }
        
        if let path = path {
            _storagePath = path
            return path
        }
        
        let tempPath = ExternalData.tempStoragePathTemplate.withCString {
            String.fromCString(mktemp(UnsafeMutablePointer($0)))!
        }
        _storagePath = tempPath
        return tempPath
    }
    private var _storagePath: String?
    private var backupPath: String {
        return (storagePath as NSString).stringByAppendingPathExtension("backup")!
    }
    
    
    // Support
    
    private func createIntermediateDirectoriesIfNeeded(fm: NSFileManager, path: String) throws {
        let directoryPath = (path as NSString).stringByDeletingLastPathComponent
        if !fm.fileExistsAtPath(directoryPath) {
            try fm.createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: directoryAttributes)
        }
    }
    
    private func writeFile(fm: NSFileManager, data: NSData, path: String) throws {
        try createIntermediateDirectoriesIfNeeded(fm, path: path)
        try deleteFileIfExist(fm, path: path)
        try data.writeToFile(path, options: [])
        if let writeCallback = writeCallback {
            try writeCallback(path: path)
        }
    }
    
    private func moveFileIfNeeded(fm: NSFileManager, fromPath source: String, toPath destination: String) throws {
        guard source != destination else { return }
        try createIntermediateDirectoriesIfNeeded(fm, path: destination)
        try fm.moveItemAtPath(source, toPath: destination)
    }
    
    private func deleteFileIfExist(fm: NSFileManager, path: String) throws {
        if fm.fileExistsAtPath(path) {
            try fm.removeItemAtPath(path)
        }
    }
    
    private func backupIfNeeded(fm: NSFileManager) throws {
        // Don't touch backup if already there
        if fm.fileExistsAtPath(backupPath) {
            return
        }
        
        if fm.fileExistsAtPath(storagePath) {
            try moveFileIfNeeded(fm, fromPath: storagePath, toPath: backupPath)
        } else {
            // Create empty file, the marker for no data.
            try writeFile(fm, data: NSData(), path: backupPath)
        }
    }
}

class RecordWithExternalData : Record {
    var id: Int64?
    var data: NSData? {
        get { return externalData.data }
        set { externalData.data = newValue }
    }
    
    
    // MARK: - Regular Record boilerplate
    
    override static func databaseTableName() -> String {
        return "datas"
    }
    
    override var storedDatabaseDictionary: [String: DatabaseValueConvertible?] {
        return ["id": id]
    }
    
    override func updateFromRow(row: Row) {
        if let dbv = row["id"] { id = dbv.value() }
        super.updateFromRow(row)
    }
    
    
    // Support for external data
    
    // The external storage directory
    static let externalDataDirectoryPath = "/tmp/RecordWithExternalData"
    
    // The path to external record data
    private var externalDataPath: String? {
        guard let id = id else { return nil }
        return (RecordWithExternalData.externalDataDirectoryPath as NSString).stringByAppendingPathComponent("\(id).txt")
    }
    
    // The externalData
    private lazy var externalData: ExternalData = { [unowned self] in
        let externalData = ExternalData(self.externalDataPath)
        externalData.onWrite { path in
            // test support
            if self.throwOnWrite {
                throw NSError(domain: "InvalidData", code: 0, userInfo: nil)
            }
        }
        return externalData
    }()
    
    
    override func insert(db: Database) throws {
        try externalData.save()
        try super.insert(db)
    }
    
    override func update(db: Database) throws {
        try externalData.save()
        try super.update(db)
    }
    
    override func delete(db: Database) throws -> Record.DeletionResult {
        try externalData.delete()
        return try super.delete(db)
    }
    
    override func didSave(db: Database, completion: TransactionCompletion) {
        externalData.transactionDidComplete(completion)
    }
    
    override func didDelete(db: Database, completion: TransactionCompletion) {
        externalData.transactionDidComplete(completion)
    }
    
    
    // Tests support
    
    var throwOnWrite: Bool = false
    
    static func setupInDatabase(db: Database) throws {
        try db.execute(
            "CREATE TABLE datas (id INTEGER PRIMARY KEY, data TEXT)")
    }
}

class ExternalDataTests : GRDBTestCase {
    override func setUp() {
        super.setUp()
        
        assertNoError {
            try dbQueue.inDatabase { db in
                try RecordWithExternalData.setupInDatabase(db)
            }
            
            let fm = NSFileManager.defaultManager()
            if fm.fileExistsAtPath(RecordWithExternalData.externalDataDirectoryPath) {
                try fm.removeItemAtPath(RecordWithExternalData.externalDataDirectoryPath)
            }
        }
    }
    
    func testImplicitTransaction() {
        assertNoError {
            // Test that we can store data in the file system...
            let record = RecordWithExternalData()
            try dbQueue.inDatabase { db in
                record.data = "foo".dataUsingEncoding(NSUTF8StringEncoding)
                try record.save(db)
            }
            
            // ... and get it back after a fetch:
            dbQueue.inDatabase { db in
                let reloadedRecord = RecordWithExternalData.fetchOne(db, primaryKey: record.id)!
                XCTAssertEqual(reloadedRecord.data, "foo".dataUsingEncoding(NSUTF8StringEncoding))
            }
        }
    }
    
    func testExplicitTransaction() {
        assertNoError {
            // Test that we can stored data in the file system...
            let record = RecordWithExternalData()
            try dbQueue.inDatabase { db in
                record.data = "foo".dataUsingEncoding(NSUTF8StringEncoding)
                try record.save(db)
            }
            
            try dbQueue.inTransaction { db in
                // ... and that changes...
                record.data = "bar".dataUsingEncoding(NSUTF8StringEncoding)
                try record.save(db)
                
                // ... after changes...
                record.data = "baz".dataUsingEncoding(NSUTF8StringEncoding)
                try record.save(db)
                
                // ... are actually applied in the file system...
                let reloadedRecord = RecordWithExternalData.fetchOne(db, primaryKey: record.id)!
                XCTAssertEqual(reloadedRecord.data, "baz".dataUsingEncoding(NSUTF8StringEncoding))
                
                // ... and enforced by commit:
                return .Commit
            }
            
            // We find our modified data after commit:
            dbQueue.inDatabase { db in
                let reloadedRecord = RecordWithExternalData.fetchOne(db, primaryKey: record.id)!
                XCTAssertEqual(reloadedRecord.data, "baz".dataUsingEncoding(NSUTF8StringEncoding))
            }
        }
    }
    
    func testCommitError() {
        assertNoError {
            // Test that we can stored data in the file system...
            let record = RecordWithExternalData()
            try dbQueue.inDatabase { db in
                record.data = "foo".dataUsingEncoding(NSUTF8StringEncoding)
                try record.save(db)
            }
            
            do {
                try dbQueue.inTransaction { db in
                    // ... and that changes...
                    record.data = "bar".dataUsingEncoding(NSUTF8StringEncoding)
                    try record.save(db)
                    
                    // ... after changes...
                    record.data = "baz".dataUsingEncoding(NSUTF8StringEncoding)
                    try record.save(db)
                    
                    // ... even deletion...
                    let externalDataPath = record.externalData.path!
                    try record.delete(db)
                    
                    // ... are actually applied in the file system...
                    let fm = NSFileManager.defaultManager()
                    XCTAssertFalse(fm.fileExistsAtPath(externalDataPath))
                    
                    // ... until database commit, which may fail:
                    let forbiddenRecord = RecordWithExternalData()
                    forbiddenRecord.throwOnWrite = true
                    forbiddenRecord.data = "error".dataUsingEncoding(NSUTF8StringEncoding)
                    try forbiddenRecord.save(db)
                    return .Commit
                }
                XCTFail("Expected error")
            } catch let error as NSError {
                XCTAssertEqual(error.domain, "InvalidData")
            }
            
            // We find our original data back after failure:
            dbQueue.inDatabase { db in
                let reloadedRecord = RecordWithExternalData.fetchOne(db, primaryKey: record.id)!
                XCTAssertEqual(reloadedRecord.data, "foo".dataUsingEncoding(NSUTF8StringEncoding))
            }
            
            // Data property is not lost
            XCTAssertEqual(record.data, "baz".dataUsingEncoding(NSUTF8StringEncoding))
        }
    }
    
    func testFailedInsert() {
        assertNoError {
            let record = RecordWithExternalData()
            record.data = "foo".dataUsingEncoding(NSUTF8StringEncoding)
            
            try dbQueue.inTransaction { db in
                try record.save(db)
                return .Rollback
            }
            
            let fm = NSFileManager.defaultManager()
            if fm.fileExistsAtPath(RecordWithExternalData.externalDataDirectoryPath) {
                let contents = try fm.contentsOfDirectoryAtPath(RecordWithExternalData.externalDataDirectoryPath)
                XCTAssertEqual(contents.count, 0)
            }
            
            // Data property is not lost
            XCTAssertEqual(record.data, "foo".dataUsingEncoding(NSUTF8StringEncoding))
        }
    }
}
