//////
//Choose the folders for import and output
/////
setOption("ExpandableArrays", true);
title = "Choose The Directory for Import Images";
  msg = "Please choose the directory contains your image";
  waitForUser(title, msg);
OriginDir = getDirectory("Import Images");
FileArray = getFileList(OriginDir);
title = "Choose The Directory for Save";
  msg = "Please choose the directory to save your Results";
  waitForUser(title, msg);
SaveDir = getDirectory("Directory for Results");
length = lengthOf(FileArray);
//////
//Basic Setting
/////
Dialog.create("Setting");
title = "Enter Basic Information";
width = 512; height = 512;
    Dialog.addNumber("Nucleus Size Under (pixes^2)", 120);
    Dialog.addCheckbox("Manually?", false);
    Dialog.show();
		NucleusSize = Dialog.getNumber(); //Nucleus size threshold for particle analysis
		Man = Dialog.getCheckbox();
print("\\Clear"); //Clear the text window
print("Name,", "Area of substance,", "Cell Number,", "Mean Gray Level of substance,", "Reference Mean Gray Level,", "Ratio,", "Threshold for Substance,", "Threshold for Cell Counting,"); //Create the header
//////
//Open the images one by one
//////
if (Man==false) {
	setBatchMode(true);
    setBatchMode("show");
}
for (j = 0; j < length; j++) {
	open(OriginDir+"/"+FileArray[j]);
	run("Clear Results");
	roiManager("reset");
	OriginDir=getDirectory("image");
	name = getInfo("image.filename");
	id=getImageID();
	run("Subtract Background...", "rolling=50 light sliding");//substract the background
	run("Colour Deconvolution", "vectors=[H&E 2]");
	selectWindow("Colour Deconvolution");
	close();
	selectWindow(name+"-(Colour_2)");
	if (Man==false) {
		run("Threshold...");
		setAutoThreshold("MinError no-reset");
		getThreshold(c,b);
		resetThreshold();
		setAutoThreshold("Default no-reset");
		getThreshold(c,a);
		resetThreshold();
		setThreshold(a, b);
	} else {
		run("Threshold...");
		title = "Threshold Setting";
  		msg = "Please set up the threshold value for substance";
  		waitForUser(title, msg);
  		selectWindow(name+"-(Colour_2)");
  		getThreshold(a, b);
	}
	run("Create Selection");
	roiManager("add");
	roiManager("deselect");
	run("Set Measurements...", "area mean modal min nan redirect=None decimal=6");
	run("Invert");//invert the LUT
	roiManager("select", 0);
	run("Measure");
	Area=getResult("Area", 0);
	Mean=getResult("Mean", 0);
	resetThreshold();
	roiManager("reset");
	run("Clear Results");
    selectWindow(name+"-(Colour_1)");
	if (Man==false) {
		setAutoThreshold("Default no-reset");
		getThreshold(c, d);
	} else {
		run("Threshold...");
		title = "Threshold Setting";
  		msg = "Please set up the threshold value for cells";
  		waitForUser(title, msg);
  		selectWindow(name+"-(Colour_1)");
  		getThreshold(c, d);
	}
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Analyze Particles...", "size=0-"+NucleusSize+" add");
	CellNumber=roiManager("count");
	roiManager("deselect");
	roiManager("reset");
	run("Analyze Particles...", "size="+NucleusSize+"-Infinity add");
	selectWindow(name+"-(Colour_2)");
	nRoi=roiManager("count");
	A=0;
	R=0;
	run("Set Measurements...", "area mean modal min integrated nan redirect=None decimal=6");
	for (i = 0; i < nRoi; i++) {
		roiManager("select", i);
		run("Measure");
		temp1=getResult("Area", 0);
		temp2=getResult("RawIntDen", 0);
		A=A+temp1;
		R=R+temp2;
		run("Clear Results");
	}
	MeanC=R/A;
	Ratio=Mean/MeanC;
	roiManager("reset");
	run("Clear Results");
	print(name,",",Area,",",CellNumber,",",Mean,",",MeanC,",",Ratio,",",a+"~"+b,",",c+"~"+d);
	selectImage(id);
	if (Man==false) {
		setBatchMode("show");
	}
	close();
	selectWindow(name+"-(Colour_3)");
	if (Man==false) {
		setBatchMode("show");
	}
	selectWindow(name+"-(Colour_2)");
	if (Man==false) {
		setBatchMode("show");
	}
	close();
	selectWindow(name+"-(Colour_1)");
	if (Man==false) {
		setBatchMode("show");
	}
	close();
}
selectWindow("Log");
saveAs("Text", SaveDir + "Results.csv");
print("\\Clear"); //Clear the text window
exit();