//
//  File.swift
//  
//
//  Created by Sergey Kazakov on 02/03/2024.
//

import Foundation
 
public protocol EntityModel {
    associatedtype ID: Hashable & Codable & LosslessStringConvertible
    
    var id: ID { get }
    
    mutating func normalize()
    
    func delete(from context: inout Context) throws
    
    func save(to context: inout Context) throws
}

extension EntityModel {
    static func delete(id: ID, from context: inout Context) throws {
        try Self.query(id, in: context)
            .resolve()?
            .delete(from: &context)
    }
}

extension EntityModel {
    func query(in context: Context) -> Query<Self> {
        Query(context: context, id: id)
    }
    
    static func query(_ id: ID, in context: Context) -> Query<Self> {
        context.query(id)
    }
    
    static func query(_ ids: [ID], in context: Context) -> [Query<Self>] {
        context.query(ids)
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
