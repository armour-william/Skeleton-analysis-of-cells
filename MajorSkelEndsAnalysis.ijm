//Major Skeleton Ends Analysis will create organised information from skeleton
//images of individual cells

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

//This macro recursively goes through a set of folders to analyse all
//the folders for the number of skeleton ends in each cell. Input images should 
//be of the original cell outline. 

//An example list of files with their folder set up is below; 
//when you run the analysis select the RootFolder
//RootFolder/Cell_1/day1.tif
//RootFolder/Cell_1/day2.tif
//RootFolder/Cell_2/day1.tif
//RootFolder/Cell_2/day2.tif

//Will Armour
//Ph.D. Candidate

//Plant Cell Biology Lab
//School of Biological Sciences | University of Sydney
//Sydney NSW 2006 | Australia

macro "Major Skeleton Ends analysis" {
	//Dialog that asks for user input
	Dialog.create("Major Skeleton Ends Analysis");
	Dialog.addMessage("This macro will go through skeleton tiff images of cell outlines and extract\n"+
	"information about the number of skeleton ends within cells.\n"+
	"You need to place images of the same cell on different days in separate folders\n"+
	"when asked for the input folder please select the root folder where all\n"+
	"your seprate folders with these images are stored\n"+"\n");
	Dialog.addNumber("Slice Number where your skeleton is (1 if not an image stack): ", 1);
	Dialog.addNumber("Number of pixels/micron for your scaled image: ", 4);
	Dialog.addCheckbox("Black outline on white background", true);
	Dialog.addMessage("If you want to change see the effect of changing resolution of your image\n"+
	"on the number of skeleton ends enter a number below. Otherwise leave as is.");
	Dialog.addNumber("Resolution multiplier:",1);
	Dialog.show();
	
	imageSliceNo=Dialog.getNumber();//gets the image slice used for the skeleton
	imageScaleMultiplier=Dialog.getNumber();//gets the image scale that is used to multiply from raw pixel coords
	BlackOutlineOnWhiteBground=Dialog.getCheckbox();//gets whether outline is black on white
	ResMultiply=Dialog.getNumber();//gets the resolution multiplier
	
	//Make sure that the folder you select for this only has folders present
	dir=getDirectory("Please choose the folder where your samples are grouped into subfolders");

	//sets up measurements so everything I want will be analysed
	run("Set Measurements...", "area centroid center perimeter shape feret's redirect=None decimal=3");

	//Makes sure that the selection colors are right for the analysis
	if (BlackOutlineOnWhiteBground==1) {
		setForegroundColor(0,0,0);
		setBackgroundColor(255,255,255);	
	} else {
		setForegroundColor(255,255,255);
		setBackgroundColor(0,0,0);
	}
	//setBatchMode(true);
	
	GetFiles(dir);
	//setBatchMode(false);

	//This gets the list of files for the batch skeleton analysis
	function GetFiles(dir) {
		dirList=getFileList(dir);
		for (l=0;l<dirList.length;l++) {
			//Open folders if using Linux, MacOSX or other *nix based systems
			if (endsWith(dirList[l],"/")) {
				FolderPath=dir+dirList[l];
				print(""+FolderPath);
				inputFolder = FolderPath;
				SetUpFolders(inputFolder);
				batchResize(inputFolder);
			}
			//Open folders if using a Microsoft Windows system
			if (endsWith(dirList[l],"\\")) {
				FolderPath=dir+dirList[l];
				print(""+FolderPath);
				inputFolder = FolderPath;
				SetUpFolders(inputFolder);
				batchResize(inputFolder);
			}
		}
	}
	function SetUpFolders(inputFolder) {
		//creates four sub-folders within the choosen input folder
		//create folder TaggedSkel
		outputFolder0 = inputFolder+"TaggedSkelRes"+ResMultiply+File.separator;
		File.makeDirectory(outputFolder0);
			if (!File.exists(outputFolder0))
				exit("Unable to create directory");
		//create folder DataSortingWall
		outputFolder1 = inputFolder+"DataSortingWallRes"+ResMultiply+File.separator;
		File.makeDirectory(outputFolder1);
			if (!File.exists(outputFolder1))
				exit("Unable to create directory");
		//create folder SkelEnds
		outputFolder4 = inputFolder+"SkelEndsRes"+ResMultiply+File.separator;
		File.makeDirectory(outputFolder4);
			if (!File.exists(outputFolder4))
				exit("Unable to create directory");
	}
	function batchResize(inputFolder) {
		list = getFileList(inputFolder);
		for (i=0; i<list.length; i++) {
			path = inputFolder+list[i];
			showProgress(i, list.length);
			if (endsWith(path, ".tif")) {
				print(""+path);
				open(path,imageSliceNo);//opens the layer of tiff as set by user
				name1=getTitle;
				index=lastIndexOf(name1, ".");//removes file extension
				if (index!=-1) name1 = substring(name1, 0, index);
				if (nImages>=1) {
					run("Set Scale...", "distance=imageScaleMultiplier known=1 pixel=1 unit=um");

					//get and set up names for the results of the skeleton analysis
					name=getTitle;
					nameOrig=getTitle;
					index=lastIndexOf(name, ".");//removes file extension
					if (index!=-1) name = substring(name, 0, index);
					nameTagSkel=name+"TagSkel.tif";
					nameSummary=name+"Summary.xls";
					nameBranchInfo=name+"BranchInfo.xls";
					nameSkelEnds=name+"SkelEnds.tif";
					outputFolder0a=inputFolder+"TaggedSkelRes"+ResMultiply+File.separator;
					outputFolder1a=inputFolder+"DataSortingWallRes"+ResMultiply+File.separator;
					outputFolder4a=inputFolder+"SkelEndsRes"+ResMultiply+File.separator;

					//get image ready for resize
					run("8-bit");
					run("Make Binary");
					
					//get the image size info and set the dimensions for the new image
					getDimensions(w,h,c,s,f);
					xwidth=w*ResMultiply;
					yheight=h*ResMultiply;
					run("Size...", "width=xwidth height=yheight constrain average interpolation=Bilinear");
			
					//Smooth the image into a nice outline and then skeltonize
					run("Gaussian Blur...", "sigma=2");
					run("Make Binary");
					run("Skeletonize (2D/3D)");
			
					//get the updated image size info and select cell
					getDimensions(w,h,c,s,f);
					xwidth=w/2;
					yheight=h/2;					
					doWand(xwidth,yheight);
					run("Make Inverse");
					run("Clear", "slice");
					run("Invert");
					run("Select None");
					run("Invert");
					
					//select the cell mask for later use
					run("Select All");
					run("Copy");
					run("Select None");
			
					//skeletonize the cell mask
					run("Skeletonize (2D/3D)");

					//Do skeleton analysis and save the results
					run("Analyze Skeleton (2D/3D)", "prune=none show");
					selectWindow("Tagged skeleton");
					saveAs("tiff", ""+outputFolder0a+nameTagSkel);
					close();
					selectWindow("Branch information");
					saveAs("Measurements", ""+outputFolder1a+nameBranchInfo);
					run("Close");
					selectWindow("Results");
					saveAs("Measurements", ""+outputFolder1a+nameSummary);
					run("Close");
			
					//create a new slice and paste the cell mask 
					selectWindow(""+nameOrig);
					run("Add Slice");
					run("Paste");
					run("Invert", "slice");

					//The next two if statements makes the skeleton outline thicker
					//so that it will look nice on a printer; they can be commented out
					run("Previous Slice [<]");
					if (ResMultiply<=1) {
						run("Dilate", "slice");	
					}
					if (ResMultiply>1) {
						run("Dilate", "slice");
						run("Dilate", "slice");
					}
					run("Z Project...", "start=1 stop=2 projection=[Max Intensity]");
					selectWindow("MAX_"+nameOrig);
					saveAs("tiff", ""+outputFolder4a+nameSkelEnds);

					//Closes the two image windows that remain open
					selectWindow(""+nameOrig);
					close();
					selectWindow(""+nameSkelEnds);
					close();
				}
			} else {
				print("Not an image suitable for Skeleton Ends Analysis, another loop begins");
				i++;
			}
		}
	}
	print("All analyses are now complete");
}
