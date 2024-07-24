//
//  File.swift
//
//
//  Created by Sergey Kazakov on 02/03/2024.
//

import Foundation

struct Query<Entity: EntityModel> {
    typealias Resolver = () -> Entity?
    
    let context: Context
    let id: Entity.ID
    let resolver: Resolver
    
    init(context: Context, id: Entity.ID) {
        self.context = context
        self.id = id
        self.resolver = { context.find(id) }
    }
    
    func resolve() -> Entity? {
        resolver()
    }
}

private extension Query {
    
    init(context: Context, id: Entity.ID, resolver: @escaping () -> Entity?) {
        self.context = context
        self.id = id
        self.resolver = resolver
    }
    
    func then(_ perform: @escaping (Entity) -> Entity?) -> Query<Entity> {
        Query(context: context, id: id) {
            guard let entity = resolve() else {
                return nil
            }
            
            return perform(entity)
        }
    }
}

extension Collection {
    func resolve<Entity>() -> [Entity] where Element == Query<Entity> {
        compactMap { $0.resolve() }
    }
}

extension Context {
    func query<Entity: EntityModel>(_ id: Entity.ID) -> Query<Entity> {
        query(Entity.self, id: id)
    }
    
    func query<Entity: EntityModel>(_ type: Entity.Type, id: Entity.ID) -> Query<Entity> {
        Query(context: self, id: id)
    }
    
    func query<Entity: EntityModel>(_ ids: [Entity.ID]) -> [Query<Entity>] {
        ids.map { query($0) }
    }
}

extension Query {
    
    func related<Child, Directionality, Constraints>(
        _ keyPath: KeyPath<Entity, ToOneRelation<Child, Directionality, Constraints>>
        
    ) -> Query<Child>? {
        context
            .findChildren(for: Entity.self, relationName: keyPath.name, id: id)
            .first
            .flatMap { Child.ID($0) }
            .map { Query<Child>(context: context, id:  $0) }
    }
    
    func related<Child, Directionality, Constraints>(
        _ keyPath: KeyPath<Entity, ToManyRelation<Child, Directionality, Constraints>>
        
    ) -> [Query<Child>] {
        context
            .findChildren(for: Entity.self, relationName: keyPath.name, id: id)
            .compactMap { Child.ID($0) }
            .map { Query<Child>(context: context, id:  $0) }
    }
}

extension Collection {
    
    func related<Entity, Child, Directionality, Constraints>(
        _ keyPath: KeyPath<Entity, ToOneRelation<Child, Directionality, Constraints>>) -> [Query<Child>]
    
    where Element == Query<Entity> {
        
        compactMap { $0.related(keyPath) }
    }
    
    func related<Entity, Child, Directionality, Constraints>(
        _ keyPath: KeyPath<Entity, ToManyRelation<Child, Directionality, Constraints>>) -> [[Query<Child>]]
    
    where Element == Query<Entity> {
        
        compactMap { $0.related(keyPath) }
    }
}

typealias QueryModifier<T: EntityModel> = (Query<T>) -> Query<T>

extension Query {
    
    func with<Child, Directionality, Constraints>(
        _ keyPath: WritableKeyPath<Entity, ToOneRelation<Child, Directionality, Constraints>>,
        nested: @escaping QueryModifier<Child> = { $0 }) -> Query {
            
        then {
            var entity = $0
            entity[keyPath: keyPath] = related(keyPath)
                .map { nested($0) }
                .flatMap { $0.resolve() }
                .map { .relation($0) } ?? .none
            
            return entity
        }
    }
    
    func with<Child, Directionality, Constraints>(
        _ keyPath: WritableKeyPath<Entity, ToManyRelation<Child, Directionality, Constraints>>,
        fragment: Bool = false,
        nested: @escaping QueryModifier<Child> = { $0 }) -> Query {
            
        then {
            var entity = $0
            let relatedEntities = related(keyPath)
                .map { nested($0) }
                .compactMap { $0.resolve() }
            
            entity[keyPath: keyPath] = fragment ? .fragment(relatedEntities) : .relation(relatedEntities)
            return entity
        }
    }
    
    func id<Child, Directionality, Constraints>(
        _ keyPath: WritableKeyPath<Entity, ToOneRelation<Child, Directionality, Constraints>>) -> Query {
        
        then {
            var entity = $0
            entity[keyPath: keyPath] = related(keyPath)
                .map { .relation(id: $0.id) } ?? .none
            return entity
        }
    }
    
    func ids<Child, Directionality, Constraints>(
        _ keyPath: WritableKeyPath<Entity, ToManyRelation<Child, Directionality, Constraints>>,
        fragment: Bool = false) -> Query {
        
        then {
            var entity = $0
            let ids = related(keyPath).map { $0.id }
            entity[keyPath: keyPath] = fragment ? .fragment(ids: ids) : .relation(ids: ids)
            return entity
        }
    }
}
