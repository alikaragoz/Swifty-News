////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Foundation
import Realm

/**
Encapsulates iteration state and interface for iteration over a
`RealmCollectionType`.
*/
public final class RLMGenerator<T: Object>: GeneratorType {
    private let generatorBase: NSFastGenerator

    internal init(collection: RLMCollection) {
        generatorBase = NSFastGenerator(collection)
    }

    /// Advance to the next element and return it, or `nil` if no next element exists.
    public func next() -> T? { // swiftlint:disable:this valid_docs
        let accessor = generatorBase.next() as! T?
        if let accessor = accessor {
            RLMInitializeSwiftAccessorGenerics(accessor)
        }
        return accessor
    }
}

/**
 RealmCollectionChange is passed to the notification blocks for Realm
 collections, and reports the current state of the collection and what changes
 were made to the collection since the last time the notification was called.

 The arrays of indices in the .Update varation follow UITableView's batching
 conventions, and can be passed as-is to a table view's batch update functions
 after converting to index paths in the appropriate section. For example, for a
 simple one-section table view, you can do the following:

        self.notificationToken = results.addNotificationBlock { changes
            switch changes {
            case .Initial:
                // Results are now populated and can be accessed without blocking the UI
                self.tableView.reloadData()
                break
            case .Update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the TableView
                self.tableView.beginUpdates()
                self.tableView.insertRowsAtIndexPaths(insertions.map { NSIndexPath(forRow: $0, inSection: 0) },
                    withRowAnimation: .Automatic)
                self.tableView.deleteRowsAtIndexPaths(deletions.map { NSIndexPath(forRow: $0, inSection: 0) },
                    withRowAnimation: .Automatic)
                self.tableView.reloadRowsAtIndexPaths(modifications.map { NSIndexPath(forRow: $0, inSection: 0) },
                    withRowAnimation: .Automatic)
                self.tableView.endUpdates()
                break
            case .Error(let err):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(err)")
                break
            }
        }
 */
public enum RealmCollectionChange<T> {
    /// The initial run of the query has completed (if applicable), and the
    /// collection can now be used without performing any blocking work.
    case Initial(T)

    /// A write transaction has been committed which either changed which objects
    /// are in the collection and/or modified one or more of the objects in the
    /// collection.
    ///
    /// All three of the change arrays are always sorted in ascending order.
    ///
    /// @param deletions The indices in the previous version of the collection
    ///                  which were removed from this one.
    /// @param insertion The indices in the new collection which were added in
    ///                  this version.
    /// @param insertion The indices of the objects in the new collection which
    ///                  were modified in this version.
    case Update(T, deletions: [Int], insertions: [Int], modifications: [Int])

    /// If an error occurs, notification blocks are called one time with a
    /// .Error result and an NSError with details. Currently the only thing
    /// that can fail is opening the Realm on a background worker thread to
    /// calculate the change set.
    case Error(NSError)

    static func fromObjc(value: T, change: RLMCollectionChange?, error: NSError?) -> RealmCollectionChange {
        if let error = error {
            return .Error(error)
        }
        if let change = change {
            return .Update(value,
                deletions: change.deletions as! [Int],
                insertions: change.insertions as! [Int],
                modifications: change.modifications as! [Int])
        }
        return .Initial(value)
    }
}

/**
A homogenous collection of `Object`s which can be retrieved, filtered, sorted,
and operated upon.
*/
public protocol RealmCollectionType: CollectionType, CustomStringConvertible {

    /// Element type contained in this collection.
    typealias Element: Object


    // MARK: Properties

    /// The Realm the objects in this collection belong to, or `nil` if the
    /// collection's owning object does not belong to a realm (the collection is
    /// standalone).
    var realm: Realm? { get }

    /// Returns the number of objects in this collection.
    var count: Int { get }

    /// Returns a human-readable description of the objects contained in this collection.
    var description: String { get }


    // MARK: Index Retrieval

    /**
    Returns the index of the given object, or `nil` if the object is not in the collection.

    - parameter object: The object whose index is being queried.

    - returns: The index of the given object, or `nil` if the object is not in the collection.
    */
    func indexOf(object: Element) -> Int?

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` no objects match.

    - parameter predicate: The `NSPredicate` used to filter the objects.

    - returns: The index of the first matching object, or `nil` if no objects match.
    */
    func indexOf(predicate: NSPredicate) -> Int?

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` if no objects match.

