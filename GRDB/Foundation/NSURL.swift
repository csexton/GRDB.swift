import Foundation

/// NSURL adopts DatabaseValueConvertible.
extension NSURL : DatabaseValueConvertible {
    
    /// Returns a value that can be stored in the database.
    /// (the URL's absoluteString).
    public var databaseValue: DatabaseValue {
        return DatabaseValue(string: absoluteString)
    }
    
    /**
    Returns an NSURL initialized from *databaseValue*, if possible.
    
    - parameter databaseValue: A DatabaseValue.
    - returns: An optional NSURL.
    */
    public static func fromDatabaseValue(databaseValue: DatabaseValue) -> Self? {
        if let string = String.fromDatabaseValue(databaseValue) {
            return self.init(string: string)
        } else {
            return nil
        }
    }
}
