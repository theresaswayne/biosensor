//@ int(label="Channel for numerator", style = "spinner") Channel_Num
//@ int(label="Channel for denominator", style = "spinner") Channel_Denom
//@ int(label="Channel for transmitted light -- select 0 if none", style = "spinner") Channel_Trans
//@ string(label="Background subtraction method", choices={"Reference image",  "Select an image area","Fixed values","None"}, style="listBox") Background_Method
//@ string(label="Noise subtraction method", choices={"Reference image", "Select an image area", "Fixed values", "None"}, style="listBox") Noise_Method
//@ File(label = "Output folder:", style = "directory") outputDir

// biosensor.ijm
// ImageJ macro to generate a ratio image from a multichannel Z stack with background and noise determination
// Input: multi-channel Z stack image, and optional reference image for background subtraction
// Output: mask and ratio images, results, ROI set, log of background and noise levels
// Theresa Swayne, Columbia University, 2022-2023

// TO USE: Open a multi-channel Z stack image. Run the macro. 

// TODO: Condense choices so background and noise are handled the same way (otherwise we have 16 options)

// TODO: Error handling
// -- no image open 
// -- user clicks OK with no background or ROIS selected
// -- if no ROI -- measure whole image -- write to log

// TODO MAYBE: 
//	user sets threshold type
// 	adapt for single plane images
//  more graceful way to set background to NaN

// --- Setup ----
print("\\Clear"); // clears Log window
roiManager("reset");
run("Clear Results");

// ---- Get image information ----
id = getImageID();
title = getTitle();
dotIndex = indexOf(title, ".");
basename = substring(title, 0, dotIndex);
getDimensions(width, height, channels, slices, frames);
print("Processing",title);

// ---- Prepare images ----
run("Split Channels");
numImage = "C"+Channel_Num+"-"+title;
denomImage = "C"+Channel_Denom+"-"+title;
if (Channel_Trans != 0) {
	transImage = "C"+Channel_Trans+"-"+title;
	}

// ---- Background and noise handling ---
// Background values are subtracted from each channel before initial segmentation
// Noise values are used to threshold each channel after segmentation, before ratioing
// Noise is estimated as the standard deviation of the background

if (Background_Method == "Reference image" || Noise_Method == "Reference image") {
	numBG = 0;
	denomBG = 0;
	subtractImage(Channel_Num, Channel_Denom, Trans);
	numNoise = imgSubResults[0];
	denomNoise = imgSubResults[1];
	print("Reference numerator channel "+Channel_Num+" background StdDev",numNoise);
	print("Reference denominator channel "+Channel_Denom+" background StdDev",denomNoise);
}

if (Background_Method == "Select an image area" || Noise_Method == "Select an image area") { // interactive selection
	print("Measuring user-selected area");
	measBG = measureBackground(Channel_Num, Channel_Denom, Channel_Trans); // array containing preliminary values for background and noise
}
	
if (Background_Method == "Select an image area") { // measured bg 
	numBG = measBG[0];
	denomBG = measBG[2];
	print("Measured numerator channel "+Channel_Num+" background mean", numBG);
	print("Measured denominator channel "+Channel_Denom+" background mean", denomBG);
}
		
else if (Background_Method == "Fixed values") {
		Dialog.create("Enter Fixed Background Values");
		Dialog.addNumber("Numerator channel "+Channel_Num+" background", 0);
		Dialog.addNumber("Denominator channel "+Channel_Denom+" background", 0);
		Dialog.show();
		numBG = Dialog.getNumber();
		denomBG = Dialog.getNumber();
		print("Entered numerator channel "+Channel_Num+" background", numBG);
		print("Entered denominator channel "+Channel_Denom+" background", denomBG);
}

else if (Background_Method == "None") {
		numBG = 0;
		denomBG = 0;
		print("No background was subtracted");
}

if (Noise_Method == "Select an image area") { // use measured noise
	numNoise = measBG[1];
	denomNoise = measBG[3];
	print("Measured numerator channel "+Channel_Num+" background StdDev",numNoise);
	print("Measured denominator channel "+Channel_Denom+" background StdDev",denomNoise);
}
	

