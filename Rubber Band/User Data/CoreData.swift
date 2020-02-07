//
//  CoreData.swift
//  RubberBand
//
//  Created by Fernando Zamora on 6/22/19.
//  Copyright © 2019 Artecolote. All rights reserved.
//

import CoreData


/// reference to the song catalog in coredata
//let pc = NSPersistentContainer(name: "catalog")
let pc: NSPersistentContainer = {
//	print("is this the real world")
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
