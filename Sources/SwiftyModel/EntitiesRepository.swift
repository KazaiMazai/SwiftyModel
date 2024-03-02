//
//  File.swift
//  
//
//  Created by Sergey Kazakov on 02/03/2024.
//

import Foundation


struct EntitiesRepository {
    typealias EntityID = String
    typealias EntityName = String
    typealias RelationName = String
     
    private var storages: [EntityName: [EntityID: any IdentifiableEntity]] = [:]
    
}

extension EntitiesRepository {
    func all<T>() -> [T] {
        let key = String(reflecting: T.self)
        return storages[key]?.compactMap { $0.value as? T } ?? []
    }
    
    func find<T: IdentifiableEntity>(_ id: T.ID) -> T? {
        let key = EntityName(reflecting: T.self)
        let storage = storages[key] ?? [:]
        return storage[id.description] as? T
    }
    
    func findAll<T: IdentifiableEntity>(_ ids: [T.ID]) -> [T?] {
        ids.map { find($0) }
    }
    
    func findAllExisting<T: IdentifiableEntity>(_ ids: [T.ID]) -> [T] {
        findAll(ids).compactMap { $0 }
    }
}

extension EntitiesRepository {
    
    @discardableResult
    mutating func remove<T: IdentifiableEntity>(_ id: T.ID) -> T? {
        let key = EntityName(reflecting: T.self)
        var storage = storages[key] ?? [:]
        let value = storage[id.description] as? T
        storage.removeValue(forKey: id.description)
        storages[key] = storage
        return value
    }
    
    @discardableResult
    mutating func removeAll<T: IdentifiableEntity>(_ ids: [T.ID]) -> [T?] {
        ids.map { remove($0) }
    }
    
    mutating func save<T: IdentifiableEntity>(_ entity: T) {
        let key = String(reflecting: T.self)
        var storage = storages[key] ?? [:]
        storage[entity.id.description] = entity.normalized()
        storages[key] = storage
    }
    
    mutating func save<T: IdentifiableEntity>(_ entity: T?) {
        guard let entity else {
            return
        }
        
        save(entity)
    }
    
    mutating func save<T: IdentifiableEntity>(_ entities: [T]) {
        entities.forEach { save($0) }
    }
}

extension EntitiesRepository {
    
    mutating func save<T: IdentifiableEntity, R>(_ relatedEntity: RelatedEntity<T, R>) {
        save(relatedEntity.entity)
    }
    
    mutating func save<T: IdentifiableEntity, R>(_ relatedEntities: some Collection<RelatedEntity<T, R>>) {
        relatedEntities.forEach { save($0) }
    }
    
    mutating func save<T: IdentifiableEntity, R>(_ relatedEntities: (any Collection<RelatedEntity<T, R>>)?) {
        guard let relatedEntities else {
            return
        }
        
        save(relatedEntities)
    }
}
