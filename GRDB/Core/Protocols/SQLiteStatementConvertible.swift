/// When a type adopts both DatabaseValueConvertible and
/// SQLiteStatementConvertible, it is granted with faster access to the SQLite
/// database values.
public protocol SQLiteStatementConvertible {
    
    /// Returns an instance initialized from a raw SQLite statement pointer.
    ///
    /// As an example, here is the how Int64 adopts SQLiteStatementConvertible:
    ///
    ///     extension Int64: SQLiteStatementConvertible {
    ///         public init(sqliteStatement: SQLiteStatement, index: Int32) {
    ///             self = sqlite3_column_int64(sqliteStatement, index)
    ///         }
    ///     }
    ///
    /// When you implement this method, don't check for NULL.
    ///
    /// See https://www.sqlite.org/c3ref/column_blob.html for more information.
    ///
    /// - parameter sqliteStatement: A pointer to a SQLite statement.
    /// - parameter index: The column index.
    init(sqliteStatement: SQLiteStatement, index: Int32)
}


// MARK: - Fetching non null SQLiteStatementConvertible

/// Types that adopt both DatabaseValueConvertible and
/// SQLiteStatementConvertible can be efficiently initialized from
/// database values.
///
/// See DatabaseValueConvertible for more information.
public extension DatabaseValueConvertible where Self: SQLiteStatementConvertible {
    
    // MARK: - Fetching From SelectStatement
    
    /// Returns a sequence of non null values fetched from a prepared statement.
    ///
    ///     let statement = db.selectStatement("SELECT name FROM ...")
    ///     let names = String.fetch(statement) // DatabaseSequence<String>
    ///
    /// The returned sequence can be consumed several times, but it may yield
    /// different results, should database changes have occurred between two
    /// generations:
    ///
    ///     let names = String.fetch(statement)
    ///     Array(names) // Arthur, Barbara
    ///     db.execute("DELETE ...")
    ///     Array(names) // Arthur
    ///
    /// If the database is modified while the sequence is iterating, the
    /// remaining elements are undefined.
    ///
    /// - parameter statement: The statement to run.
    /// - parameter arguments: Statement arguments.
    /// - returns: A sequence of non null values.
    public static func fetch(statement: SelectStatement, arguments: StatementArguments = StatementArguments.Default) -> DatabaseSequence<Self> {
        return statement.fetch(arguments: arguments) {
            let sqliteStatement = statement.sqliteStatement
            if sqlite3_column_type(sqliteStatement, 0) == SQLITE_NULL {
                if let arguments = statement.arguments {
                    fatalError("Could not convert NULL to \(Self.self) while iterating `\(statement.sql)` with arguments \(arguments).")
                } else {
                    fatalError("Could not convert NULL to \(Self.self) while iterating `\(statement.sql)`.")
                }
            } else {
                return Self.init(sqliteStatement: sqliteStatement, index: 0)
            }
        }
    }
    
    /// Returns an array of non null values fetched from a prepared statement.
    ///
    ///     let statement = db.selectStatement("SELECT name FROM ...")
    ///     let names = String.fetchAll(statement)  // [String]
    ///
    /// - parameter statement: The statement to run.
    /// - parameter arguments: Statement arguments.
    /// - returns: An array of non null values.
    public static func fetchAll(statement: SelectStatement, arguments: StatementArguments = StatementArguments.Default) -> [Self] {
        return Array(fetch(statement, arguments: arguments))
    }
    
    
    // MARK: - Fetching From Database
    
    /// Returns a sequence of non null values fetched from an SQL query.
    ///
    ///     let names = String.fetch(db, "SELECT name FROM ...") // DatabaseSequence<String>
    ///
    /// The returned sequence can be consumed several times, but it may yield
    /// different results, should database changes have occurred between two
    /// generations:
    ///
    ///     let names = String.fetch(db, "SELECT name FROM ...")
    ///     Array(names) // Arthur, Barbara
    ///     execute("DELETE ...")
    ///     Array(names) // Arthur
    ///
    /// If the database is modified while the sequence is iterating, the
    /// remaining elements are undefined.
    ///
    /// - parameter db: A Database.
    /// - parameter sql: An SQL query.
    /// - parameter arguments: Statement arguments.
    /// - returns: A sequence of non null values.
    public static func fetch(db: Database, _ sql: String, arguments: StatementArguments = StatementArguments.Default) -> DatabaseSequence<Self> {
        return fetch(db.selectStatement(sql), arguments: arguments)
    }
    
    /// Returns an array of non null values fetched from an SQL query.
    ///
    ///     let names = String.fetchAll(db, "SELECT name FROM ...") // [String]
    ///
    /// - parameter db: A Database.
    /// - parameter sql: An SQL query.
    /// - parameter arguments: Statement arguments.
    /// - returns: An array of non null values.
    public static func fetchAll(db: Database, _ sql: String, arguments: StatementArguments = StatementArguments.Default) -> [Self] {
        return fetchAll(db.selectStatement(sql), arguments: arguments)
    }
}
