//@ String (label = "Colorization method",choices={"Intensity modulated", "Equal brightness"}, style="radioButtonHorizontal") Color_Method
//@ String (label = "Color scheme",choices={"Fire", "RainbowRGB"}, style="radioButtonHorizontal") Color_LUT
//@ Integer (label="Minimum display value", value=0) minDisplay
//@ Integer (label="Maximum display value", value=20) maxDisplay
//@ File(label = "Output folder:", style = "directory") outputDir

// ImageJ/Fiji macro to calculate a ratio image from a multichannel image with interactive background selection
// Outputs: a colorized RGB image with calibration bar
// 
// Theresa Swayne, Columbia University, 2022-2023

// TO USE: Open a ratio image calculated by the biosensor macro. Run the script.
// If intensity modulation is selected, the user will be prompted for the original data file

// TODO maybe: Stack compatibility (without max proj)
// TODO maybe: Batch compatibility
// TODO: Help text/readme for initial choices
// TODO maybe: User selects calib bar options

// ---- Get image information ----
id = getImageID();
title = getTitle();
dotIndex = indexOf(title, ".");
basename = substring(title, 0, dotIndex);
getDimensions(width, height, channels, slices, frames);
selectWindow(title);

// Make projection if needed and rename the input ratio image to Ratio
if (slices > 1) {
	run("Z Project...", "projection=[Max Intensity]");
	selectWindow("MAX_"+title);
	rename("Ratio");
	selectWindow(title);
	close();
}
else {
	selectWindow(title);
	rename("Ratio");
}

// Create colorized image following the user's choice of method

if (Color_Method == "Intensity modulated") {
	// create the HSB stack
	intensity_mod("Ratio");
	
	// set display contrast and LUT
	selectWindow("Intensity_Modulated");
	selectSlice(3); // should be value
	setMinAndMax(minDisplay, maxDisplay);
	if (Color_LUT == "Fire") {
	run("Fire"); 
	}
	else if (Color_Lut == "Rainbow RGB") {
		run("Rainbow RGB");
	}
	else {
		showMessage("I don't know what LUT to use");
	}
	
	// create a color calibration bar 
	// (change the parameters to suit your preference)
	run("Calibration Bar...", "location=[Upper Right] fill=Black label=White number=5 decimal=2 font=12 zoom=1 overlay");
	// save the bar overlay in the ROI Mgr
	run("To ROI Manager");

	// generate the RGB version without bar	
	selectWindow("Intensity_Modulated");
	run("Duplicate...", "title=Color duplicate");
	selectWindow("Color");
	run("RGB Color");
	
	// generate the RGB verson with bar
	selectWindow("Color")
	run("Duplicate...", "title=Color with bar");
	selectWindow("Color with bar");
	run("From ROI Manager"); 
	run("Flatten");

	// save images
	selectWindow("Intensity_Modulated");
	saveAs("Tiff", outputDir  + File.separator + basename + "_IntensityModulated_HSB.tif");

	selectWindow("Color");
	run("Hide Overlay");
	saveAs("Tiff", outputDir  + File.separator + basename + "_IntensityModulated_RGB.tif");
	
	selectWindow("Color with bar");
	saveAs("Tiff", outputDir  + File.separator + basename + "_IntensityModulated_RGB_with_bar.tif");
	
}
else if (Color_Method == "Equal brightess") {
	selectWindow("Ratio");
	setMinAndMax(minDisplay, maxDisplay);
	if (Color_LUT == "Fire") {
	run("Fire"); 
	}
	else if (Color_Lut == "Rainbow RGB") {
		run("Rainbow RGB");
	}
	else {
		showMessage("I don't know what LUT to use");
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
	selectWindow("Color")
	run("Duplicate...", "title=Color with bar");
	selectWindow("Color with bar");
	run("From ROI Manager"); 
	run("Flatten");

	// save images
	selectWindow("Color");
	saveAs("Tiff", outputDir  + File.separator + basename + "_Color_RGB.tif");
	
	selectWindow("Color with bar");
	saveAs("Tiff", outputDir  + File.separator + basename + "_Color_with_bar.tif");

}
else {
	showMessage("I don't know what color method to use");
}

// ---- Clean up and display all of the windows ----
//selectWindow("copy_ratio"); 
//close();
//selectWindow(IMName);
//run("Hide Overlay");
//roiManager("reset");
//run("Tile");

// close("*"); // image windows

// ---- Helper functions ---


function intensity_mod(ratioImage) {
	// generate an intensity modulated ratio image based on the sum of the two raw image channels

	// solicit a raw data image and relevant channels, return the sum of the fluorescent channels
	
	// get the raw data image
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
	Dialog.create("Which channels to use for intensity modulation?"); // you can use the same or different channels
	Dialog.addNumber("First channel", 1);
	Dialog.addNumber("Second channel", 2);
	Dialog.show();
	firstCh = Dialog.getNumber();
	secondCh = Dialog.getNumber();
	
	// calculate the average intensity
	run("Split Channels");
	firstChImage = "C"+firstCh+"_Raw";
	secondChImage = "C"+secondCh+"_Raw";
	imageCalculator("Add create 32-bit", firstChImage,secondChImage);
	selectWindow("Result of "+firstChImage);
	run("Divide", 2);
	rename("Average.tif");

	// ---- Make an intensity modulated image ----
	
	// create a new single-channel RGB image to hold the data
	IMName = "Intensity_Modulated";
	newImage(IMName, "RGB black", rawwidth, rawheight, 1, 1, 1);
	
	// convert the RGB image to the HSB colorspace
	selectWindow(IMName);
	run("HSB Stack");
	
	// hue will be the ratio value
	selectWindow("Ratio");
	run("Duplicate...", "title=copy_ratio");
	selectWindow("copy_ratio");
	run("Conversions...", "scale"); // make sure values are scaled properly when we convert
	run("Select All");
	run("Copy");
	selectWindow(IMName);
	setSlice(1); // hue
	run("Select All");
	run("Paste");
	
	// saturation should be all white (max value)
	selectWindow(IMName);
	setSlice(2); // saturation
	setForegroundColor(255, 255, 255); // white
	run("Select All");
	run("Fill", "slice");
	run("Select None");
	
	// a popular choice for the value is the sum (or average) of the two channels. 
	// Here we use the average.
	selectWindow("Average.tif");
	run("Select All");
	run("Copy");
	run("Select None");
	selectWindow(IMName);
	setSlice(3); // value
	run("Select All");
	run("Paste");
	run("Select None");
	
	return;

}