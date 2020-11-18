Rationale: To convert cubic maps from one format to another format.

Note: This program only supports RGB formats 8 bits/component (with or without alpha) graphic files.

Reference: SCNMaterialProperty Documentation - contents - "Using Cube Map Texures" 

Cube maps supported by Apple's SceneKit framework may be provided in several formats e.g. 

a) a vertical strip where the height == 6 * width of the image,
b) a horizontal strip where the width = 6 * height of the image,
c) a spherical projection where the width = 2 * height of the image, and,
d) 6 separate images where the height == width of each image


This simple program can be used to  
a) split an image (vertical/horizontal strip) into 2 or more smaller images, and,
b) merge a set of 2 or more images to produce a single larger image (in the form of a vertical/horizontal strip).

Currently, it cannot convert a spherical projection image to vertical/horizontal strip or 6 cubic maps. A spherical projection image (aka equirectangular projection image) is a single 2D image whose width to height resolution is 2:1.

https://github.com/markpmlim/MetalCubemapping



Note: To be used as a cubic map, the individual images must have a SQUARE resolution. 

Important: Apple’s Core Image function will compute an image’s width or height based on a DPI of 72 dots/inch. For example, if an image’s width and height are both 2048 and its DPI is 96 dots/inch, the returned image dimensions are 1536 x 1536. The user should bear in mind this point if she/he intends to produce images that are a power of 2 in resolutions.


Description of the User Interface.

On running this program, there is no initial window, only the main menubar. The user interface (UI) consists of 2 windows each with some controls. Both windows are opened by selecting the appropriate menu item under the Window menu of the main menubar.

The menu options are:
	"Merge..." (or Option+M)
	"Split..." (or Option+S)



When the "Merge..." menu item is selected, a window with the title "Merge Images" will appear as the topmost window on the desktop. Its UI consists of

a) a table view on the left,
b) an image view on the right, and
c) some buttons below the image view but on the right of the table view.

The user can drag two or more graphic files onto the table view. A drag-and-drop from Finder/Desktop is always added as the last item of the list. Multiple files can be added to the list of items.

There is manual support for the re-ordering of the table items.

Note: Only one table item can be selected for 
a) an internal drag-and-drop during a manual re-arranging of the table items, and,
b) deletion.


Please note: click once to select/highlight the table item before performing an internal drag-and-drop. The drop should preferably be on top of another table item. This is to avoid the potential problem:

When manually rearranging by dragging-and-dropping the user might find it difficult produce the correct order.

It is worth remembering the merging of the images into a single strip depends on the order of the items as displayed in the table view. The first tableview item will be topmost/leftmost sub-image of the vertical/horizontal strip and the last tableview item will be the bottom/rightmost sub-image of the strip.

The recommendation is to rename the graphic files to be merged in alphabetical order and drag-and-drop them one-by-one or several at a time onto the tableview making sure the names of the images are in intended order during the drag-and-drop process.

For example, consider the following set of files with names image0, image1, image2, image3, image4, image5. The names are in already in alphabetic order. There is no need to do an internal-drag-and-drop to rearrange the images if the files are in alphabetical order. In this case, the user can

(a) select and drop all files at one go making sure that during the drag-and-drop operation from Finder/Desktop, the items are in alphabetical order, or

(b) one-by-one drag-and-drop in the following order image0, image1, ... image5. When performing a one-by-one drop, the item to be added should be dropped at the current end of the list.

On the other hand, if the user wants to produce a strip that will be used as a cubic environment map from the following set of images with the names (in alphabetical order):

   back.png, bottom.png, front.png, left.png, right.png and top.png,

then a one-by-one drag-and-drop should be performed in the following order:

   right.png, left.png, top.png, bottom.png, front.png, back.png.


Each drop should be at the current end of the list of tableview items so that no manual re-ordering is necessary.


When a table item is selected, a larger image of the thumbnail displayed in the table view item will be displayed in the image view on its right.

A click on the "Merge" button will combine all images into a horizontal or vertical strip. There is a pop-up button to the right of a label "Merge Mode". If the merge is successful, the "Save" button will be enabled. The user may type Command+S to save the strip. Alternatively, he/she may click on the "Save" button.

There is also a "Delete" button (Command+D) which can be used to remove a table view item. If the table view is empty, all the buttons (except the popup) should be disabled.



The "Split Image" window can be brought up by an Option+S key combination or selecting its menu item under the Window menu of the MainMenu bar. Its UI consists of

a) an image well on the left,
b) a table view to its right, and
c) some buttons below the image well.

The graphic file(horizontal/vertical strip) whose image is to be split into smaller sub-images must be drag-and-dropped onto the image well. A click on the "Split" button will split the image into several smaller images which will then be used to populate the table view. The user may save these sub-images produced by clicking on the "Save" button or Command+S.



Notes on Merging images to be used as a cubic environment or background map.

In order to produce a cube map in a format supported by Apple's SceneKit framework, the names of the image files must be arranged in a certain order. For example, to merge 6 images to produce a vertical/horizontal strip, the first table item is considered to be associated with the +X face, the second table item the -X face etc. 

The images to be merged into a single (horizontal/vertical) strip must have the same width and height e.g. 256x256, 400x400, 512x512, etc. The longer dimension of the resulting image strip will be a multiple of the width/height. To elaborate if 6 images of resolutions 512x512 are merged, the strip will be 512x3072 or 3072x512.

Apple recommends the vertical strip (512x3072) for faster loading.


Notes on Splitting Images

The program will decide on the split mode by comparing the horizontal and vertical resolution of the image strip.

If the horizontal resolution is n times the vertical resolution, the split mode will be assigned as horizontal. On the other hand, if the vertical resolution is n times the horizontal resolution then the split mode is vertical.

After a successful split, the accompanying tableview will be populated with a set of images plus an assigned name. The assigned names are image0, image1, etc. and where image0 is the leftmost/topmost image of the horizontal/vertical image strip.


Save format

The images can be saved in 3 graphic formats:
a) png, b) jpg and (c) heic

Apple macOS (up to Catalina) does not support HEIC 16-bit format.



