//
//  CoreDataRepository.swift
//  GameBase
//
//  Created by Raul Lermen on 11/07/20.
//  Copyright © 2020 Raul Lermen. All rights reserved.
//

import Foundation
import CoreData

/// Essa classe é utilizada para encapsular a lógica de acesso aos dados do contexto do CoreData.
/// Para adição de regras de negócio na manipulação de classes específicas do CoreData, é aconselhado a criação de extensões desse repositório.
///
/// Utilização:
///
/// Criação de um objeto
/// if let article = CoreDataRepository.create(new: Article.self) {
///    article.title = "Title"
///    article.subtitle = "Subtitle"
///    CoreDataRepository.save()
/// }
///
/// Listagem de objetos
/// if let result = CoreDataRepository.list(type: Article.self) {
///    print(result.map({ $0.title }))
/// }
///
/// Encontrar um objeto
/// if let article = CoreDataRepository.find(type: Article.self, id: 1) {
///    print(article)
/// }
///
/// Apagar um objeto
/// let result: Bool = CoreDataRepository.delete(type: Article.self, id: 1)


public class CoreDataRepository: ObservableObject {
    
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataContext.build()) {
        self.context = context
    }
    
    //MARK: List
    
    func list<T: NSManagedObject>(type: T.Type, with predicate: NSPredicate? = nil) -> [T]? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: T.entityName)
        request.predicate = predicate
        
        do {
            let result = try context.fetch(request)
            return result as? [T]
        } catch {
            return nil
        }
    }
    
    func find<T: NSManagedObject>(type: T.Type, id: Int64) -> T? {
        if !T.containsKey(key: "id") { return nil }
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: T.entityName)
        request.predicate = NSPredicate(format: "id == %@", String(describing: id))
        
        do {
            guard let object = try context.fetch(request).first else { return nil }
            return object as? T
        } catch {
            return nil
        }
    }
    
    func count<T: NSManagedObject>(type: T.Type) -> Int {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: T.entityName)
        do {
            let count = try context.count(for: request)
            return count
        } catch {
            return 0
        }
    }
    
    //MARK: Create
    
    func create<T: NSManagedObject>(new type: T.Type) -> T? {
        let object = NSEntityDescription.insertNewObject(forEntityName: T.entityName, into: context)
        return object as? T
    }
    
    func createOrUpdate<T: NSManagedObject>(new type: T.Type, id: Int64) -> T? {
        if let _ = find(type: type, id: id) {
            delete(type: type, id: id)
        }
        let object = NSEntityDescription.insertNewObject(forEntityName: T.entityName, into: context)
        return object as? T
    }
    
    //MARK: Delete
    
    @discardableResult
    func delete<T: NSManagedObject>(type: T.Type, id: Int64) -> Bool {
        if !T.containsKey(key: "id") { return false }
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: T.entityName)
        request.predicate = NSPredicate(format: "id == %@", String(describing: id))
        
        do {
            guard let result = try context.fetch(request) as? [NSManagedObject] else { return false }
            for item in result {
                context.delete(item)
            }
            return true
        } catch {
            return false
        }
    }
    
    //MARK: Save
    
    @discardableResult
    func save() -> Bool {
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
}

extension NSManagedObject {
    
    static var entityName: String {
        return String(describing: self)
    }
    
    static func containsKey(key: String) -> Bool {
        return entity().attributesByName.map({ $0.key }).contains(key)
    }
}
