#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix
#@ Boolean (label = "Batch Mode?") batchMode

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	setBatchMode(batchMode);
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	
	FileNoExt = File.nameWithoutExtension;
	MaskFile = output + File.separator + "Mask_" + FileNoExt + ".tif";
	
	// Do the processing here by adding your own code.
	run("Bio-Formats", "open=[" + input + "/" + file +"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT stitch_tiles");
	id = getImageID(); // get original image id
	run("Duplicate...", " "); // duplicate original image and work on the copy
	id_copy = getImageID(); // get copy image id
	
	// get a mask file by multiplying by 255. Result is that both the 1 and 2 value pixels will be converted to white (255), so 
	// that they can be identified as objects in the binary setting. 
	selectImage(id_copy);
	run("Multiply...", "value=255");
	run("Convert to Mask");
	id_mask = getImageID();
	run("Dilate");
	run("Fill Holes");
	run("Watershed");
	save(MaskFile);
	
	run("Analyze Particles...", "size=1000-50000 display exclude clear summarize add");
	run("Clear Results");

	selectImage(id);
	roiManager("Deselect");
	roiManager("Measure");
	
	nR = nResults;
	Label = newArray(nR);
	Number = newArray(nR);
	Mean = newArray(nR);
	Median = newArray(nR);
	Roundness = newArray(nR);
	Alive = newArray(nR);
	Dead = newArray(nR)'
	
	// Grab the old results
	for (i=0; i<nR;i++) {
		Label[i] = getResultLabel(i);
		Number[i] = substring(label[i],5,8);
		Mean[i] = getResult("Mean", i);
		Median[i] = getResult("Median",i);
		Roundness[i] = getResult("Round",i);
		if (Median[i] == 2) {
			Dead[i] = 1
			Alive[i] = 0
		} else if (Median == 1) {
			Dead[i] = 0
			Alive[i] = 1
		} else {
			Dead[i] = 0
			Alive[i] = 0
		}
		roiManager("Select",i);
		roiManager("Rename",number[i]);
	}
	IJ.renameResults("Results_roundness");
	selectWindow("Results_roundness");
	saveAs("Results", output + File.separator + "results_" + FileNoExt + ".csv");
	close("results_" + FileNoExt + ".csv");

	roiManager("Deselect");
	roiManager("Delete"); // clear ROI Manager for next image
	close("*");		
}