//@ String (label = "Colorization method:",choices={"Intensity modulated", "Unmodulated"}, style="radioButtonHorizontal") Color_Method
//@ Double (label="Minimum displayed value:", value=0.00, persist=true, style="format:#.##") minDisplay
//@ Double (label="Maximum displayed value:", value=1.00, persist=true, style="format:#.##") maxDisplay
//@ String (label = "Projection mode for Z stacks:", choices={"Max", "Average"}, style="radioButtonHorizontal") Proj_Method
//@ File(label = "Output folder:", style = "directory") outputDir

// ImageJ/Fiji macro to create colorized images with desired intensity range from ratio images
// Outputs: colorized RGB images with and without calibration bars
// 
// Theresa Swayne, Columbia University, 2022-2023

// TO USE: Open a ratio image. Run the script.
// If intensity modulation is selected, the user will be prompted for the original data file
// The Unmodulated option produces an image with each pixel having equal brightness, so it is most suitable for masked images

// ---- Setup ----
roiManager("reset");

// ---- Get image information ----
id = getImageID();
title = getTitle();
dotIndex = indexOf(title, "."); // will throw error if no dot
basename = substring(title, 0, dotIndex);
getDimensions(width, height, channels, slices, frames);
selectWindow(title);

// ---- Project if needed ----
if (slices > 1) {
	if (Proj_Method == "Max") {
		run("Z Project...", "projection=[Max Intensity]");
		selectWindow("MAX_"+title);
		rename("Ratio");
	}
	
	if (Proj_Method == "Average") {
		run("Z Project...", "projection=[Average Intensity]");
		selectWindow("AVG_"+title);
		rename("Ratio");
	}
	selectWindow(title);
	close();
}
else {
	selectWindow(title);
	rename("Ratio");
}

// ---- Create colorized image ----

if (Color_Method == "Intensity modulated") {
	// create the HSB stack
	intensity_mod(minDisplay, maxDisplay);
	
	// set display contrast and LUT on the ratio image
	selectWindow("Ratio");
	setMinAndMax(minDisplay, maxDisplay);
	run("Spectrum"); // required to correspond to the hue value in the HSV image
	
	// create a color calibration bar 
	// (change the parameters to suit your preference)
	run("Calibration Bar...", "location=[Upper Right] fill=Black label=White number=5 decimal=2 font=12 zoom=1 overlay");
	// save the bar overlay in the ROI Mgr
	run("To ROI Manager");
	roiManager("Show All without labels");

	// generate the RGB version without bar	
	selectWindow("Intensity_Modulated");
	run("Duplicate...", "title=Color duplicate");
	selectWindow("Color");
	run("RGB Color");
	
	// generate the RGB verson with bar
	selectWindow("Color");
	run("From ROI Manager");
	roiManager("Show All without labels");
	run("Flatten"); // generates a new window
	selectWindow("Color-1");
	rename("ColorWithBar");
	
	// save images
	//selectWindow("Intensity_Modulated");
	//saveAs("Tiff", outputDir  + File.separator + basename + "_IntensityModulated_HSB.tif");

	selectWindow("Color");
	run("Hide Overlay");
	saveAs("Tiff", outputDir  + File.separator + basename + "_IntensityModulated_RGB.tif");
	
	selectWindow("ColorWithBar");
	saveAs("Tiff", outputDir  + File.separator + basename + "_IntensityModulated_RGB_with_bar.tif");
	
}
else if (Color_Method == "Unmodulated") {
	selectWindow("Ratio");
	setMinAndMax(minDisplay, maxDisplay);
	
	Dialog.create("Select color scheme");
	Dialog.addChoice("Display LUT:", newArray("Fire", "Rainbow RGB", "Import from LUT file"));
	Dialog.show();
	
	Color_LUT  = Dialog.getChoice();
	
	if (Color_LUT == "Import from LUT file") {
		showMessage("On the next dialog please open the desired LUT file");
		run("LUT... ");
	}
	else {
		run(Color_LUT); 
	}
	
	// create a color calibration bar 
	// (change the parameters to suit your preference)
	run("Calibration Bar...", "location=[Upper Right] fill=Black label=White number=5 decimal=2 font=12 zoom=1 overlay");
	// save the bar overlay in the ROI Mgr
	run("To ROI Manager");

	// generate the RGB version without bar	
	selectWindow("Ratio");
	run("Duplicate...", "title=Color");
	selectWindow("Color");
	run("Hide Overlay");
	run("RGB Color");
	
	// generate the RGB verson with bar
	selectWindow("Color");
	run("From ROI Manager"); 
	roiManager("Show All without labels");
	run("Flatten"); // generates a new window
	selectWindow("Color-1");
	rename("ColorWithBar");

	// save images
	selectWindow("Color");
	saveAs("Tiff", outputDir  + File.separator + basename + "_Color_RGB.tif");
	
	selectWindow("ColorWithBar");
	saveAs("Tiff", outputDir  + File.separator + basename + "_Color_with_bar.tif");

}
else {
	showMessage("I don't know what color method to use");
}