else if (Noise_Method == "Fixed values") {
		Dialog.create("Enter Fixed Noise Values");
		Dialog.addNumber("Numerator channel "+Channel_Num+" noise", 1);
		Dialog.addNumber("Denominator channel "+Channel_Denom+" noise", 1);
		Dialog.show();
		numNoise = Dialog.getNumber();
		denomNoise = Dialog.getNumber();
		print("Entered numerator channel "+Channel_Num+" noise", numNoise);
		print("Entered denominator channel "+Channel_Denom+" noise", denomNoise);
}

else if (Noise_Method == "None") {
		numNoise = 1; // default noise value
		denomNoise = 1;
		print("No noise level was provided");
}

// subtract the previously determined background

selectWindow(numImage);
run("Select None");
run("Subtract...", "value="+numBG+" stack");

selectWindow(denomImage);
run("Select None");
run("Subtract...", "value="+denomBG+" stack");

// ---- Segmentation and ratioing ----

// threshold on the sum of the 2 images
imageCalculator("Add create 32-bit stack", numImage,denomImage);
selectWindow("Result of "+numImage);
rename("Sum");
setAutoThreshold("MaxEntropy dark stack"); // change the threshold method if needed
//setOption("BlackBackground", false);
run("Convert to Mask", "method=MaxEntropy background=Dark black"); // change the threshold method if needed

// divide the 8-bit mask by 255 to generate a 0,1 mask
selectWindow("Sum");
run("Divide...", "value=255 stack");
rename("Mask");

// apply the mask to each channel by multiplication
// (a 32-bit result is required so we can change the background to NaN later)
// Apply an additional threshold based on the noise level to eliminate erroneous ratios caused by low signal

imageCalculator("Multiply create 32-bit stack", numImage, "Mask");
selectWindow("Result of "+numImage);
rename("Masked Num");
selectWindow("Masked Num");
setThreshold(numNoise, 1000000000000000000000000000000.0000); // this should ensure all mask pixels are selected 
run("NaN Background", "stack");

imageCalculator("Multiply create 32-bit stack", denomImage, "Mask");
selectWindow("Result of "+denomImage);
rename("Masked Denom");
selectWindow("Masked Denom");
setThreshold(denomNoise, 1000000000000000000000000000000.0000); // this should ensure all mask pixels are selected 
run("NaN Background", "stack");

// calculate the ratio image
imageCalculator("Divide create 32-bit stack", "Masked Num","Masked Denom");
selectWindow("Result of Masked Num");
rename("Ratio");

// ---- Select cells and measure ----

run("Set Measurements...", "area mean integrated display redirect=None decimal=2");
if (Channel_Trans != 0) {
	transImage = "C"+Channel_Trans+"-"+title;
	selectWindow(transImage);
	}
else {
	selectWindow(Sum);
	}
setTool("freehand");
middleSlice = round(slices/2);
Stack.setPosition(1,middleSlice,1);
waitForUser("Mark cells", "Draw ROIs and add to the ROI manager (press T after each).\nThen click OK");

//  save individual channel results

selectWindow("Masked Num");
roiManager("deselect");
roiManager("Multi Measure");
selectWindow("Results");
saveAs("Results", outputDir  + File.separator + basename + "_Num Results.csv");
run("Clear Results");

selectWindow("Masked Denom");
roiManager("deselect");
roiManager("Multi Measure");
selectWindow("Results");
saveAs("Results", outputDir  + File.separator + basename + "_Denom Results.csv");
run("Clear Results");

// save ratio image results

selectWindow("Ratio");
rename(basename + "_ratio"); // so the results will have the original filename attached

roiManager("deselect");
roiManager("Multi Measure"); // user sees dialog to choose rows/columns for output


// ---- Save output files ----

selectWindow("Mask");
saveAs("Tiff", outputDir  + File.separator + basename + "_mask.tif");
selectWindow(basename + "_ratio");
saveAs("Tiff", outputDir  + File.separator + basename + "_ratio.tif");
roiManager("deselect");
roiManager("save", outputDir  + File.separator + basename + "_ROIs.zip");
selectWindow("Results");
saveAs("Results", outputDir  + File.separator + basename + "_Results.csv");
selectWindow("Log");
saveAs("text",outputDir  + File.separator + basename + "_Log.txt");

// ---- Clean up ----

close("*"); // image windows
selectWindow("Log");
run("Close");
roiManager("reset");
run("Clear Results");

// ---- Helper functions ----

