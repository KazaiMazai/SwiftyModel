//
//  File.swift
//  
//
//  Created by Sergey Kazakov on 02/03/2024.
//

import Foundation

protocol IdentifiableEntity {
    associatedtype ID: Hashable & Codable & LosslessStringConvertible
    
    var id: ID { get }
    
    mutating func normalize()
}

extension IdentifiableEntity {
    func normalized() -> Self {
        var copy = self
        copy.normalize()
        return copy
    }
}

extension IdentifiableEntity {
    func relation<E>(_ keyPath: KeyPath<Self, [Relation<E>]?>,
                     option: RelationsRepository.Option) -> RelationsRepository.StoredRelation<Self, E> {
        RelationsRepository.StoredRelation(
            id: id,
            name: keyPath.relationName,
            inverseName: nil,
            relation: self[keyPath: keyPath] ?? [],
            option: option,
            inverseOption: nil
        )
    }
    
    func relation<E>(_ keyPath: KeyPath<Self, Relation<E>?>) -> RelationsRepository.StoredRelation<Self, E> {
        RelationsRepository.StoredRelation(
            id: id,
            name: keyPath.relationName,
            inverseName: nil,
            relation: [self[keyPath: keyPath]].compactMap { $0 },
            option: .replace,
            inverseOption: nil
        )
    }
    
    func relation<E>(_ keyPath: KeyPath<Self, BiRelation<E>?>,
                     inverse: KeyPath<E, BiRelation<Self>?>) -> RelationsRepository.StoredRelation<Self, E> {
        RelationsRepository.StoredRelation(
            id: id,
            name: keyPath.relationName,
            inverseName: inverse.relationName,
            relation: [self[keyPath: keyPath]].compactMap { $0?.relation() },
            option: .replace,
            inverseOption: .replace
        )
    }
    
    func relation<E>(_ keyPath: KeyPath<Self, BiRelation<E>?>,
                     inverse: KeyPath<E, [BiRelation<Self>]?>) -> RelationsRepository.StoredRelation<Self, E> {
        RelationsRepository.StoredRelation(
            id: id,
            name: keyPath.relationName,
            inverseName: inverse.relationName,
            relation: [self[keyPath: keyPath]].compactMap { $0?.relation() },
            option: .replace,
            inverseOption: .append
        )
    }
    
    func relation<E>(_ keyPath: KeyPath<Self, [BiRelation<E>]?>,
                     option: RelationsRepository.Option,
                     inverse: KeyPath<E, BiRelation<Self>?>) -> RelationsRepository.StoredRelation<Self, E> {
        RelationsRepository.StoredRelation(
            id: id,
            name: keyPath.relationName,
            inverseName: inverse.relationName,
            relation: self[keyPath: keyPath]?.compactMap { $0.relation() } ?? [],
            option: option,
            inverseOption: .replace
        )
    }
    
    func relation<E>(_ keyPath: KeyPath<Self, [BiRelation<E>]?>,
                     option: RelationsRepository.Option,
                     inverse: KeyPath<E, [BiRelation<Self>]?>) -> RelationsRepository.StoredRelation<Self, E> {
        RelationsRepository.StoredRelation(
            id: id,
            name: keyPath.relationName,
            inverseName: inverse.relationName,
            relation: self[keyPath: keyPath]?.compactMap { $0.relation() } ?? [],
            option: option,
            inverseOption: .append
        )
    }
}

extension KeyPath {
    var relationName: String {
        String(describing: self)
    }
}

extension IdentifiableEntity {
    static func find(_ id: ID, in repository: Repository) -> Entity<Self> {
        repository.find(id)
    }

    static func find(_ ids: [ID], in repository: Repository) -> [Entity<Self>] {
        repository.find(ids)
    }
}
