//
//  File.swift
//  
//
//  Created by Sergey Kazakov on 02/03/2024.
//

import Foundation

typealias Relation<T: IdentifiableEntity> = RelatedEntity<T, Unidirectional>

typealias BiRelation<T: IdentifiableEntity> = RelatedEntity<T, Bidirectional>

enum Unidirectional { }

enum Bidirectional { }

indirect enum RelatedEntity<T: IdentifiableEntity, Direction> {
    case faulted(T.ID)
    case entity(T)
    
    var id: T.ID {
        switch self {
        case .faulted(let id):
            return id
        case .entity(let entity):
            return entity.id
        }
    }
    
    var entity: T? {
        switch self {
        case .faulted:
            return nil
        case .entity(let entity):
            return entity        }
    }
    
    init(_ id: T.ID) {
        self = .faulted(id)
    }
    
    init(_ entity: T) {
        self = .entity(entity)
    }
 
    mutating func normalize() {
        self = .faulted(id)
    }
    
    func normalized() -> Self {
        var copy = self
        copy.normalize()
        return copy
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension RelatedEntity where Direction == Bidirectional {
    func relation() -> Relation<T> {
        Relation.faulted(id)
    }
}

extension RelatedEntity: Codable where T: Codable {
    
}
 
extension Collection  {
    func getEntities<T, Direction>() -> [T] where Element == RelatedEntity<T, Direction> {
        self.map { $0.entity }
            .compactMap { $0 }
    }
    
    func getIds<T, Direction>() -> [T.ID] where Element == RelatedEntity<T, Direction>  {
        self.map { $0.id }
    }
    
    func `in`<T, Direction>(_ repository: Repository) -> [T] where Element == RelatedEntity<T, Direction> {
        repository.findAllExisting(getIds())
    }
}

extension Array {
    mutating func normalize<T, Direction>() where Element == RelatedEntity<T, Direction> {
        self = map { $0.normalized() }
    }
}
