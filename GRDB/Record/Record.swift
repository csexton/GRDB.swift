// MARK: - Record

/**
Record is a class that wraps a table row, or the result of any query. It is
designed to be subclassed.

Subclasses opt in Record features by overriding all or part of the core
methods that define their relationship with the database:

- updateFromRow(_:)
- databaseTable
- storedDatabaseDictionary
*/
public class Record : RowConvertible, DatabaseTableMapping, DatabaseStorable {
    
    /// The result of the Record.delete() method
    public enum DeletionResult {
        /// A row was deleted.
        case RowDeleted
        
        /// No row was deleted.
        case NoRowDeleted
    }
    
    
    // MARK: - Initializers
    
    /**
    Initializes a Record.
    
    The returned record is *edited*.
    */
    public init() {
        // IMPLEMENTATION NOTE
        //
        // This initializer is defined so that a subclass can be defined
        // without any custom initializer.
    }
    
    /**
    Initializes a Record from a row.
    
    The returned record is *edited*.
    
    The input row may not come straight from the database. When you want to
    complete your initialization after being fetched, override awakeFromFetch().
    
    - parameter row: A Row
    */
    required public init(row: Row) {
        // IMPLEMENTATION NOTE
        //
        // Swift requires a required initializer so that we can fetch Records
        // in SelectStatement.fetch<Record: GRDB.Record>(type: Record.Type, arguments: StatementArguments? = nil) -> DatabaseSequence<Record>
        //
        // This required initializer *can not* be the simple init(), because it
        // would prevent subclasses to provide handy initializers made of
        // optional arguments like init(firstName: String? = nil, lastName: String? = nil).
        // See rdar://22554816 for more information.
        //
        // OK so the only initializer that we can require in init(row:Row).
        //
        // IMPLEMENTATION NOTE
        //
        // This initializer returns an edited record because the row may not
        // come from the database.
        
        updateFromRow(row)
    }
    
    
    // MARK: - Events
    
    /**
    Don't call this method directly. It is called after a Record has been
    fetched or reloaded.
    
    *Important*: subclasses must invoke super's implementation.
    
    - parameter row: A Row.
    */
    public func awakeFromFetch(row: Row) {
        // Take care of the databaseEdited flag. If the row does not contain
        // all needed columns, the record turns edited.
        //
        // Row may be a metal row which will turn invalid as soon as the SQLite
        // statement is iterated. We need to store an immutable and safe copy.
        referenceRow = row.copy()
    }
    
    /**
    This method is called after a record insertion has been committed, or
    rollbacked. A call to didSave() follows immediately.
    
    Note: in a single transaction, only the last write operation is notified: if
    the record is updated or deleted after its insertion, didInsert() is not
    called.
    
    *Important*: subclasses must invoke super's implementation.
    
    - parameter db: A Database.
    - parameter completion: .Commit, or .Rollback.
    */
    public func didInsert(db: Database, completion: TransactionCompletion) {
        
    }
    
    /**
    This method is called after a record update has been committed, or
    rollbacked. A call to didSave() follows immediately.
    
    Note: in a single transaction, only the last write operation is notified: if
    the record is updated twice, didUpdate() is only called once. It the record
    is deleted after an update, didUpdate() is not called.
    
    *Important*: subclasses must invoke super's implementation.
    
    - parameter db: A Database.
    - parameter completion: .Commit, or .Rollback.
    */
    public func didUpdate(db: Database, completion: TransactionCompletion) {
        
    }
    
    /**
    This method is called after a record insertion or update has been committed,
    or rollbacked.
    
    Note: in a single transaction, only the last write operation is notified: if
    the record is inserted then updated, didSave() is only called once. It the
    record is eventually deleted, didSave() is not called.
    
    *Important*: subclasses must invoke super's implementation.
    
    - parameter db: A Database.
    - parameter completion: .Commit, or .Rollback.
    */
    public func didSave(db: Database, completion: TransactionCompletion) {
        
    }
    