    - parameter predicateFormat: The predicate format string, optionally followed by a variable number
    of arguments.

    - returns: The index of the first matching object, or `nil` if no objects match.
    */
    func indexOf(predicateFormat: String, _ args: AnyObject...) -> Int?


    // MARK: Filtering

    /**
    Returns `Results` containing collection elements that match the given predicate.

    - parameter predicateFormat: The predicate format string which can accept variable arguments.

    - returns: `Results` containing collection elements that match the given predicate.
    */
    func filter(predicateFormat: String, _ args: AnyObject...) -> Results<Element>

    /**
    Returns `Results` containing collection elements that match the given predicate.

    - parameter predicate: The predicate to filter the objects.

    - returns: `Results` containing collection elements that match the given predicate.
    */
    func filter(predicate: NSPredicate) -> Results<Element>


    // MARK: Sorting

    /**
    Returns `Results` containing collection elements sorted by the given property.

    - parameter property:  The property name to sort by.
    - parameter ascending: The direction to sort by.

    - returns: `Results` containing collection elements sorted by the given property.
    */
    func sorted(property: String, ascending: Bool) -> Results<Element>

    /**
    Returns `Results` with elements sorted by the given sort descriptors.

    - parameter sortDescriptors: `SortDescriptor`s to sort by.

    - returns: `Results` with elements sorted by the given sort descriptors.
    */
    func sorted<S: SequenceType where S.Generator.Element == SortDescriptor>(sortDescriptors: S) -> Results<Element>


    // MARK: Aggregate Operations

    /**
    Returns the minimum value of the given property.

    - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    - parameter property: The name of a property conforming to `MinMaxType` to look for a minimum on.

    - returns: The minimum value for the property amongst objects in the collection, or `nil` if the
               collection is empty.
    */
    func min<U: MinMaxType>(property: String) -> U?

    /**
    Returns the maximum value of the given property.

    - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    - parameter property: The name of a property conforming to `MinMaxType` to look for a maximum on.

    - returns: The maximum value for the property amongst objects in the collection, or `nil` if the
               collection is empty.
    */
    func max<U: MinMaxType>(property: String) -> U?

    /**
    Returns the sum of the given property for objects in the collection.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate sum on.

    - returns: The sum of the given property over all objects in the collection.
    */
    func sum<U: AddableType>(property: String) -> U

    /**
    Returns the average of the given property for objects in the collection.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate average on.

    - returns: The average of the given property over all objects in the collection, or `nil` if the
               collection is empty.
    */
    func average<U: AddableType>(property: String) -> U?


    // MARK: Key-Value Coding

    /**
    Returns an Array containing the results of invoking `valueForKey(_:)` using key on each of the collection's objects.

    - parameter key: The name of the property.

    - returns: Array containing the results of invoking `valueForKey(_:)` using key on each of the collection's objects.
    */
    func valueForKey(key: String) -> AnyObject?

    /**
     Returns an Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
     collection's objects.

     - parameter keyPath: The key path to the property.

     - returns: Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
     collection's objects.
     */
    func valueForKeyPath(keyPath: String) -> AnyObject?

    /**
    Invokes `setValue(_:forKey:)` on each of the collection's objects using the specified value and key.

    - warning: This method can only be called during a write transaction.

    - parameter value: The object value.
    - parameter key:   The name of the property.
    */
    func setValue(value: AnyObject?, forKey key: String)

    // MARK: Notifications

    /// :nodoc:
    func _addNotificationBlock(block: (RealmCollectionChange<AnyRealmCollection<Element>>) -> Void) -> NotificationToken
}

