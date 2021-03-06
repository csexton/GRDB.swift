The Design of GRDB.swift
========================

More than caveats or defects, there are a few glitches, or surprises in the GRDB.swift API. We try to explain them here. The interested readers can take them as Swift challenges!


### Why is Record a class, when protocols are all the rage?

Easy: Swift protocols don't provide `super`, and `super` is what turns Record into the flexible base class you need when you implement your specific needs:

```swift
// A Record that makes sure its UUID is set before insertion:
class A : Record {
    var UUID: NSString?
    override func insert(db: Database) throws {
        if UUID == nil {
            UUID = NSUUID().UUIDString
        }
        try super.insert()
    }
}

// A Record that validates itself before saving:
class B : Record {
    override func insert(db: Database) throws {
        try validate()
        try super.insert(db)
    }
    override func update(db: Database) throws {
        try validate()
        try super.update(db)
    }
    func validate() throws {
        ...
    }
}

// A Record that deletes an external resource after being deleted from
// the database:
class C : Record {
    public func delete(db: Database) throws -> DeletionResult {
        switch try super.delete(db) {
        case .RowDeleted:
            try NSFileManager.defaultManager().removeItemAtPath(...)
        case .NoRowDeleted:
            break
        }
    }
}
```

A second reason: the `databaseEdited` flag, which is true when a Record has unsaved changes, is easily provided by the base class Record. Record can manage its internal state *accross method calls*. Protocols could not provide this service without extra complexity.

Yet, don't miss the [RowConvertible](http://cocoadocs.org/docsets/GRDB.swift/0.12.0/Protocols/RowConvertible.html) and [DatabaseMapping](http://cocoadocs.org/docsets/GRDB.swift/0.12.0/Protocols/DatabaseTableMapping.html) protocols: they provide fetching from custom SQL queries and fetching by primary key for free.


### Why must we provide query arguments in an Array, when Swift provides variadic method parameters?

I admit that the array argument below looks odd:

```swift
Int.fetch(db,
    "SELECT COUNT(*) FROM persons WHERE name = ?",
    arguments: ["Arthur"])
```

Well, GRDB provides three fetching methods for each fetchable type:

```swift
// Row
Row.fetch(db, "SELECT ...", arguments: ...)        // DatabaseSequence<Row>
Row.fetchAll(db, "SELECT ...", arguments: ...)     // [Row]
Row.fetchOne(db, "SELECT ...", arguments: ...)     // Row?

// DatabaseValueConvertible
String.fetch(db, "SELECT ...", arguments: ...)     // DatabaseSequence<String>
String.fetchAll(db, "SELECT ...", arguments: ...)  // [String]
String.fetchOne(db, "SELECT ...", arguments: ...)  // String?

// Record (via RowConvertible)
Person.fetch(db, "SELECT ...", arguments: ...)     // DatabaseSequence<Person>
Person.fetchAll(db, "SELECT ...", arguments: ...)  // [Person]
Person.fetchOne(db, "SELECT ...", arguments: ...)  // Person?
```

The `arguments` parameter type is StatementArguments, which is both ArrayLiteralConvertible and DictionaryLiteralConvertible, so that you can write both:

```swift
Int.fetch(db,
    "SELECT COUNT(*) FROM persons WHERE name = ?",
    arguments: ["Arthur"])
Int.fetch(db,
    "SELECT COUNT(*) FROM persons WHERE name = :name",
    arguments: ["name": "Arthur"])
```

Without StatementArguments, that number would be six (three for Array and three for Dictionary), or even nine (three more for variadic parameters). I prefer limiting the API footprint: three methods per fetchable type is just quite fine.

Moreover, one of my pet peeves with SQLite is that it is a pain to write an SQL query with the `IN` operator. SQLite won't natively feed a single `?` placeholder with an array of values, and this forces users to build their own `IN(?,?,?,...)` SQL snippets:

```swift
// Let's load persons whose name is in names:
let names = ["Arthur", "Barbara"]
let questionMarks = Array(count: names.count, repeatedValue: "?").joinWithSeparator(",") // OMG Swift come on
let sql = "SELECT * FROM persons WHERE name IN (\(questionMarks))"
let persons = Person.fetchAll(db, sql, arguments: StatementArguments(names))
```

I wish that in a future version of GRDB we can write instead:

```swift
Person.fetchAll(db,
    "SELECT * FROM persons WHERE name IN (?)",
    arguments: [["Arthur", "Barbara"]]) // one array argument
Person.fetchAll(db,
    "SELECT * FROM persons WHERE name = ? OR name = ?",
    arguments: ["Arthur", "Barbara"])   // two string arguments
```

This will require to distinguish arrays of values from arrays of arrays of values.
