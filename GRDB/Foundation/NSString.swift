import Foundation

/// NSString adopts DatabaseValueConvertible
extension NSString: DatabaseValueConvertible {
    
    /// Returns a value that can be stored in the database.
    public var databaseValue: DatabaseValue {
        return DatabaseValue(string: self as String)
    }
    
    /// Returns an NSString initialized from *databaseValue*, if possible.
    ///
    /// - parameter databaseValue: A DatabaseValue.
    /// - returns: An optional NSString.
    public static func fromDatabaseValue(databaseValue: DatabaseValue) -> Self? {
        guard let string = String.fromDatabaseValue(databaseValue) else {
            return nil
        }
        return self.init(string: string)
    }
}
