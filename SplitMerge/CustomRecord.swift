//
//  ReadOperation.swift
//  SplitMerge
//
//  Created by Mark Lim Pak Mun on 09/11/2020.
//  Copyright (c) 2020 Mark Lim Pak Mun. All rights reserved.
//

import Cocoa

// We need a struct with the following fields
// filename: String
// image: NSImage
// thumbNail: NSImage
// Background read
@objc
class CustomRecord: NSObject {
	@objc dynamic var fileName: String!
    @objc dynamic var thumbNail: NSImage!
	@objc dynamic var nsImage: NSImage!

	init(_ name: String?, _ image: NSImage?) {
		self.fileName = name
		self.nsImage = image
        // A thumbnail image is created for use by a tableview.
        self.thumbNail = image!.byScalingProportionally(toSize:NSMakeSize(64,64))
        //print(self.fileName, self.nsImage)
	}
}
