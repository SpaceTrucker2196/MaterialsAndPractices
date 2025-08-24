import Foundation
import CoreData

extension NSManagedObject {
    @objc func generateUUID() -> String {
        return UUID().uuidString
    }
}
