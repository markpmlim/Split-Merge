//
//  ViewController.swift
//  SplitMerge
//
//  Created by Mark Lim Pak Mun on 09/11/2020.
//  Copyright © 2020 Mark Lim Pak Mun. All rights reserved.
//

import Cocoa
import AVFoundation

enum MergeMode {
    case horizontally
    case vertically
}

@objc
class MergeViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var saveAccessoryView: NSView!

    var mergedImageData: Data?
    var mergedImageWidth = 0
    var mergedImageHeight = 0
    var desiredMode: MergeMode = .vertically
    var colorSpace: CGColorSpace!               // Color space of strip.
    var saveFileType = kUTTypePNG               // UTI of strip or final image.
 
    // All the properties below are bind to UI widgets in IB.
    @objc dynamic var mergeRecords = [CustomRecord]()
    @objc dynamic var canSave = false
    @objc dynamic var canMerge = false
    @objc dynamic var wasMerged = false
    @objc dynamic var canRemove = false

    // constants
    let kPrivateTableViewData = "Archived Row Data"

    // This is bind to the Popup button of the Save accessory view.
    var saveType: Int {
        get {
            var value: Int!
            if self.saveFileType == kUTTypeJPEG {
                value = 0
            }
            else if self.saveFileType == kUTTypePNG {
                value = 1
            }
            else if self.saveFileType == AVFileTypeHEIC as CFString {
                value = 2
            }
           return value
        }
        set {
            if newValue == 0 {
                self.saveFileType = kUTTypeJPEG
            }
            else if newValue == 1 {
                self.saveFileType = kUTTypePNG
            }
            else if newValue == 2 {
                self.saveFileType = AVFileTypeHEIC as CFString
            }
        }
    }

    // This is bind to the Popup button of the main view.
    var mergeMode: Int {
        get {
            var value: Int!
            if self.desiredMode == .horizontally {
                value = 0
            }
            else if self.desiredMode == .vertically {
                value = 1
            }
            return value
        }
        set {
            //print("Setting")
            if newValue == 0 {
                self.desiredMode = .horizontally
            }
            else if newValue == 1 {
                self.desiredMode = .vertically
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let registeredTypes = [kPrivateTableViewData, NSFilenamesPboardType]
        tableView.register(forDraggedTypes: registeredTypes)

        // No to dragging outside tableview
        tableView.setDraggingSourceOperationMask(.copy, forLocal: true)
        // Yes to dragging within tableview
        tableView.setDraggingSourceOperationMask(.move, forLocal: true)

        // Allow ONE table item to be selected at any one time.
        // This can also be set in IB.
        tableView.allowsMultipleSelection = false
        // Sorting has been disabled.
    }

    override var representedObject: Any? {
        didSet {
        }
    }

    //=============== Implementation of some methods of NSTableViewDataSource protocol

    // Support for internal drags-and-drops within the table view.
    // Support drags-and-drops from Finder/Desktop.
    // No dragging out to Finder/Desktop.
    // Inter-application drops are not supported.
    func tableView(_ tableView: NSTableView,
                   writeRowsWith rowIndexes: IndexSet,
                   to pboard: NSPasteboard) -> Bool {

        let types = [kPrivateTableViewData]
        pboard.declareTypes(types, owner: self)
        let archiveData = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
        pboard.setData(archiveData,
                       forType: kPrivateTableViewData)
        if rowIndexes.count >= 1 {
            return true
        }
        else {
           return false
        }
    }

    /*
     Supports drag-and-drops from Finder/Desktop.
     Supports internal drag-and-drops for a manual re-ordering of
     the tableview items.
    */
    func tableView(_ tableView: NSTableView,
                   validateDrop info: NSDraggingInfo,
                   proposedRow row: Int,
                   proposedDropOperation operation: NSTableViewDropOperation) -> NSDragOperation {
        //print("validateDrop")
        var dragOperation: NSDragOperation = []
        let dragSrc = info.draggingSource() as? NSTableView
        if dragSrc == nil {
            // Drag-and-drops from Finder are allowed.
            let pboard = info.draggingPasteboard()
            let acceptedTypes = [kUTTypeImage]		// an array of UTI type strings
            // The items in classObjects must conform to the NSPasteboardReading protocol
            let classObjects : [AnyClass] = [NSURL.self]
            let searchOptions: [String : AnyObject] = [NSPasteboardURLReadingFileURLsOnlyKey : NSNumber(value: true as Bool),
                                                       NSPasteboardURLReadingContentsConformToTypesKey : acceptedTypes as AnyObject]
            let urls = pboard.readObjects(forClasses: classObjects,
                                          options: searchOptions)
            if !urls!.isEmpty {
                // The urls returned is not  an empty array
                dragOperation = .copy
            }
        }

        if dragSrc == tableView {
            // Accept all internal drag-and-drops.
            dragOperation = .move
        }
        return dragOperation
    }

    /*
     Problem: the CustomRecord object instantiated by the ReadOperation function
     could not be added to the Swift array "mergeRecords".
     Solution is to call the helper function below. Not an elegant solution.
     */
    func add(record: CustomRecord) {
        self.mergeRecords.append(record)
        // There must be at least 2 table items for the "Merge" button to be enabled.
        if self.mergeRecords.count > 1 {
            self.canMerge = true
        }
    }

    /*
     Todo: to accept targeted drops of graphic files from Finder/Desktop.
     Currently the files will be added to the end of the table view.
     */
    func tableView(_ tableView: NSTableView,
                   acceptDrop info: NSDraggingInfo,
                   row: Int,
                   dropOperation: NSTableViewDropOperation) -> Bool {
        //print("acceptDrop")
        var accepted = false
        let draggingSource = info.draggingSource() as? NSTableView
        let pboard = info.draggingPasteboard()
        if draggingSource == nil {
            // Drag-and-drop from Finder/Desktop is handled by this branch.
            // NB. files will never be an optional if the drop has been flagged as validated.
            let files = pboard.propertyList(forType: NSFilenamesPboardType) as! [String]
            for path in files {
                let url = URL(fileURLWithPath: path)
                let appDelegate = NSApp.delegate as! AppDelegate
                // Proceed to read the graphic file on a secondary thread.
                let readOp = ReadOperation(url: url, delegate: self)
                appDelegate.opQueue.addOperations([readOp],
                                                  waitUntilFinished: true)
           }
            self.canRemove = true
            accepted = true
        }
 
        // Use internal drag-and-drops to reorder the images.
        // Such drag-and-drops are handled by the code below.
        // Note: Only 1 table item can be selected at any one time.
        if draggingSource == tableView {
            //print("internal")
            let supportedTypes = [kPrivateTableViewData]
            guard let availableType = pboard.availableType(from: supportedTypes)
            else {
                return false
            }

            // Do we have some data on the paste board?
            if availableType == kPrivateTableViewData {
                let rowData = pboard.data(forType: kPrivateTableViewData)
                let indexSetRow = NSKeyedUnarchiver.unarchiveObject(with: rowData!) as! IndexSet
                // Expect one element in the IndexSet
                let draggedRow = indexSetRow[indexSetRow.startIndex]
                //print(indexSet[indexSet.startIndex], dropOperation.rawValue)
                tableView.beginUpdates()
                if draggedRow < row {
                    // The dragged table item is above the proposed row.
                    let draggedRec = self.mergeRecords[draggedRow]
                    self.mergeRecords.insert(draggedRec, at: row)
                    self.mergeRecords.remove(at: draggedRow)

                    tableView.noteNumberOfRowsChanged()
                    tableView.moveRow(at: draggedRow, to: row-1)
                }
                else {
                    // The dragged table item is below the proposed row.
                    let draggedRec = self.mergeRecords[draggedRow]
                    self.mergeRecords.remove(at: draggedRow)
                    self.mergeRecords.insert(draggedRec, at:row)

                    tableView.noteNumberOfRowsChanged()
                    tableView.moveRow(at: draggedRow, to: row)
                }
                tableView.endUpdates()
                tableView.deselectAll(self)
            }
            accepted = true
        }
        return accepted
    }

    // The "Delete" button is only enabled if there are at least 1 file.
    // Multiple selected objects are not allowed.
    @IBAction func deleteAction(_ sender: Any?) {
        //print("deleteAction")
        let selectedObjs = arrayController.selectedObjects as? [CustomRecord]
        let selectedObj = selectedObjs![0]
        arrayController.removeObject(selectedObj)
        if self.mergeRecords.count == 1 {
            self.canMerge = false
        }
        if mergeRecords.count == 0 {
            self.canRemove = false
        }
    }

    /*
     Instantiate an instance of CGImage from the raw bitMap data.
     */
    func makeCGImage(from rawData: Data,
                     width: Int, height: Int,
                     space colorSpace: CGColorSpace) -> CGImage? {

        let pixelByteCount = 4 * MemoryLayout<UInt8>.size
        let imageBytesPerRow = width * pixelByteCount
        let imageByteCount = imageBytesPerRow * height
        let imageBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: imageByteCount)
        defer {
            imageBytes.deallocate()
        }
        rawData.copyBytes(to: imageBytes,
                          count: imageByteCount)
        // Assumes the raw data of CGImage is in RGB/RGBA format.
        // The alpha component is stored in the least significant bits of each pixel.
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let bitmapContext = CGContext(data: nil,
                                            width: width,
                                            height: height,
                                            bitsPerComponent: 8,
                                            bytesPerRow: imageBytesPerRow,
                                            space: colorSpace,
                                            bitmapInfo: bitmapInfo)
        else {
            return nil
        }

        bitmapContext.data?.copyMemory(from: imageBytes,
                                       byteCount: imageByteCount)
        let image = bitmapContext.makeImage()
        return image
    }

    /*
     Output the instance of CGImage at the given url.
     */
    func write(cgImage: CGImage?, url: URL) {
        guard let image = cgImage
        else {
            return
        }
        if let imageDestination = CGImageDestinationCreateWithURL(url as CFURL,
                                                                  self.saveFileType,
                                                                  1,
                                                                  nil) {
            CGImageDestinationAddImage(imageDestination, image, nil)
            CGImageDestinationFinalize(imageDestination)
        }
    }

    /*
     More checks maybe required.
     Enforced: the images must have the same width and same height.
     The common width must be equal to common height; we assume
     the strip produced is to be used as a cube map.
     Assumes the set of original images have the same color space.
      Additional checks:
     Can be enforced: thecommon height (and width) must be a
     multiple of a power of 2 e.g. 128x128, 256x256, 512x512 etc.
     Uncomment the code for this check.
     */
    @IBAction func mergeAction(_ sender: Any?) {
        // Call this function to merge the n sub-images.
        let numberOfImages = self.mergeRecords.count
        //print("# of images to be merged:", numberOfImages)
        let commonHeight = Int(self.mergeRecords[0].nsImage.size.height)
        let commonWidth = Int(self.mergeRecords[0].nsImage.size.width)
        //print(commonWidth, commonHeight)
        if commonHeight != commonWidth {
            print("The height of an image must be equal to its width")
            return
        }
        // loop thru the rest of the images to check if they have
        // the same common width and common height.
        var noMore = false          //continue looping? true => no, false=yes
        var allEqual = true
        var k = 1
        repeat {
            let imageWidth = Int(self.mergeRecords[k].nsImage.size.width)
            let imageHeight = Int(self.mergeRecords[k].nsImage.size.height)
            if imageWidth != commonWidth || imageHeight != commonHeight {
                noMore = true
                allEqual = false
                break
            }
            else {
                k += 1
                if k == numberOfImages {
                    noMore = true
                }
            }
        } while !noMore

        if !allEqual {
            print("All images must have the same common width and height")
            return
        }
/*
        if !Int(commonWidth).isPowerOfTwo {
            print("The common height & width of each image must be a power of 2.")
            return
        }
*/
        if self.desiredMode == .horizontally {
            self.mergedImageWidth = commonWidth * numberOfImages
            self.mergedImageHeight = commonHeight
        }
        else {
            self.mergedImageWidth = commonWidth
            self.mergedImageHeight = commonHeight * numberOfImages
        }

        // The original set of CGImage to be merged into a larger image.
        var cgImages = [CGImage?](repeating: nil,
                                  count: numberOfImages)
        // Assumes are images are bpc=8.
        var all8Bit = true
        for i in 0..<numberOfImages {
            let nsImage = self.mergeRecords[i].nsImage
            let cgImage = nsImage?.cgImage(forProposedRect: nil,
                                           context: nil,
                                           hints: nil)
            if (cgImage!.bitsPerPixel != 32 && cgImage!.bitsPerComponent != 8) {
                // Even RGB (w/o alpha) is flagged as having a bpp=32.
                all8Bit = false
                break
            }
            cgImages[i] = cgImage
        }
        if !all8Bit {
            // KIV: put up dialog box here.
            print("This application only merges 8-bit RGB images")
            return
        }
        self.wasMerged = true           // unused.
        self.canSave = true             // Enable the "Save" button
        // Preserve the color space. We assume all images in the set has the same color space.
        self.colorSpace = cgImages[0]!.colorSpace!
        //print("Color Space", self.colorSpace)

        // All images in the set have the same square resolution.
        // KIV. Images with colors that are half-floats and floats.
        let bytesPerRow = cgImages[0]!.bytesPerRow
        let componentsPerPixel = cgImages[0]!.bitsPerPixel/cgImages[0]!.bitsPerComponent
        // Compute the common size of each of the original set of images.
        let bytesPerImage = cgImages[0]!.bytesPerRow * commonHeight
        // Encapsulate the raw bitmap data of each of the original
        // set of images as instances of CFData.
        var bitmapData = [CFData]()
        for i in 0..<numberOfImages {
            let bmData = cgImages[i]!.dataProvider!.data!
            bitmapData.append(bmData)
        }

        // The ptr to the memory block of the raw bitmap data of the merged image.
        let rawBitMapPtr = UnsafeMutableRawPointer.allocate(byteCount: bytesPerImage*numberOfImages,
                                                            alignment: 1)
        defer {
            rawBitMapPtr.deallocate()
        }

        if self.desiredMode == .horizontally {
            // Typed pointer to the memory block of the raw bitmap data of the merged image.
            let startPtr = rawBitMapPtr.assumingMemoryBound(to: UInt8.self)
            // Number of bytes for a row of pixels of the merged image.
            let rowSpan = bytesPerRow * numberOfImages

            for row in 0..<self.mergedImageHeight {
                // Compute the ptr to the start of each row of merged image.
                var destPtr = startPtr + rowSpan * row
                // Compute the offset from the beginning of the source image.
                // Note: all source images must be of the same width and same height.
                let srcOffset = bytesPerRow * row
                //let srcEndIndex = srcStartIndex + bytesPerRow
                for i in 0..<numberOfImages {
                    destPtr.withMemoryRebound(to: UInt8.self,
                                              capacity: bytesPerRow, {
                        (destLocation) in
                        let srcLocation = CFDataGetBytePtr(bitmapData[i])! + srcOffset
                        destLocation.assign(from: srcLocation,
                                            count: bytesPerRow)
                    })
                    // Compute next section of the row (of the merged image) to be filled.
                    destPtr = destPtr + bytesPerRow
                }
            }
        }
        else {
            var destPtr = rawBitMapPtr.assumingMemoryBound(to: UInt8.self)
            for i in 0..<numberOfImages {
                // An unsafeMutablePointer's withMemoryRebound method allows us to temporarily
                // change the Pointee type from UInt8 to UInt16, Float etc.
                destPtr.withMemoryRebound(to: UInt8.self,
                                          capacity: bytesPerImage, {
                    (destLocation) in
                    let srcLocation = CFDataGetBytePtr(bitmapData[i])!  // unsafeMutablePointer
                    destLocation.assign(from: srcLocation, count: bytesPerImage)
                })
                destPtr = destPtr + bytesPerImage
           }
        }
        // Encapsulate the raw bitmap of the merged image as an instance of Data.
        // This object will be used by "saveAction"
        self.mergedImageData = Data(bytes: rawBitMapPtr,
                                    count: bytesPerImage*numberOfImages)
    }

 
    @IBAction func saveAction(_ sender: Any?) {
        if self.mergedImageData == nil {
            return
        }

        let sp = NSSavePanel()
        sp.accessoryView = saveAccessoryView
        sp.canCreateDirectories = true
        sp.allowedFileTypes = [String(kUTTypePNG),
                               String(kUTTypeJPEG),
                               AVFileTypeHEIC]
        sp.nameFieldStringValue = "MergedImage"
        sp.prompt = "Save Merged Image"
        let button = sp.runModal()
        if (button == NSModalResponseOK) {
            var fileExt = "jpg"
            self.willChangeValue(forKey: "saveType")
            if self.saveType == 0 {
                fileExt = "jpg"
            }
            else if self.saveType == 1 {
                fileExt = "png"
            }
            else if self.saveType == 2 {
                fileExt = "heic"
            }
            self.didChangeValue(forKey: "saveType")
            let fileName = sp.url?.deletingPathExtension()
            let fileURL = fileName?.appendingPathExtension(fileExt)

            let cgImage = makeCGImage(from: self.mergedImageData!,
                                      width: self.mergedImageWidth,
                                      height: self.mergedImageHeight,
                                      space: self.colorSpace)
            write(cgImage: cgImage, url: fileURL!)
        }
    }
}

