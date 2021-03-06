import XCTest
import SQLite
import GRDB

class StephenCelisSQLitePerformanceTests: XCTestCase {

    func testValueAtIndexPerformance() {
        // Here we test the extraction of values by column index.
        
        let databasePath = NSBundle(forClass: self.dynamicType).pathForResource("FetchPerformanceTests", ofType: "sqlite")!
        let db = try! Connection(databasePath)
        
        self.measureBlock {
            // Column access by index requires raw SQL (unlike extraction of values by column name).
            for row in db.prepare("SELECT * FROM items") {
                // Direct Int extraction is not supported.
                let _ = Int(row[0] as! Int64)
                let _ = Int(row[1] as! Int64)
                let _ = Int(row[2] as! Int64)
                let _ = Int(row[3] as! Int64)
                let _ = Int(row[4] as! Int64)
                let _ = Int(row[5] as! Int64)
                let _ = Int(row[6] as! Int64)
                let _ = Int(row[7] as! Int64)
                let _ = Int(row[8] as! Int64)
                let _ = Int(row[9] as! Int64)
            }
        }
    }
    
    func testValueNamedPerformance() {
        // Here we test the extraction of values by column name.
        
        let databasePath = NSBundle(forClass: self.dynamicType).pathForResource("FetchPerformanceTests", ofType: "sqlite")!
        let db = try! Connection(databasePath)
        
        // Column access by name requires query builder (unlike extraction of values by column index).
        let items = Table("items")
        let i0 = Expression<Int>("i0")
        let i1 = Expression<Int>("i1")
        let i2 = Expression<Int>("i2")
        let i3 = Expression<Int>("i3")
        let i4 = Expression<Int>("i4")
        let i5 = Expression<Int>("i5")
        let i6 = Expression<Int>("i6")
        let i7 = Expression<Int>("i7")
        let i8 = Expression<Int>("i8")
        let i9 = Expression<Int>("i9")

        self.measureBlock {
            for item in db.prepare(items) {
                let _ = item[i0]
                let _ = item[i1]
                let _ = item[i2]
                let _ = item[i3]
                let _ = item[i4]
                let _ = item[i5]
                let _ = item[i6]
                let _ = item[i7]
                let _ = item[i8]
                let _ = item[i9]
            }
        }
    }
    
    func testRecordPerformance() {
        // Here we test that we can load "records".
        //
        // Two constraints:
        //
        // 1. Records MUST be initialized from a row, or a row-like object like
        //    a dictionary: rows MUST be introspectable by column name, so that
        //    the record can pick the columns it wants.
        //
        // 2. Fetched records MUST be flagged as having no change.
        
        let databasePath = NSBundle(forClass: self.dynamicType).pathForResource("FetchPerformanceTests", ofType: "sqlite")!
        let db = try! Connection(databasePath)
        
        // Column access by name requires query builder.
        let items = Table("items")
        let i0 = Expression<Int>("i0")
        let i1 = Expression<Int>("i1")
        let i2 = Expression<Int>("i2")
        let i3 = Expression<Int>("i3")
        let i4 = Expression<Int>("i4")
        let i5 = Expression<Int>("i5")
        let i6 = Expression<Int>("i6")
        let i7 = Expression<Int>("i7")
        let i8 = Expression<Int>("i8")
        let i9 = Expression<Int>("i9")
        
        func dictionaryFromRow(row: SQLite.Row) -> [NSObject: AnyObject] {
            return [
                "i0": row[i0],
                "i1": row[i1],
                "i2": row[i2],
                "i3": row[i3],
                "i4": row[i4],
                "i5": row[i5],
                "i6": row[i6],
                "i7": row[i7],
                "i8": row[i8],
                "i9": row[i9]] as [NSObject: AnyObject]
        }
        
        self.measureBlock {
            var records = [PerformanceRecord]()
            for row in db.prepare(items) {
                // SQLite.swift does not provide rows that are introspectable:
                // build our own Row.
                let dictionary = dictionaryFromRow(row)
                let record = PerformanceRecord(dictionary: dictionary)
                record.databaseEdited = false   // Needs to be explicit: GRDB does it implicitly.
                records.append(record)
            }
            XCTAssertEqual(records[4].i2, 1)
            XCTAssertEqual(records[4].i3, 0)
            XCTAssertEqual(records[5].i2, 2)
            XCTAssertEqual(records[5].i3, 1)
        }
    }
}
