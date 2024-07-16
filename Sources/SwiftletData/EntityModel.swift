//
//  File.swift
//  
//
//  Created by Sergey Kazakov on 02/03/2024.
//

import Foundation

public protocol Storable {
    func save(_ repository: inout Repository)
}

public protocol EntityModel: Storable {
    associatedtype ID: Hashable & Codable & LosslessStringConvertible
    
    var id: ID { get }
    
    mutating func normalize()
    
    static func mergeStraregy() -> MergeStrategy<Self>
}

public extension EntityModel {
    static func mergeStraregy() -> MergeStrategy<Self> {
        MergeStrategy.replace
    }
}

extension EntityModel {
    func query(in repository: Repository) -> Query<Self> {
        Query(repository: repository, id: id)
    }
    
    static func query(_ id: ID, in repository: Repository) -> Query<Self> {
        repository.query(id)
    }
    
    static func query(_ ids: [ID], in repository: Repository) -> [Query<Self>] {
        repository.query(ids)
    }
}

extension EntityModel {
    func normalized() -> Self {
        var copy = self
        copy.normalize()
        return copy
    }
}

extension KeyPath {
    var name: String {
        String(describing: self)
    }
}

extension EntityModel {
    func relationIds<Child, Direction, Cardinality, Constraint>(
        _ keyPath: KeyPath<Self, Relation<Child, Direction, Cardinality, Constraint>>) -> [Child.ID] {
        self[keyPath: keyPath].ids
    }
    
    func relation<Child, Direction, Cardinality, Constraint>(
        _ keyPath: KeyPath<Self, Relation<Child, Direction, Cardinality, Constraint>>) -> Relation<Child, Direction, Cardinality, Constraint> {
        self[keyPath: keyPath]
    }
}