private class _AnyRealmCollectionBase<T: Object> {
    typealias Wrapper = AnyRealmCollection<Element>
    typealias Element = T
    var realm: Realm? { fatalError() }
    var count: Int { fatalError() }
    var description: String { fatalError() }
    func indexOf(object: Element) -> Int? { fatalError() }
    func indexOf(predicate: NSPredicate) -> Int? { fatalError() }
    func indexOf(predicateFormat: String, _ args: AnyObject...) -> Int? { fatalError() }
    func filter(predicateFormat: String, _ args: AnyObject...) -> Results<Element> { fatalError() }
    func filter(predicate: NSPredicate) -> Results<Element> { fatalError() }
    func sorted(property: String, ascending: Bool) -> Results<Element> { fatalError() }
    func sorted<S: SequenceType where S.Generator.Element == SortDescriptor>(sortDescriptors: S) -> Results<Element> {
        fatalError()
    }
    func min<U: MinMaxType>(property: String) -> U? { fatalError() }
    func max<U: MinMaxType>(property: String) -> U? { fatalError() }
    func sum<U: AddableType>(property: String) -> U { fatalError() }
    func average<U: AddableType>(property: String) -> U? { fatalError() }
    subscript(index: Int) -> Element { fatalError() }
    func generate() -> RLMGenerator<T> { fatalError() }
    var startIndex: Int { fatalError() }
    var endIndex: Int { fatalError() }
    func valueForKey(key: String) -> AnyObject? { fatalError() }
    func valueForKeyPath(keyPath: String) -> AnyObject? { fatalError() }
    func setValue(value: AnyObject?, forKey key: String) { fatalError() }
    func _addNotificationBlock(block: (RealmCollectionChange<Wrapper>) -> Void)
        -> NotificationToken { fatalError() }
}

private final class _AnyRealmCollection<C: RealmCollectionType>: _AnyRealmCollectionBase<C.Element> {
    let base: C
    init(base: C) {
        self.base = base
    }

    // MARK: Properties

    /// The Realm the objects in this collection belong to, or `nil` if the
    /// collection's owning object does not belong to a realm (the collection is
    /// standalone).
    override var realm: Realm? { return base.realm }

    /// Returns the number of objects in this collection.
    override var count: Int { return base.count }

    /// Returns a human-readable description of the objects contained in this collection.
    override var description: String { return base.description }


    // MARK: Index Retrieval

    /**
    Returns the index of the given object, or `nil` if the object is not in the collection.

    - parameter object: The object whose index is being queried.

    - returns: The index of the given object, or `nil` if the object is not in the collection.
    */
    override func indexOf(object: C.Element) -> Int? { return base.indexOf(object) }

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` no objects match.

    - parameter predicate: The `NSPredicate` used to filter the objects.

    - returns: The index of the first matching object, or `nil` if no objects match.
    */
    override func indexOf(predicate: NSPredicate) -> Int? { return base.indexOf(predicate) }

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` if no objects match.

    - parameter predicateFormat: The predicate format string, optionally followed by a variable number
    of arguments.

    - returns: The index of the first matching object, or `nil` if no objects match.
    */
    override func indexOf(predicateFormat: String, _ args: AnyObject...) -> Int? {
        return base.indexOf(NSPredicate(format: predicateFormat, argumentArray: args))
    }

    // MARK: Filtering

    /**
    Returns `Results` containing collection elements that match the given predicate.

    - parameter predicateFormat: The predicate format string which can accept variable arguments.

    - returns: `Results` containing collection elements that match the given predicate.
    */
    override func filter(predicateFormat: String, _ args: AnyObject...) -> Results<C.Element> {
        return base.filter(NSPredicate(format: predicateFormat, argumentArray: args))
    }

    /**
    Returns `Results` containing collection elements that match the given predicate.

    - parameter predicate: The predicate to filter the objects.

    - returns: `Results` containing collection elements that match the given predicate.
    */
    override func filter(predicate: NSPredicate) -> Results<C.Element> { return base.filter(predicate) }


    // MARK: Sorting

    /**
    Returns `Results` containing collection elements sorted by the given property.

    - parameter property:  The property name to sort by.
    - parameter ascending: The direction to sort by.

    - returns: `Results` containing collection elements sorted by the given property.
    */
    override func sorted(property: String, ascending: Bool) -> Results<C.Element> {
        return base.sorted(property, ascending: ascending)
    }

    /**
    Returns `Results` with elements sorted by the given sort descriptors.

    - parameter sortDescriptors: `SortDescriptor`s to sort by.

    - returns: `Results` with elements sorted by the given sort descriptors.
    */
    override func sorted<S: SequenceType where S.Generator.Element == SortDescriptor>
                        (sortDescriptors: S) -> Results<C.Element> {
        return base.sorted(sortDescriptors)
    }


    // MARK: Aggregate Operations

    /**
    Returns the minimum value of the given property.

    - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    - parameter property: The name of a property conforming to `MinMaxType` to look for a minimum on.

    - returns: The minimum value for the property amongst objects in the collection, or `nil` if the
               collection is empty.
    */
    override func min<U: MinMaxType>(property: String) -> U? { return base.min(property) }

