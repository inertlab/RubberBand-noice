//
//  CoreData.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/22/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import CoreData


/// reference to the song catalog in coredata
let pc: NSPersistentContainer = {
	let container = NSPersistentContainer(name: "catalog")
	print("this is the container", container)
	//	container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
	container.loadPersistentStores(completionHandler: { (storeDescription, error) in
		if let error = error {
			print("hello no")
			fatalError("Unresolved error \(error)")
		}
	})
	return container
}()



extension NSPersistentStoreCoordinator {
	func destroyPersistentStore(type: String) -> NSPersistentStore? {
		guard
			let store 		= persistentStores.first(where: { $0.type == type }),
			let storeURL 	= store.url
			else {
				return nil
		}
		try? destroyPersistentStore(at: storeURL, ofType: store.type, options: nil)
		return store
	}
}
