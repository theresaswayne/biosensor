// @File(label = "Input folder", style = "directory") input
// @File(label = "Output folder", style = "directory") output
// @File(label="Saved ROI", description="Select the ROI file") roifile
// @String(label = "Input file suffix", value = ".nd2") suffix

// setup
roiManager("reset");

// open ROI
roiManager("Open", roifile);

// process images
processFolder(input);

function processFolder(input) {
// scan folders/subfolders/files to find files with correct suffix

	list = getFileList(input);
	list = Array.sort(list);
	for (i=0; i < list.length; i++) {
		if(File.isDirectory(input + list[i]))
			processFolder("" + input + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	// process each file

	open(input + File.separator + file);
	title = getTitle();
	dotIndex = indexOf(title, ".");
	basename = substring(title, 0, dotIndex);
	
	// select ROI
	roiManager("Select", 0);
	run("Crop");
	
	saveAs("Tiff",  output + File.separator + basename+"_crop.tif");
	close();
	print("Processing: " + input + file);
	print("Saving to: " + output);
}