    /**
    Returns the maximum value of the given property.

    - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    - parameter property: The name of a property conforming to `MinMaxType` to look for a maximum on.

    - returns: The maximum value for the property amongst objects in the collection, or `nil` if the
               collection is empty.
    */
    override func max<U: MinMaxType>(property: String) -> U? { return base.max(property) }

    /**
    Returns the sum of the given property for objects in the collection.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate sum on.

    - returns: The sum of the given property over all objects in the collection.
    */
    override func sum<U: AddableType>(property: String) -> U { return base.sum(property) }

    /**
    Returns the average of the given property for objects in the collection.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate average on.

    - returns: The average of the given property over all objects in the collection, or `nil` if the
               collection is empty.
    */
    override func average<U: AddableType>(property: String) -> U? { return base.average(property) }


    // MARK: Sequence Support

    /**
    Returns the object at the given `index`.

    - parameter index: The index.

    - returns: The object at the given `index`.
    */
    override subscript(index: Int) -> C.Element {
        // FIXME: it should be possible to avoid this force-casting
        return unsafeBitCast(base[index as! C.Index], C.Element.self)
    }

    /// Returns a `GeneratorOf<Element>` that yields successive elements in the collection.
    override func generate() -> RLMGenerator<Element> {
        // FIXME: it should be possible to avoid this force-casting
        return base.generate() as! RLMGenerator<Element>
    }


    // MARK: Collection Support

    /// The position of the first element in a non-empty collection.
    /// Identical to endIndex in an empty collection.
    override var startIndex: Int {
        // FIXME: it should be possible to avoid this force-casting
        return base.startIndex as! Int
    }

    /// The collection's "past the end" position.
    /// endIndex is not a valid argument to subscript, and is always reachable from startIndex by
    /// zero or more applications of successor().
    override var endIndex: Int {
        // FIXME: it should be possible to avoid this force-casting
        return base.endIndex as! Int
    }


    // MARK: Key-Value Coding

    /**
    Returns an Array containing the results of invoking `valueForKey(_:)` using key on each of the collection's objects.

    - parameter key: The name of the property.

    - returns: Array containing the results of invoking `valueForKey(_:)` using key on each of the collection's objects.
    */
    override func valueForKey(key: String) -> AnyObject? { return base.valueForKey(key) }

    /**
     Returns an Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
     collection's objects.

     - parameter keyPath: The key path to the property.

     - returns: Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
       collection's objects.
     */
    override func valueForKeyPath(keyPath: String) -> AnyObject? { return base.valueForKeyPath(keyPath) }

    /**
    Invokes `setValue(_:forKey:)` on each of the collection's objects using the specified value and key.

    - warning: This method can only be called during a write transaction.

    - parameter value: The object value.
    - parameter key:   The name of the property.
    */
    override func setValue(value: AnyObject?, forKey key: String) { base.setValue(value, forKey: key) }

    // MARK: Notifications

    /// :nodoc:
    override func _addNotificationBlock(block: (RealmCollectionChange<Wrapper>) -> Void)
        -> NotificationToken { return base._addNotificationBlock(block) }
}

/**
A type-erased `RealmCollectionType`.

Forwards operations to an arbitrary underlying collection having the same
Element type, hiding the specifics of the underlying `RealmCollectionType`.
*/
public final class AnyRealmCollection<T: Object>: RealmCollectionType {

    /// Element type contained in this collection.
    public typealias Element = T
    private let base: _AnyRealmCollectionBase<T>

    /// Creates an AnyRealmCollection wrapping `base`.
    public init<C: RealmCollectionType where C.Element == T>(_ base: C) {
        self.base = _AnyRealmCollection(base: base)
    }

    // MARK: Properties

    /// The Realm the objects in this collection belong to, or `nil` if the
    /// collection's owning object does not belong to a realm (the collection is
    /// standalone).
    public var realm: Realm? { return base.realm }

    /// Returns the number of objects in this collection.
    public var count: Int { return base.count }

    /// Returns a human-readable description of the objects contained in this collection.
    public var description: String { return base.description }


    // MARK: Index Retrieval

