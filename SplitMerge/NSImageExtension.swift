//
//  NSImageExtension.swift
//  SplitMerge
//
//  Created by Mark Lim Pak Mun on 09/11/2020.
//  Copyright (c) 2020 Mark Lim Pak Mun. All rights reserved.
//

import Cocoa

// This class is not really necessary
extension NSImage {
	func byScalingProportionally(toSize targetSize : NSSize) ->NSImage {
		let sourceImage = self
		var newImage = NSImage()
		if sourceImage.isValid {
			let imageSize = sourceImage.size
			let width = imageSize.width
			let height = imageSize.height

			let targetWidth = targetSize.width
			let targetHeight = targetSize.height

			var scaleFactor  = CGFloat(0.0)
			var scaledWidth  = targetWidth
			var scaledHeight = targetHeight
			var thumbnailPoint = NSMakePoint(0,0)
			if !NSEqualSizes( imageSize, targetSize ) {
				let widthFactor  = CGFloat(targetWidth / width)
				let heightFactor = CGFloat(targetHeight / height)
				if widthFactor < heightFactor {
					scaleFactor = widthFactor
				}
				else {
					scaleFactor = heightFactor
				}
				scaledWidth  = width  * scaleFactor;
				scaledHeight = height * scaleFactor;
				if ( widthFactor < heightFactor ) {
					thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
				}
				else if ( widthFactor > heightFactor ) {
					thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
				}
			}
			// create a new image to draw into

			newImage = NSImage(size:targetSize)
			newImage.lockFocus()
			var thumbnailRect = NSRect()
			thumbnailRect.origin = thumbnailPoint;
			thumbnailRect.size.width = scaledWidth;
			thumbnailRect.size.height = scaledHeight;
			sourceImage.draw(in: thumbnailRect,
			                 from: NSZeroRect,
			                 operation: .sourceOver,
			                 fraction: 1.0)
			newImage.unlockFocus()
		}
		return newImage
	}
}