    /**
    This method is called after a record deletion has been committed,
    or rollbacked.
    
    Note: in a single transaction, only the last write operation is notified: if
    the record is eventually inserted again, didDelete() is not called.
    
    *Important*: subclasses must invoke super's implementation.
    
    - parameter db: A Database.
    - parameter completion: .Commit, or .Rollback.
    */
    public func didDelete(db: Database, completion: TransactionCompletion) {
        
    }
    
    
    // MARK: - Core methods
    
    /**
    Returns the name of a database table.
    
    The insert, update, save, delete, exists and reload methods require it: they
    raise a fatal error if databaseTableName is nil.
    
        class Person : Record {
            override class func databaseTableName() -> String? {
                return "persons"
            }
        }
    
    The implementation of the base class Record returns nil.
    
    - returns: The name of a database table.
    */
    public class func databaseTableName() -> String? {
        return nil
    }
    
    /**
    Returns the values that should be stored in the database.
    
    Keys of the returned dictionary must match the column names of the target
    database table (see Record.databaseTableName()).
    
    In particular, primary key columns, if any, must be included.
    
        class Person : Record {
            var id: Int64?
            var name: String?
    
            override var storedDatabaseDictionary: [String: DatabaseValueConvertible?] {
                return [
                    "id": id,
                    "name": name]
            }
        }
    
    The implementation of the base class Record returns an empty dictionary.
    */
    public var storedDatabaseDictionary: [String: DatabaseValueConvertible?] {
        return [:]
    }
    
    /**
    Updates self from a row.
    
    *Important*: subclasses must invoke super's implementation.
    
    Subclasses should update their internal state from the given row:
    
        class Person : Record {
            var id: Int64?
            var name: String?
    
            override func updateFromRow(row: Row) {
                if let dbv = row["id"] { id = dbv.value() }
                if let dbv = row["name"] { name = dbv.value() }
                super.updateFromRow(row) // Subclasses are required to call super.
            }
        }
    
    For performance reasons, the row argument may be reused between several
    record initializations during the iteration of a fetch query. So if you
    want to keep the row for later use, make sure to store a copy:
    `self.row = row.copy()`.
    
    Note that your subclass *could* support mangled column names, and be able to
    load from custom SQL queries like the following:
    
        SELECT id AS person_id, name AS person_name FROM persons;
    
    Yet we *discourage* doing so, because such record loses the ability to track
    changes (see databaseEdited, databaseChanges).
    
    Finally, consider that the input row may not come straight from the
    database. When you want to complete your initialization after being fetched,
    override awakeFromFetch().
    
    - parameter row: A Row.
    */
    public func updateFromRow(row: Row) {
    }
    
    
    // MARK: - Copy
    
    /**
    Returns a copy of `self`, initialized from the values of
    storedDatabaseDictionary.

    Note that the eventual primary key is copied, as well as the
    databaseEdited flag.
    
    - returns: A copy of self.
    */
    @warn_unused_result
    public func copy() -> Self {
        let copy = self.dynamicType.init(row: Row(dictionary: self.storedDatabaseDictionary))
        copy.referenceRow = self.referenceRow
        return copy
    }
    
    
    // MARK: - Changes
    
    /**
    A boolean that indicates whether the record has changes that have not
    been saved.
    
    This flag is purely informative, and does not prevent insert(), update(),
    save() and reload() to perform their database queries. Yet you can prevent
    queries that are known to be pointless, as in the following example:
        
        let json = ...
    
        // Fetches or create a new person given its ID:
        let person = Person.fetchOne(db, primaryKey: json["id"]) ?? Person()
    
        // Apply json payload:
        person.updateFromJSON(json)
                 
        // Saves the person if it is edited (fetched then modified, or created):
        if person.databaseEdited {
            try person.save(db) // inserts or updates
        }
    
    Precisely speaking, a record is edited if its *storedDatabaseDictionary*
    has been changed since last database synchronization (fetch, update,
    insert). Comparison is performed on *values*: setting a property to the same
    value does not trigger the edited flag.
    
    You can rely on the Record base class to compute this flag for you, or you
    may set it to true or false when you know better. Setting it to false does
    not prevent it from turning true on subsequent modifications of the record.
    */
    public var databaseEdited: Bool {
        get {
            return generateDatabaseChanges().next() != nil
        }
        set {
            if newValue {
                referenceRow = nil
            } else {
                referenceRow = Row(dictionary: storedDatabaseDictionary)
            }
        }
    }
    