    /**
    Returns the index of the given object, or `nil` if the object is not in the collection.

    - parameter object: The object whose index is being queried.

    - returns: The index of the given object, or `nil` if the object is not in the collection.
    */
    public func indexOf(object: Element) -> Int? { return base.indexOf(object) }

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` no objects match.

    - parameter predicate: The `NSPredicate` used to filter the objects.

    - returns: The index of the first matching object, or `nil` if no objects match.
    */
    public func indexOf(predicate: NSPredicate) -> Int? { return base.indexOf(predicate) }

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` if no objects match.

    - parameter predicateFormat: The predicate format string, optionally followed by a variable number
    of arguments.

    - returns: The index of the first matching object, or `nil` if no objects match.
    */
    public func indexOf(predicateFormat: String, _ args: AnyObject...) -> Int? {
        return base.indexOf(NSPredicate(format: predicateFormat, argumentArray: args))
    }

    // MARK: Filtering

    /**
    Returns `Results` containing collection elements that match the given predicate.

    - parameter predicateFormat: The predicate format string which can accept variable arguments.

    - returns: `Results` containing collection elements that match the given predicate.
    */
    public func filter(predicateFormat: String, _ args: AnyObject...) -> Results<Element> {
        return base.filter(NSPredicate(format: predicateFormat, argumentArray: args))
    }

    /**
    Returns `Results` containing collection elements that match the given predicate.

    - parameter predicate: The predicate to filter the objects.

    - returns: `Results` containing collection elements that match the given predicate.
    */
    public func filter(predicate: NSPredicate) -> Results<Element> { return base.filter(predicate) }


    // MARK: Sorting

    /**
    Returns `Results` containing collection elements sorted by the given property.

    - parameter property:  The property name to sort by.
    - parameter ascending: The direction to sort by.

    - returns: `Results` containing collection elements sorted by the given property.
    */
    public func sorted(property: String, ascending: Bool) -> Results<Element> {
        return base.sorted(property, ascending: ascending)
    }

    /**
    Returns `Results` with elements sorted by the given sort descriptors.

    - parameter sortDescriptors: `SortDescriptor`s to sort by.

    - returns: `Results` with elements sorted by the given sort descriptors.
    */
    public func sorted<S: SequenceType where S.Generator.Element == SortDescriptor>
                      (sortDescriptors: S) -> Results<Element> {
        return base.sorted(sortDescriptors)
    }


    // MARK: Aggregate Operations

    /**
    Returns the minimum value of the given property.

    - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    - parameter property: The name of a property conforming to `MinMaxType` to look for a minimum on.

    - returns: The minimum value for the property amongst objects in the collection, or `nil` if the
               collection is empty.
    */
    public func min<U: MinMaxType>(property: String) -> U? { return base.min(property) }

    /**
    Returns the maximum value of the given property.

    - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    - parameter property: The name of a property conforming to `MinMaxType` to look for a maximum on.

    - returns: The maximum value for the property amongst objects in the collection, or `nil` if the
               collection is empty.
    */
    public func max<U: MinMaxType>(property: String) -> U? { return base.max(property) }

    /**
    Returns the sum of the given property for objects in the collection.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate sum on.

    - returns: The sum of the given property over all objects in the collection.
    */
    public func sum<U: AddableType>(property: String) -> U { return base.sum(property) }

    /**
    Returns the average of the given property for objects in the collection.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate average on.

    - returns: The average of the given property over all objects in the collection, or `nil` if the
               collection is empty.
    */
    public func average<U: AddableType>(property: String) -> U? { return base.average(property) }


    // MARK: Sequence Support

    /**
    Returns the object at the given `index`.

    - parameter index: The index.

    - returns: The object at the given `index`.
    */
    public subscript(index: Int) -> T { return base[index] }

    /// Returns a `GeneratorOf<T>` that yields successive elements in the collection.
    public func generate() -> RLMGenerator<T> { return base.generate() }


    // MARK: Collection Support

    /// The position of the first element in a non-empty collection.
    /// Identical to endIndex in an empty collection.
    public var startIndex: Int { return base.startIndex }

    /// The collection's "past the end" position.
    /// endIndex is not a valid argument to subscript, and is always reachable from startIndex by
    /// zero or more applications of successor().
    public var endIndex: Int { return base.endIndex }


    // MARK: Key-Value Coding

