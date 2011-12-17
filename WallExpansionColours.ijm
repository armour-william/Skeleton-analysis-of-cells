//Wall expansion colours labels your cell walls with a colour scale to 
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
//expansion in an area of wall. If you want to make your own LUT you need to have 
//index[0]=0,0,0 and index[255]=255,255,255. In this way you reserve black and white
//for the background and wall outline, respectively.

//Will Armour
//Ph.D. Candidate

//Plant Cell Biology Lab
//School of Biological Sciences | University of Sydney
//Sydney NSW 2006 | Australia

macro "Wall Expansion Colours" {
	
	//Dialog that asks for user input
	Dialog.create("Line Expansion Colours");
	Dialog.addMessage("This macro will label your image with lines of different\n"+
	"colours in order to visually see where expansion is greatest.\n"+
	"You will need to open the file with coordinates as such:\n"+
	"x1, y1, x2, y2, expansion rate (tab-delimited)\n"+"\n"+
	"Once this is selected then please open your image\n");
	Dialog.addNumber("Max expansion (% increase): ", 100);
	Dialog.addNumber("Radius of circle (pixels): ", 15);
	Dialog.addMessage("Above masks out the wall junctions and is needed to\n"+
	"allow segmentation of walls";
	//Dialog.addNumber("Min expansion (% increase): ", 0);
	Dialog.addMessage("Alternatively you can choose for the max expansion \n"+
	"to be automatically determined by selecting below\n");
	Dialog.addCheckbox("Auto scale colour based on your dataset", false);
	Dialog.addCheckbox("Black outline on white background", true);
	Dialog.addCheckbox("Draw a straight line for failed walls", false);
	Dialog.addNumber("Number of pixels/micron for x and y coords: ", 8.806);//this value is for the 288dpi images
	Dialog.addMessage("(set above value as 1 if coordinates are actual pixel values)");
	Dialog.show();

	maxExpansion=Dialog.getNumber();//gets the max expansion rate
	radius=Dialog.getNumber();//gets the radius to use for the dots
	halfRadius=radius/2;//this value is used to expand the line about its main axis
	//minExpansion=Dialog.getNumber();//gets the min expansion rate
	autoScale=Dialog.getCheckbox();//gets whether user wants the data to be scaled based on data set
	BlackOutlineOnWhiteBground=Dialog.getCheckbox();//gets whether outline is black on white
	failWallDraw=Dialog.getCheckbox();//gets whether user wants a straight line drawn if all other attempts fail
	scaleMultiplier=Dialog.getNumber();//gets the scale the image is set at

	//Open the array file which must be a csv list with the x1, y1, x2, y2 
	//and expansion rate in columns separated by tab
	string = File.openAsString("");
	stringAllCoords=File.openAsString("");

	//setup conditions
	run("Profile Plot Options...", "width=450 height=200 minimum=0 maximum=0 draw");
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
			valueMax=value[4];
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
	separateWalls(scaleMultiplier);
	labelWalls(scaleMultiplier);
	//setBatchMode(false);
	imagePresentationWhiteVertices();

	function prepareImage() {
		run("8-bit");//converts file to 8bit if it isn't already
		//Inverts the image to get white outline on black
		if (BlackOutlineOnWhiteBground==1) run("Invert");
		//copies the image to a new slice for backup
		run("Select All");
		run("Copy");
		run("Add Slice");//should be slice 2
		run("Paste");
		setSlice(1);
	}
	function separateWalls(scaleMultiplier) {
		lines = split(stringAllCoords, "\n");
		nindents = lengthOf(lines);
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
			//sets the x2 and y2 coords as the x2 and y2 coordinate, respectively.
			xCoord2=value[2];
			xCoord2=(xCoord2)*(scaleMultiplier);
			//xCoord2=round(xCoord2);
			yCoord2=value[3];
			yCoord2=(yCoord2)*(scaleMultiplier);
			//yCoord2=round(yCoord2);

			//offset the x and y coords by the radius in order to get the fillOval
			//position correct
			diameter=2*radius;
			offset=radius;
			xCoord1=xCoord1-offset;
			yCoord1=yCoord1-offset;
			xCoord2=xCoord2-offset;
			yCoord2=yCoord2-offset;

			//draws a circle at the x and y Coordinates so that each wall can be
			//made a different colour
			setColor(0);//circles will be black like the background
			fillOval(xCoord1,yCoord1,diameter,diameter);
			fillOval(xCoord2,yCoord2,diameter,diameter);
	}
	function labelWalls(scaleMultiplier) {
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
			//sets the x2 and y2 coords as the x2 and y2 coordinate, respectively.
			xCoord2=value[2];
			xCoord2=(xCoord2)*(scaleMultiplier);
			//xCoord2=round(xCoord2);
			yCoord2=value[3];
			yCoord2=(yCoord2)*(scaleMultiplier);
			//yCoord2=round(yCoord2);
			//sets the expansion rate
			expansionRate=value[4];
			if (expansionRate<1) expansionRate=1;//error check for negative values
			expansionColour=round(m*expansionRate+1);//this is y=mx+b to change the scale to 1-254

			setResult("x1",rowNo,xCoord1);
			setResult("y1",rowNo,yCoord1);
			setResult("x2",rowNo,xCoord2);
			setResult("y2",rowNo,yCoord2);
			setResult("Expansion Rate",rowNo,expansionRate);
			setResult("Expansion Colour",rowNo,expansionColour);
			rowNo++;
			
			//This first round of looking at the profile needs to get beyond the blacked out circle
			makeLine(xCoord1,yCoord1,xCoord2,yCoord2);
			roiManager("Add");
			profile=getProfile();//these are returned as an array
			maxPixelIntensity=0;
			for (i=0;i<profile.length;i++) {
				pixelIntensity=profile[i];
				if (pixelIntensity>maxPixelIntensity) maxPixelIntensity=pixelIntensity;
			}
			if (maxPixelIntensity>0) {
				//print("First labelling method");
				//pixelIntensity=0;//initialised as black
				//A polyline selection is required in order to get the x and y coords of the line 
				//selection at 1 pixel intervals
				xCoordArray=newArray(2);
				yCoordArray=newArray(2);
				xCoordArray[0]=xCoord1;
				yCoordArray[0]=yCoord1;
				xCoordArray[1]=xCoord2;
				yCoordArray[1]=yCoord2;
				makeSelection("polyline",xCoordArray,yCoordArray);
				run("Fit Spline", "straighten");
				getSelectionCoordinates(xPixel,yPixel);
				i=0;
				for (i=0;i<xPixel.length;i++) {
					bins=256;
					xPixelCoord=xPixel[i];
					yPixelCoord=yPixel[i];
					pixelIntensity=getPixel(xPixelCoord,yPixelCoord);
					if (pixelIntensity>250) {
						doWand(xPixelCoord,yPixelCoord);
						getStatistics(area);
						if (area<100000) {
							setColor(expansionColour);
							fill();	
						}
						
					}	
				}
			}
			if (maxPixelIntensity==0) {
				//print("Second labelling method");
				//This will catch examples where no wall is found when you use a straight polyline
				//A polyline selection is required in order to get the x and y coords of the line 
				//selection at 1 pixel intervals
				xCoordArray=newArray(2);
				yCoordArray=newArray(2);
				xCoordArray[0]=xCoord1;
				yCoordArray[0]=yCoord1;
				xCoordArray[1]=xCoord2;
				yCoordArray[1]=yCoord2;
				makeSelection("polyline",xCoordArray,yCoordArray);
				run("Line to Area");
				run("Enlarge...", "enlarge="+halfRadius);
				getSelectionCoordinates(xPixel,yPixel);
				i=0;
				fail=1;//sets up a value to see if the whole for loop fails to find a wall
				for (i=0;i<xPixel.length;i++) {
					bins=256;
					xPixelCoord=xPixel[i];
					yPixelCoord=yPixel[i];
					pixelIntensity=getPixel(xPixelCoord,yPixelCoord);
					if (pixelIntensity>250) {
						doWand(xPixelCoord,yPixelCoord);
						getStatistics(area);
						if (area<100000) {
							setColor(expansionColour);
							fill();
							fail=0;
						}
					}
				}
				if (failWallDraw==1) {
					if (fail==1) {
						run("Line Width...", "line=10");
						makeLine(xCoord1,yCoord1,xCoord2,yCoord2);
						setBackgroundColor(expansionColour,expansionColour,expansionColour);
						run("Clear", "slice");
						run("Line Width...", "line=1");
						setBackgroundColor(255,255,255);
					}
				}
			}
			
		}
	}
	function imagePresentationWhiteVertices() {
		//Apply a custom rainbow LUT to the image and convert that to RGB 
		//The transparent zero used herein does not work in batch mode
		run("0Will_Rainbow");//filename = 0Will_Rainbow.lut
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