    /**
    A dictionary of changes that have not been saved.
    
    Its keys are column names.
    
    Its values are `(old: DatabaseValue?, new: DatabaseValue)` pairs, where
    *old* is the reference DatabaseValue, and *new* the current one.
    
    The old DatabaseValue is nil, which means unknown, unless the record has
    been fetched, updated or inserted.
    
    See `databaseEdited` for more information.
    */
    public var databaseChanges: [String: (old: DatabaseValue?, new: DatabaseValue)] {
        var changes: [String: (old: DatabaseValue?, new: DatabaseValue)] = [:]
        for (column: column, old: old, new: new) in generateDatabaseChanges() {
            changes[column] = (old: old, new: new)
        }
        return changes
    }
    
    // A change generator that is used by both databaseEdited and
    // databaseChanges properties.
    private func generateDatabaseChanges() -> AnyGenerator<(column: String, old: DatabaseValue?, new: DatabaseValue)> {
        let oldRow = self.referenceRow
        var newValueGenerator = storedDatabaseDictionary.generate()
        return anyGenerator {
            // Loop until we find a change, or exhaust columns:
            while let (column, newValue) = newValueGenerator.next() {
                let new = newValue?.databaseValue ?? .Null
                guard let old = oldRow?[column] else {
                    return (column: column, old: nil, new: new)
                }
                if new != old {
                    return (column: column, old: old, new: new)
                }
            }
            return nil
        }
    }
    
    
    /// Reference row for the *databaseEdited* property.
    var referenceRow: Row?
    

    // MARK: - CRUD
    
    private enum WriteOperation {
        case None
        case Insert
        case Update
        case Delete
    }
    
    private var lastWriteOperation: WriteOperation = .None
    private func didWrite(db: Database, completion: TransactionCompletion) {
        switch lastWriteOperation {
        case .None:
            break
        case .Insert:
            didInsert(db, completion: completion)
            didSave(db, completion: completion)
        case .Update:
            didUpdate(db, completion: completion)
            didSave(db, completion: completion)
        case .Delete:
            didDelete(db, completion: completion)
        }
        lastWriteOperation = .None
    }
    
    
    /**
    Executes an INSERT statement to insert the record.
    
    On success, this method sets the *databaseEdited* flag to false.
    
    This method is guaranteed to have inserted a row in the database if it
    returns without error.
    
    - parameter db: A Database.
    - throws: A DatabaseError whenever a SQLite error occurs.
    */
    public func insert(db: Database) throws {
        let dataMapper = DataMapper(db, self)
        
        lastWriteOperation = .Insert
        let changes = try dataMapper.insertStatement().execute { (db, completion, insertedRowID) in
            switch completion {
            case .Commit:
                // Insertion was committed...
                if let insertedRowID = insertedRowID {
                    // ... in an implicit transaction. Update the id before
                    // calling didWrite().
                    self.updateRowIDPrimaryKey(dataMapper, rowID: insertedRowID)
                }
            case .Rollback:
                // Insertion has failed: reset the id.
                self.updateRowIDPrimaryKey(dataMapper, rowID: nil)
            }
            self.didWrite(db, completion: completion)
        }
        
        updateRowIDPrimaryKey(dataMapper, rowID: changes.insertedRowID!)
        databaseEdited = false
    }
    
    private func updateRowIDPrimaryKey(dataMapper: DataMapper, rowID: Int64?) {
        guard case let .Managed(idColumnName) = dataMapper.primaryKey else { return }
        updateFromRow(Row(dictionary: [idColumnName: rowID]))
    }
    