    /**
    Returns an Array containing the results of invoking `valueForKey(_:)` using key on each of the collection's objects.

    - parameter key: The name of the property.

    - returns: Array containing the results of invoking `valueForKey(_:)` using key on each of the collection's objects.
    */
    public func valueForKey(key: String) -> AnyObject? { return base.valueForKey(key) }

    /**
     Returns an Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
     collection's objects.

     - parameter keyPath: The key path to the property.

     - returns: Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
     collection's objects.
     */
    public func valueForKeyPath(keyPath: String) -> AnyObject? { return base.valueForKeyPath(keyPath) }

    /**
    Invokes `setValue(_:forKey:)` on each of the collection's objects using the specified value and key.

    - warning: This method can only be called during a write transaction.

    - parameter value: The object value.
    - parameter key:   The name of the property.
    */
    public func setValue(value: AnyObject?, forKey key: String) { base.setValue(value, forKey: key) }

    // MARK: Notifications

    /**
    Register a block to be called each time the collection changes.

    The block will be asynchronously called with the initial collection, and
    then called again after each write transaction which changes the collection
    or any of the items in the collection.

    The block is called on the same thread as it was added on, and can only
    be added on threads which are currently within a run loop. Unless you are
    specifically creating and running a run loop on a background thread, this
    normally will only be the main thread.

    Notifications can't be delivered as long as the runloop is blocked by
    other activity. When notifications can't be delivered instantly, multiple
    notifications may be coalesced. That can include the notification about the
    initial collection.

    You must retain the returned token for as long as you want updates to continue
    to be sent to the block. To stop receiving updates, call stop() on the token.

    - parameter block: The block to be called each time the collection changes.
    - returns: A token which must be held for as long as you want notifications to be delivered.
    */
    @available(*, deprecated=1, message="Use addNotificationBlock with changes")
    @warn_unused_result(message="You must hold on to the NotificationToken returned from addNotificationBlock")
    public func addNotificationBlock(block: (collection: AnyRealmCollection<Element>?,
                                             error: NSError?) -> ()) -> NotificationToken {
        return base._addNotificationBlock { changes in
            switch changes {
            case .Initial(let collection):
                block(collection: collection, error: nil)
                break
            case .Update(let collection, _, _, _):
                block(collection: collection, error: nil)
                break
            case .Error(let error):
                block(collection: nil, error: error)
                break
            }
        }
    }

    /**
     Register a block to be called each time the collection changes.

     The block will be asynchronously called with the initial results, and then
     called again after each write transaction which changes either any of the
     objects in the collection, or which objects are in the collection.

     At the time when the block is called, the collection object will be fully
     evaluated and up-to-date, and as long as you do not perform a write
     transaction on the same thread or explicitly call realm.refresh(),
     accessing it will never perform blocking work.

     Notifications are delivered via the standard run loop, and so can't be
     delivered while the run loop is blocked by other activity. When
     notifications can't be delivered instantly, multiple notifications may be
     coalesced into a single notification. This can include the notification
     with the initial collection. For example, the following code performs a write
     transaction immediately after adding the notification block, so there is no
     opportunity for the initial notification to be delivered first. As a
     result, the initial notification will reflect the state of the Realm after
     the write transaction.

         let results = realm.objects(Dog)
         print("dogs.count: \(dogs?.count)") // => 0
         let token = dogs.addNotificationBlock { (changes: RealmCollectionChange) in
             switch changes {
                 case .Initial(let dogs):
                     // Will print "dogs.count: 1"
                     print("dogs.count: \(dogs.count)")
                     break
                 case .Update:
                     // Will not be hit in this example
                     break
                 case .Error:
                     break
             }
         }
         try! realm.write {
             let dog = Dog()
             dog.name = "Rex"
             person.dogs.append(dog)
         }
         // end of run loop execution context

     You must retain the returned token for as long as you want updates to continue
     to be sent to the block. To stop receiving updates, call stop() on the token.

     - warning: This method cannot be called during a write transaction, or when
                the source realm is read-only.

     - parameter block: The block to be called with the evaluated collection and change information.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    public func addNotificationBlock(block: (RealmCollectionChange<AnyRealmCollection>) -> ())
        -> NotificationToken { return base._addNotificationBlock(block) }

    /// :nodoc:
    public func _addNotificationBlock(block: (RealmCollectionChange<AnyRealmCollection>) -> ())
        -> NotificationToken { return base._addNotificationBlock(block) }
}
