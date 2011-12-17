//Cell expansion colours labels your cells with a colour scale to 
//visually show spatial patterns of expansion across a region of 
//contiguous cells

//Copyright (C) 2011  Will Armour

//This program is free software; you can redistribute it and/or
//modify it under the terms of the GNU General Public License
//as published by the Free Software Foundation; either version 2
//of the License, or (at your option) any later version.

//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.

//You should have received a copy of the GNU General Public License
//along with this program; if not, write to the Free Software
//Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

//This macro works by converting a series of expansion values that apply to a set of
//x and y coordinates into a custom colour using a custom LUT so you can visualise the 
//expansion in a cells area. If you want to make your own LUT you need to have 
//index[0]=0,0,0 and index[255]=255,255,255. In this way you reserve black and white
//for the background and wall outline, respectively.

//Will Armour
//Ph.D. Candidate

//Plant Cell Biology Lab
//School of Biological Sciences | University of Sydney
//Sydney NSW 2006 | Australia

macro "Cell Expansion Colours" {
	
	//Dialog that asks for user input
	Dialog.create("Cell Expansion Colours");
	Dialog.addMessage("This macro will label the cells in your image different\n"+
	"colours in order to visually see where expansion is greatest.\n"+
	"You will need to open the file with coordinates as such:\n"+
	"x1, y1, expansion rate (tab-delimited)\n"+"\n"+
	"Once this is selected then please open your image\n");
	Dialog.addCheckbox("Make colour scale friendly for colourblind people", false);
	Dialog.addNumber("Max expansion (% increase): ", 100);
	Dialog.addMessage("Alternatively you can choose for the max expansion \n"+
	"to be automatically determined by selecting below\n");
	Dialog.addCheckbox("Auto scale colour based on your dataset", false);
	Dialog.addCheckbox("Black outline on white background", true);
	Dialog.addNumber("Number of pixels/micron for x and y coords: ", 1);
	Dialog.addMessage("(set above value as 1 if coordinates are actual pixel values)");
	Dialog.show();

	colourBlindFriendly=Dialog.getCheckbox();
	maxExpansion=Dialog.getNumber();//gets the max expansion rate
	//minExpansion=Dialog.getNumber();//gets the min expansion rate
	autoScale=Dialog.getCheckbox();//gets whether user wants the data to be scaled based on data set
	BlackOutlineOnWhiteBground=Dialog.getCheckbox();//gets whether outline is black on white
	scaleMultiplier=Dialog.getNumber();//gets the scale the image is set at

	//Open the array file which must be a csv list with the x1, y1
	//and expansion rate in columns separated by tab
	string = File.openAsString("");

	//setup conditions
	//run("Profile Plot Options...", "width=450 height=200 minimum=0 maximum=0 draw");
	if (autoScale==1) {
	//Split the CSV like file into an array of lines
	linesAutoScale = split(string, "\n");
	nindentsAutoScale = lengthOf(linesAutoScale);
	goto=-1;
	maxExpansion=0;
		for (pos=0; pos<nindentsAutoScale;pos++) {
			if (goto!=-1) pos=goto;
			//splits each line into an array of 5 numbers. As the way the file has
			//been split is not specified it will try space and tab to split it up.
			value=split(linesAutoScale[pos]);
			valueMax=value[2];
			ratio=(valueMax)/(maxExpansion);
			//ratio=division(valueMax,maxExpansion);
			if (ratio>=1) maxExpansion=valueMax;
		}
	}
	b=1;//This is to reserve 0 as black for background
	y=254;//This is to reserve 255 as white for outline
	x=maxExpansion;
	m=(y-b)/x;

	//Asks user to open the image to be used, gets the title and
	//then truncates the string so the extension is removed
	open("");
	inputImageName=getTitle;
	index=lastIndexOf(inputImageName, ".");//removes file extension
	if (index!=-1) truncImageName=substring(inputImageName, 0, index);
	rename(""+truncImageName);

	//setBatchMode(true);
	prepareImage();
	labelCells(scaleMultiplier);
	//setBatchMode(false);
	imagePresentation(colourBlindFriendly);

	function prepareImage() {
		run("8-bit");//converts file to 8bit if it isn't already
		//Inverts the image to get white outline on black
		checkIfInvertLUT=is("Inverting LUT");
		if (BlackOutlineOnWhiteBground==1 && checkIfInvertLUT==0) run("Invert");
		if (BlackOutlineOnWhiteBground==1 && checkIfInvertLUT==1) run("Invert LUT");
		if (BlackOutlineOnWhiteBground==0 && checkIfInvertLUT==1) {
			run("Invert LUT");
			run("Invert");
		}
		//Next line is not required but is the correct option that needs no modification
		//if (BlackOutlineOnWhiteBground==0 && checkIfInvertLUT==0) run("Invert LUT");
		
		//copies the image to a new slice for backup
		run("Select All");
		run("Copy");
		run("Add Slice");//should be slice 2
		run("Paste");
		setSlice(1);
	}
	function labelCells(scaleMultiplier) {
		//Split the CSV like file into an array of lines
		lines = split(string, "\n");
		nindents = lengthOf(lines);
		run("Line Width...", "line=1");//1 pixel thick line required to use getProfile
		//setup the goto value which is required for getting each line to be 
		//split up into the x and y coordinates.
		goto=-1;
		rowNo=0;
		for (pos=0; pos<nindents;pos++) {
			if (goto!=-1) pos=goto;
			//splits each line into an array of 5 numbers. As the way the file has
			//been split is not specified it will try space, tab, comma and newline
			//to split it up.
			value=split(lines[pos]);
			//sets the x1 and y1 coords as the x1 and y1 coordinate, respectively.
			xCoord1=value[0];
			xCoord1=(xCoord1)*(scaleMultiplier);
			//xCoord1=round(xCoord1);//rounds value to integer
			yCoord1=value[1];
			yCoord1=(yCoord1)*(scaleMultiplier);
			//yCoord1=round(yCoord1);
			//sets the expansion rate
			expansionRate=value[2];
			if (expansionRate<1) expansionRate=1;//error check for negative values
			expansionColour=round(m*expansionRate+1);//this is y=mx+b to change the scale to 1-254

			setResult("x1",rowNo,xCoord1);
			setResult("y1",rowNo,yCoord1);
			setResult("Expansion Rate",rowNo,expansionRate);
			setResult("Expansion Colour",rowNo,expansionColour);
			rowNo++;
			
			doWand(xCoord1,yCoord1);
			roiManager("Add");
			setColor(expansionColour);
			fill();
			}
			
		}
	}
	function imagePresentation(colourBlindFriendly) {
		//Apply a custom rainbow LUT to the image and convert that to RGB 
		//The transparent zero used herein does not work in batch mode
		if (colourBlindFriendly==1) run("0Will_GreenMagenta");
		if (colourBlindFriendly==0) run("0Will_Rainbow");//filename = 0Will_Rainbow.lut
		//run("16_colors");//different LUT if you don't have the above
		run("16-bit");
		run("RGB Color");
		setSlice(1);
		run("Select All");
		run("Copy");
		setSlice(2);
		run("Paste");
		//This means black becomes transparent so the original white wall will show up
		setPasteMode("Transparent-zero");
		//Comment out the next two lines if you want to keep the original image
		setSlice(1);
		run("Delete Slice");
		run("Select None");
	}
}
