//
//  SplitViewController.swift
//  SplitMerge
//
//  Created by Mark Lim Pak Mun on 09/11/2020.
//  Copyright © 2020 Mark Lim Pak Mun. All rights reserved.
//

import Cocoa
import AVFoundation

enum SplitMode {
    case horizontally
    case vertically
}
// Drag and drop to and from the tableview widget is not supported.
// Dragging from the NSImageView widget to Finder or another application
// is not supported.
class SplitViewController: NSViewController {
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var imageView: NSImageView!       // Image Well
    @IBOutlet var openAccessoryView: NSView!

    var cgImages = [CGImage]()                  // in case we want to save.
    var utType: CFString = "" as CFString       // UTI of the original file.
    var saveFileType = kUTTypePNG               // type is CString
    // This is bind to Popup button of the openAccessoryView widget.
    // IB will sent the messages saveType and setSaveType to our view
    // controller object whenever the user changes the popup control
    // option with a mouse click/key down.
    var saveType: Int {
        get {
            //print("Getting")
            var value: Int = 0      // default to JPG
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
                //print("Setting")
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
    var splitMode: SplitMode = .horizontally
    dynamic var splitRecords = [CustomRecord]()
    dynamic var canSplit = false
    dynamic var canSave = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    // Response to an image dropped from Finder onto the NSImageView widget in UI.
    @IBAction func imageDroppedAction(_ sender: NSImageView?) {
        canSplit = true
        canSave = false
        // This ensures no entries displayed in the table view
        self.splitRecords = [CustomRecord]()
        // Make sure there are no split images
        self.cgImages = [CGImage]()
    }

    // ====== Helper functions ======
    // The color space of the split images is the same as the original.
    // Assumes the raw data of CGImage is already in 8-bit RGB format.
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
     Assumes the sub-images extracted are used subsequently as a cube map texture.
     Check that the common height == the common width; i.e the sub-images
     have a square resolution since they are cubic maps.
     The following additional check if necessary:
     Common height (and width) must be a multiple of a power of 2.
    */
    @IBAction func splitAction(_ sender: Any?) {
        // The original image is either a horizontal or vertical strip
        // consisting of n sub-images.
        let originalImage = imageView.image
        let originalImageHeight = originalImage!.size.height
        let originalImageWidth = originalImage!.size.width
        // The strip must consist of at least 2 sub-images.
        if originalImageHeight == originalImageWidth {
            print("Can't split this square image")
            return
        }
        else if originalImageHeight > originalImageWidth {
        /*
            // Check the width (which is shorter) is 2^n
            if !Int(originalImageWidth).isPowerOfTwo {
                print("The breadth of the vertical strip is not a multiple of 2")
                return
            }
        */
            // Check the height is a multiple of width - vertical strip
            if !Int(originalImageHeight).isMultiple(of: Int(originalImageWidth)) {
                // In math, the definition of length is always the longer side
                // i.e. length > breadth. So in the case of a VERTICAL strip
                // the length is the height and the breadth is the width.
                print("The length of the vertical strip is not a multiple of its breadth")
                return
            }
        }
        else if originalImageWidth > originalImageHeight {
        /*
            // Check the height (which is shorter) is 2^n
            if !Int(originalImageHeight).isPowerOfTwo {
                print("The breadth of the horizontal strip is not a multiple of 2")
                return
            }
        */
            // Check the width is a multiple of height - horizontal strip
            if !Int(originalImageWidth).isMultiple(of: Int(originalImageHeight)) {
                // In math, the definition of length is always the longer side
                // i.e. length > breadth. So in the case of a HORIZONTAL strip
                // the length is the width and the breadth is the height.
                print("The length of the horizontal strip is not a multiple of its breadth")
                return
            }
        }

        let heightMultiple = originalImageWidth/originalImageHeight
        let widthMultiple = originalImageHeight/originalImageWidth
        //print(heightMultiple, widthMultiple)
        var commonWidth: Int = 0
        var commonHeight: Int = 0
        var numberOfSubImages: Int = 0

        if heightMultiple > 1 {
            // horizontal strip: width is heightMultiple times > height
            commonWidth = Int(originalImageWidth/heightMultiple)
            commonHeight = Int(originalImageHeight)
            numberOfSubImages = Int(heightMultiple)
            self.splitMode = .horizontally
        }
        else {
            // vertical strip: height is widthMultiple times > width
            commonWidth = Int(originalImageWidth)
            commonHeight = Int(originalImageHeight/widthMultiple)
            numberOfSubImages = Int(widthMultiple)
            self.splitMode = .vertically
        }
        //print(commonWidth, commonHeight, numberOfImages)
        // Instantiate an instance of CGImage from the original NSImage object.
        // Even if there is no an alpha component, the CGImage has bpc=8, bpp=32.
        let cgImage = originalImage?.cgImage(forProposedRect: nil,
                                             context: nil,
                                             hints: nil)
        if (cgImage!.bitsPerPixel != 32 && cgImage!.bitsPerComponent != 8) {
            print("Only 8-bit RGB images will be split")
        }
        let originalColorSpace = cgImage?.colorSpace
        //print("color space:", originalColorSpace)
        self.utType = (cgImage?.utType)!
        //print("Original UTI:", self.utType)
        // Encapsulate the image strip's raw bitmap data as an instance of Data.
        var rawImageData = cgImage!.dataProvider!.data!
        // The strip's and its sub-images' bytes/pixel.
        let bytesPerPixel = cgImage!.bitsPerPixel/cgImage!.bitsPerComponent
        print(cgImage!.bitsPerPixel, cgImage!.bitsPerComponent)
        // Compute the bytes/row of each sub-image's raw bitmap data.
        let bytesPerRow = bytesPerPixel * commonWidth
        //print(bytesPerPixel, bytesPerRow)
        // Compute the total number of bytes of each sub-image's raw bitmap data.
        let bytesPerImage = bytesPerRow * commonHeight
        //print("common size of split images:", bytesPerImage)

        // Init array of ptrs to the extracted raw bitmap data of the sub-images
        var rawBitMapPtrs = [UnsafeMutableRawPointer?](repeating: nil,
                                                       count: numberOfSubImages)
        for i in 0..<numberOfSubImages {
            rawBitMapPtrs[i] = UnsafeMutableRawPointer.allocate(byteCount: bytesPerImage, alignment: 1)
        }
 
        var nsImages = [NSImage]()
        if self.splitMode == .horizontally {
            let rowSpan = cgImage!.bytesPerRow
            //print("Bytes per row of the horizontal image strip: \(rowSpan)")
            for i in 0..<numberOfSubImages {
                var destPtr = rawBitMapPtrs[i]!.assumingMemoryBound(to: UInt8.self)
                // Compute offset to the start of i-th sub-image within horizontal strip.
                var srcStartOffset = bytesPerRow * i
                for row in 0..<commonHeight {
                    destPtr.withMemoryRebound(to: UInt8.self,
                                              capacity: bytesPerRow, {
                        (destLocation) in
                        let srcLocation = CFDataGetBytePtr(rawImageData) + srcStartOffset
                        destLocation.assign(from: srcLocation,
                                            count: bytesPerRow)
                    })
                    destPtr = destPtr + bytesPerRow
                    // Compute the start of next row of bytes of i-th sub-image
                    // within the horizontal strip
                    srcStartOffset = srcStartOffset + rowSpan
                }
                // We have copied all bytes of the i-th sub-image so proceed to
                // create an instance of CGImage using the sub-image's raw bitmap data
                let data = Data(bytes: rawBitMapPtrs[i]!, count: bytesPerImage)
                defer {
                    rawBitMapPtrs[i]!.deallocate()
                }

                let cgImage = makeCGImage(from: data,
                                          width: commonWidth, height: commonHeight,
                                          space: originalColorSpace!)
                // Save a temporary copy of the CGImage instance in case the user wants to save the images.
                self.cgImages.append(cgImage!)
                // Instantiate an NSImage object will be used to populate the tableview.
                let nsImage = NSImage(cgImage: cgImage!, size: NSZeroSize)
                nsImages.append(nsImage)
            }
        }
        else {
            // Splitting a vertical strip into n sub-images is relatively easier and faster.
            for i in 0..<numberOfSubImages {
                let destPtr = rawBitMapPtrs[i]!.assumingMemoryBound(to: UInt8.self)
                // compute offset to the start of i-th sub-image within the vertical strip
                let srcStartOffset = bytesPerImage * i

                destPtr.withMemoryRebound(to: UInt8.self,
                                          capacity: bytesPerImage, {
                    (destLocation) in
                    let srcLocation = CFDataGetBytePtr(rawImageData)! + srcStartOffset
                    destLocation.assign(from: srcLocation, count: bytesPerImage)
                })
                
                let data = Data(bytes: rawBitMapPtrs[i]!, count: bytesPerImage)
                defer {
                    rawBitMapPtrs[i]!.deallocate()
                }

                // Create an instance of CGImage using the sub-image's raw bitmap data
                let cgImage = makeCGImage(from: data,
                                          width: commonWidth, height: commonHeight,
                                          space: originalColorSpace!)
                cgImages.append(cgImage!)
                // Instantiate an NSImage object will be used to populate the tableview.
                let nsImage = NSImage(cgImage: cgImage!, size: NSZeroSize)
                nsImages.append(nsImage)
            }
        }

        // setup split records for the tableview.
        for i in 0..<numberOfSubImages {
            // The file extension will be appended during a saveAction
            let name = "image" + String(i)
            let rec = CustomRecord(name, nsImages[i])
            self.splitRecords.append(rec)
        }
        // Enable the "Save" action button
        canSave = true
    }

    func write(cgImage: CGImage?, url: URL) {
        guard let image = cgImage
        else {
            return
        }
        if let imageDestination = CGImageDestinationCreateWithURL(url as CFURL,
                                                                  self.saveFileType,
                                                                  1, nil) {
            CGImageDestinationAddImage(imageDestination, image, nil)
            CGImageDestinationFinalize(imageDestination)
        }
    }
    // We won't be using an instance of NSSavePanel because we only allow navigation to
    // location of a folder.
    @IBAction func saveAction(_ sender: Any?) {
        //print("saveAction")
        // Defaults to the file type of the original graphic
        // We are changing the property "saveType" manually.
        // The messages willChangeValueForKey: & didChangeValueForKey:
        // must be sent to IB which will update the popup control visually.
        self.willChangeValue(forKey: "saveType")
        self.saveType = 0
        if self.utType == kUTTypePNG {
            self.saveType = 1
        }
        //print("Original UTI:", self.utType)
        self.didChangeValue(forKey: "saveType")

        let op = NSOpenPanel()
        op.accessoryView = openAccessoryView    // Getter not called!
        op.canChooseFiles = false
        op.canChooseDirectories = true
        op.canCreateDirectories = true
        op.allowsMultipleSelection = false
        op.prompt = "Save Images"
        //op.allowedFileTypes = ["png", "jpg", "tiff", "bmp"]
        op.allowedFileTypes = [String(kUTTypePNG),
                               String(kUTTypeJPEG),
                               AVFileTypeHEIC]
        let button = op.runModal()
        if (button == NSModalResponseOK) {
            self.willChangeValue(forKey: "saveType")
            var fileExt = ""
            if self.saveType == 0 {
                self.saveFileType = kUTTypeJPEG
                fileExt = "jpg"
            }
            else if self.saveType == 1 {
                self.saveFileType = kUTTypePNG
                fileExt = "png"
            }
            else if self.saveType == 2 {
                self.saveFileType = AVFileTypeHEIC as CFString
                fileExt = "heic"
            }
            self.didChangeValue(forKey: "saveType")
            let folderURL = op.directoryURL
            for i in 0..<self.splitRecords.count {
                let rec = self.splitRecords[i]
                let fileURL = folderURL?.appendingPathComponent(rec.fileName).appendingPathExtension(fileExt)
                write(cgImage: self.cgImages[i], url: fileURL!)
            }
        }
    }
}
