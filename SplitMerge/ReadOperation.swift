//
//  ReadOperation.swift
//  IIgsXGraphicBrowser
//
//  Created by Mark Lim Pak Mun on 09/11/2020.
//  Copyright (c) 2020 Mark Lim Pak Mun. All rights reserved.
//

import Cocoa

// We need a struct with the following fields
// filename: String
// image: NSImage
// thumbNail: NSImage - may not be necessary
// Background read
class ReadOperation : Operation {
	var srcURL: URL?
	var theDelegate: MergeViewController?

	init(url: URL, delegate: NSViewController?) {
		super.init()
		self.srcURL = url
		self.theDelegate = delegate as? MergeViewController
	}

	override func main() {
		// Creates the various entities
		//let fileExt = srcURL!.pathExtension
        let fileName = srcURL!.deletingPathExtension().lastPathComponent
        //print(fileName, fileExt)
        guard let image = NSImage(contentsOf: srcURL!)
        else {
            let errString = "Error reading " + srcURL!.absoluteString
            print(errString)
            //NSApp.presentError(outErr)
            return
        }
        let rec = CustomRecord(fileName, image)
        // Add a custom record; must be performed on the main thread
        // since the array of Custom Records (mergeRecords) are bind to the UI.
        if (Thread.isMainThread) {
            self.theDelegate!.add(record: rec)
        }
        else {
            self.theDelegate!.performSelector(onMainThread: #selector(MergeViewController.add(record:)),
                                              with: rec,
                                              waitUntilDone: false)
        }
    }
}