// ---- Clean up  ----
roiManager("reset");
close("*"); // all image windows

// ---- Helper function ---

function intensity_mod(min, max) {
	// generate an intensity modulated ratio image based on the sum of the two raw image channels

	// solicit a raw data image and relevant channels, return the sum of the fluorescent channels
	
	// get the raw data image
	showMessage("On the next dialog please open the raw data file");
	rawPath = File.openDialog("Select the raw data file corresponding to the ratio image");
  	open(rawPath); // open the file
  	
  	//dir = File.getParent(rawPath);
	rawName = File.getName(rawPath);
	rawDotIndex = indexOf(rawName, ".");
	rawBasename = substring(rawName, 0, rawDotIndex);
	
	selectWindow(rawName);
	getDimensions(rawwidth, rawheight, rawchannels, rawslices, rawframes);

	if (rawslices > 1) {
		run("Z Project...", "projection=[Max Intensity]");
		selectWindow("MAX_"+rawName);
		rename("Raw");
		selectWindow(rawName);
		close();
	}
	else {
		selectWindow(rawName);
		rename("Raw");
	}
	// get the channels of interest
	Dialog.create("Which channels to use for intensity information? (provide 1 or 2 channel numbers)"); // you can use the same or different channels
	Dialog.addNumber("Fluorescence Channel A", 1);
	Dialog.addNumber("Fluorescence Channel B", 2);
	Dialog.show();
	firstCh = Dialog.getNumber();
	secondCh = Dialog.getNumber();
	
	// calculate the average intensity
	run("Split Channels");
	firstChImage = "C"+firstCh+"-Raw";
	secondChImage = "C"+secondCh+"-Raw";
	imageCalculator("Add create 32-bit", firstChImage,secondChImage);
	selectWindow("Result of "+firstChImage);
	run("Divide...", "value=2");
	rename("Average");

	// ---- Make an intensity modulated image ----
	
	// create a new single-channel RGB image to hold the data
	newImage("Intensity_Modulated", "RGB black", rawwidth, rawheight, 1, 1, 1);
	
	// convert the RGB image to the HSB colorspace
	selectWindow("Intensity_Modulated");
	run("HSB Stack");
	
	// hue will be the ratio value
	selectWindow("Ratio");
	run("Duplicate...", "title=copy_ratio");
	run("Conversions...", "scale"); // ratios will be scaled to 0-255
	selectWindow("copy_ratio");
	setMinAndMax(min, max);
	run("Select All");
	run("Copy");
	selectWindow("Intensity_Modulated");
	setSlice(1); // hue
	run("Paste");
	
	// saturation should be all white (max value)
	selectWindow("Intensity_Modulated");
	setSlice(2); // saturation
	setForegroundColor(255, 255, 255); // white
	run("Select All");
	run("Fill", "slice");
	run("Select None");
	
	// a popular choice for the value is the sum (or average) of the two channels. 
	// Here we use the average.
	selectWindow("Average");
	run("Select All");
	run("Copy");
	run("Select None");
	selectWindow("Intensity_Modulated");
	setSlice(3); // brightness
	run("Select All");
	run("Paste");
	run("Select None");
	
	return;

}