    /**
    Executes an UPDATE statement to update the record.
    
    On success, this method sets the *databaseEdited* flag to false.
    
    This method is guaranteed to have updated a row in the database if it
    returns without error.
    
    - parameter db: A Database.
    - throws: A DatabaseError is thrown whenever a SQLite error occurs.
              RecordError.RecordNotFound is thrown if the primary key does
              not match any row in the database and record could not be
              updated.
    */
    public func update(db: Database) throws {
        lastWriteOperation = .Update
        let changes = try DataMapper(db, self).updateStatement().execute { (db, completion, _) in
            self.didWrite(db, completion: completion)
        }
        if changes.changedRowCount == 0 {
            throw RecordError.RecordNotFound(self)
        }
        
        databaseEdited = false
    }
    
    /**
    Saves the record in the database.
    
    If the record has a non-nil primary key and a matching row in the
    database, this method performs an update.
    
    Otherwise, performs an insert.
    
    On success, this method sets the *databaseEdited* flag to false.
    
    This method is guaranteed to have inserted or updated a row in the database
    if it returns without error.
    
    - parameter db: A Database.
    - throws: A DatabaseError whenever a SQLite error occurs, or errors thrown
              by update().
    */
    final public func save(db: Database) throws {
        // Make sure we call self.insert and self.update so that classes that
        // override insert or save have opportunity to perform their custom job.
        
        if DataMapper(db, self).resolvingPrimaryKeyDictionary == nil {
            return try insert(db)
        }
        
        do {
            // TODO: the update failure because of RecordError.RecordNotFound should not be notified to didUpdate()
            try update(db)
        } catch RecordError.RecordNotFound {
            return try insert(db)
        }
    }
    
    /**
    Executes a DELETE statement to delete the record.
    
    On success, this method sets the *databaseEdited* flag to true.
    
    - parameter db: A Database.
    - returns: Whether a row was deleted or not.
    - throws: A DatabaseError is thrown whenever a SQLite error occurs.
    */
    public func delete(db: Database) throws -> DeletionResult {
        lastWriteOperation = .Delete
        let changes = try DataMapper(db, self).deleteStatement().execute { (db, completion, _) in
            self.didWrite(db, completion: completion)
        }
        
        // Future calls to update will throw RecordNotFound. Make the user
        // a favor and make sure this error is thrown even if she checks the
        // databaseEdited flag:
        databaseEdited = true
        
        if changes.changedRowCount > 0 {
            return .RowDeleted
        } else {
            return .NoRowDeleted
        }
    }
    
    /**
    Executes a SELECT statetement to reload the record.
    
    On success, this method sets the *databaseEdited* flag to false.
    
    - parameter db: A Database.
    - throws: RecordError.RecordNotFound is thrown if the primary key does
              not match any row in the database and record could not be
              reloaded.
    */
    final public func reload(db: Database) throws {
        let statement = DataMapper(db, self).reloadStatement()
        if let row = Row.fetchOne(statement) {
            updateFromRow(row)
            awakeFromFetch(row)
        } else {
            throw RecordError.RecordNotFound(self)
        }
    }
    
    /**
    Returns true if and only if the primary key matches a row in the database.
    
    - parameter db: A Database.
    - returns: Whether the primary key matches a row in the database.
    */
    final public func exists(db: Database) -> Bool {
        return (Row.fetchOne(DataMapper(db, self).existsStatement()) != nil)
    }
}


// MARK: - CustomStringConvertible

/// Record adopts CustomStringConvertible.
extension Record : CustomStringConvertible {
    /// A textual representation of `self`.
    public var description: String {
        return "<\(self.dynamicType)"
            + storedDatabaseDictionary.map { (key, value) in
                if let value = value {
                    return " \(key):\(String(reflecting: value))"
                } else {
                    return " \(key):nil"
                }
                }.joinWithSeparator("")
            + ">"
    }
}


// MARK: - RecordError

/// A Record-specific error
public enum RecordError: ErrorType {
    
    /// No matching row could be found in the database.
    case RecordNotFound(Record)
}

extension RecordError : CustomStringConvertible {
    /// A textual representation of `self`.
    public var description: String {
        switch self {
        case .RecordNotFound(let record):
            return "Record not found: \(record)"
        }
    }
}