function measureBackground(Num, Denom, Trans) { 
	// Measures background from a user-specified ROI
	// Returns the mean and standard deviation of stack background values
	//   (rounded to nearest integer) in numerator and denominator channels
	
	if (Trans != 0) {
		transImage = "C"+Trans+"-"+title;
		selectWindow(transImage);
	}
	else {
		selectWindow(numImage);
	}
	
	// get the ROI
	run("Set Measurements...", "mean standard redirect=None decimal=2");
	setTool("rectangle");
	waitForUser("Mark background", "Draw a background area, then click OK");
	
	// measure background in numerator channel
	selectWindow(numImage);
	run("Restore Selection"); // TODO: save this in the ROI manager
	run("Measure Stack...");
	numBGs = Table.getColumn("Mean");
	numSDs = Table.getColumn("StdDev");
	Array.getStatistics(numBGs, min, max, mean, stdDev);
	numMeasBackground = round(mean);
	Array.getStatistics(numSDs, min, max, mean, stdDev);
	numMeasNoise = round(mean);

	// measure background in denominator channel
	run("Clear Results");
	selectWindow(denomImage);
	run("Restore Selection"); // TODO: save this in the ROI manager
	run("Measure Stack...");
	denomBGs = Table.getColumn("Mean");
	denomSDs = Table.getColumn("StdDev");
	Array.getStatistics(denomBGs, min, max, mean, stdDev);
	denomMeasBackground = round(mean);
	Array.getStatistics(denomSDs, min, max, mean, stdDev);
	denomMeasNoise = round(mean);

	measBGResults = newArray(numMeasBackground, numMeasNoise, denomMeasBackground, denomMeasNoise);
	return measBGResults;
}
// measureBackground function

function subtractImage(Num, Denom, Trans) {

// Takes an input image and a user-supplied multichannel reference image. 
// Calculates the noise in the reference image as the standard deviation of the pixel values (by channel).
// Subtracts the average of the reference stack from the input stack (by channel).
// Returns the corrected channels and the SD values
	
	// get the reference image
	showMessage("On the next dialog please open the reference image file");
	refPath = File.openDialog("Select the reference image file");
  	open(refPath); // open the file
  	
  	//dir = File.getParent(rawPath);
	refName = File.getName(refPath);
	refDotIndex = indexOf(refName, ".");
	refBasename = substring(refName, 0, refDotIndex);
	
	// write info to the log
	print("Subtracting reference image",refName);
	
	selectWindow(refName);
	getDimensions(refwidth, refheight, refchannels, refslices, refframes);
	run("Split Channels");
	numRef = "C"+Num+"-"+refName;
	denomRef = "C"+Denom+"-"+refName;
	if (Trans != 0) {
		transRef = "C"+Channel_Trans+"-"+refName;
	}

	// measure the standard deviation of each fluorescence channel in the stack
	run("Set Measurements...", "mean standard redirect=None decimal=2");

	// measure SD in reference image numerator channel
	selectWindow(numRef);
	run("Select All");
	run("Measure Stack..."); 
	numRefSDs = Table.getColumn("StdDev"); // each row is one slice of the stack
	Array.getStatistics(numRefSDs, min, max, mean, stdDev);
	numRefNoise = round(mean); // average of all the slice standard deviations  

	// measure SD in reference image denominator channel
	run("Clear Results");
	selectWindow(denomRef);
	run("Select All");
	run("Measure Stack...");
	denomRefSDs = Table.getColumn("StdDev");
	Array.getStatistics(denomRefSDs, min, max, mean, stdDev);
	denomRefNoise = round(mean);
	
	// make an average intensity projection, or use the original image if just one slice
	if (refslices > 1) {
		run("Z Project...", "projection=[Average Intensity]");
		selectWindow("MAX_"+refName);
		rename("Reference");
	}
	else {
		selectWindow(rawName);
		rename("Reference");
	}
	
	// subtract the averaged reference from the input image and restore the image name
	imageCalculator("Subtract create 32-bit", numImage,"Reference");
	selectWindow(numImage);
	close();
	selectWindow("Result of "+numImage);
	rename(numImage);
	
	imageCalculator("Subtract create 32-bit", denomImage,"Reference");
	selectWindow(denomImage);
	close();
	selectWindow("Result of "+denomImage);
	rename(denomImage);
	
	selectWindow("Reference");
	close();
	
	imgSubResults = newArray(numRefNoise, denomRefNoise);
	return(imgSubResults);
}
// subtractImage function

