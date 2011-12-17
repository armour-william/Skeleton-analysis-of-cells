//Major Skeleton Analysis will create organised information from skeleton
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
//the folders for skeleton analysis as well as all ROI measurements.
//Note that in order for this macro to work properly you need to open 
//up the ROI manager separately first and select "Edit Mode" in the 
//bottom right corner.

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

macro "Major Skeleton Analysis" {
	
	//Dialog that asks for user input
	Dialog.create("Major Skeleton analysis");
	Dialog.addMessage("This macro will go through skeleton images and extract"+
	"information from them.\n"+
	"You need to place images of the same cell on different days in separate folders\n"+
	"when asked for the input folder please select the root folder where all\n"+
	"your seprate folders with these images are stored\n"+"\n");
	Dialog.addNumber("Slice Number where your skeleton is (1 if not an image stack): ", 1);
	Dialog.addNumber("Number of pixels/micron for your scaled image: ", 4);
	Dialog.show();

	imageSliceNo=Dialog.getNumber();//gets the image slice used for the skeleton
	imageScaleMultiplier=Dialog.getNumber();//gets the image scale that is used to multiply from raw pixel coords
	
	//Make sure that the folder you select for this only has folders present
	dir=getDirectory("Please choose the folder where your samples are grouped into folders");

	//sets up measurements so everything I want will be analysed
	run("Set Measurements...", "area centroid center perimeter shape feret's redirect=None decimal=3");

	setBatchMode(true);
	GetFiles(dir);
	setBatchMode(false);
	GetFilesRedo(dir);

	//This gets the list of files for the batch skeleton analysis
	function GetFiles(dir) {
		dirList=getFileList(dir);
		for (l=0;l<dirList.length;l++) {
			if (endsWith(dirList[l],"/")) {
				FolderPath=dir+dirList[l];
				print(""+FolderPath);
				inputFolder = FolderPath;
				SetUpFolders(inputFolder);
				batchSkeletonAnalysis(inputFolder);
			} 
		}
	}
	function SetUpFolders(inputFolder) {
		//creates four sub-folders within the choosen input folder
		//create folder TaggedSkel
		outputFolder0 = inputFolder+"TaggedSkel"+File.separator;
		File.makeDirectory(outputFolder0);
			if (!File.exists(outputFolder0))
				exit("Unable to create directory");
		//create folder DataSortingWall
		outputFolder1 = inputFolder+"DataSortingWall"+File.separator;
		File.makeDirectory(outputFolder1);
			if (!File.exists(outputFolder1))
				exit("Unable to create directory");
		//create folder DataSortingCell
		outputFolder2 = inputFolder+"DataSortingCell"+File.separator;
		File.makeDirectory(outputFolder2);
			if (!File.exists(outputFolder2))
				exit("Unable to create directory");
		//create folder ROIall
		outputFolder3 = inputFolder+"ROIall"+File.separator;
		File.makeDirectory(outputFolder3);
			if (!File.exists(outputFolder3))
				exit("Unable to create directory");
	}
	
	function batchSkeletonAnalysis(inputFolder) {
		list = getFileList(inputFolder);
		for (i=0; i<list.length; i++) {
			path = inputFolder+list[i];
			showProgress(i, list.length);
			if (endsWith(path, ".tif")) {
				print(""+path);
				open(path,imageSliceNo);
				name1=getTitle;
				index=lastIndexOf(name1, ".");//removes file extension
				if (index!=-1) name1 = substring(name1, 0, index);
				if (nImages>=1) {
					//use raw uncalibrated images and it will set the scale for you
					//scale it uses is for 288d.p.i. images, 2D(area) and 1D(lines)
					//measurements should both be calculated correctly
					//if you want bypass this just comment out the line below
					run("Set Scale...", "distance=4000 known=454.23 pixel=1 unit=um");
					
					//get and set up names for the results of the skeleton analysis
					name=getTitle;
					nameOrig=getTitle;
					index=lastIndexOf(name, ".");//removes file extension
					if (index!=-1) name = substring(name, 0, index);
					nameTagSkel=name+"TagSkel.tif";
					nameSummary=name+"Summary.xls";
					nameBranchInfo=name+"BranchInfo.xls";
					outputFolder0a=inputFolder+"TaggedSkel"+File.separator;
					outputFolder1a=inputFolder+"DataSortingWall"+File.separator;
					
					
					//get image ready for skeleton analysis
					run("8-bit");
					run("Make Binary");
					
					//get the cell area info for the cell
					getDimensions(w,h,c,s,f);
					xCoordWand=w/2;
					yCoordWand=h/2;
					doWand(xCoordWand,yCoordWand);
					roiManager("Add");
					
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
				}
			} else {
				
				print("Not an image suitable for Skeleton Analysis, another loop begins");
				i++;
				roiManager("Deselect");
			}
		}
		outputFolder2a=inputFolder+"DataSortingCell"+File.separator;
		//saves the cumulative roi selection as a ROI set as well as a spreadsheet
		roiManager("Save",outputFolder2a+"ROIset.zip");
		roiManager("Measure");
		selectWindow("Results");
		nameROI=name1+"CellArea.xls";
		saveAs("Measurements", ""+outputFolder2a+nameROI);
		run("Close");
		close();//next 3 lines closes the original pictures opened
		close();
		close();
		roiManager("Delete");//Deletes all items on the list
	}

	//This gets the files for the batch ROI analysis	
	function GetFilesRedo(dir) {
		dirList1=getFileList(dir);
		for (m=0;m<dirList1.length;m++) {
			if (endsWith(dirList1[m],"/")) {
				FolderPath1=dir+dirList1[m];
				print(""+FolderPath1);
				inputFolder=FolderPath1;
				batchROI(inputFolder);
			} 
		}
	}
	function batchROI(inputFolder) {
		//Searches for files to be used for importing into results table and if it matches then opens
		//up the original images so all the ROIs can be saved on their surface as a destructive overlay
		
		list1 = getFileList(inputFolder);
		for (j=0; j<list1.length; j++) {
			path1=inputFolder+list1[j];
			showProgress(j, list1.length);
			if (endsWith(list1[j], "Input.tif")) {
				print("Input image: "+path1);//prints the files path to the log
				open(path1,imageSliceNo);
				
				//Get image name for use in saving stuff
				rootName = getTitle;//gets title of image
				OrigTifName = getTitle;
				index=lastIndexOf(rootName, ".");//removes file extension
				if (index!=-1) rootName = substring(rootName, 0, index);
				print("Truncated input image name: "+rootName);
				
				if(nImages>=1) {
					//Get the name of xls file that corresponds with the image
					outputFolder1a=inputFolder+"DataSortingWall"+File.separator;
					VerticesFileFolder = outputFolder1a;
					VerticesFile = ""+VerticesFileFolder+rootName+"BranchInfo.xls";
					print("Vertices file path: "+VerticesFile);//prints the files path to log
					
					//Imports data into results table adds pairs of coordinates to ROI
					//manager before finally saving both the ROIs and a flattened
					//image with the ROIs all showing
					
					run("Results... ","open=["+VerticesFile+"]");
					//run("Results... ",VerticesFile);//this is wrong
					x=1;//value for counting number of lines added to ROI manager
					for(k=0; k<nResults; k++) {
						//get the x1,y1,x2,y2 coordinates from the results table
						//these coordinates are in microns and adjusted to your scale
						x1 = getResult("V1 x", k);
						x1 = x1*imageScaleMultiplier; //gets values close to original pixel coordinates
						x1 = round(x1);//rounds the value to the nearest integer
						x2 = getResult("V2 x", k);
						x2 = x2*imageScaleMultiplier;
						x2 = round(x2);
						y1 = getResult("V1 y", k);
						y1 = y1*imageScaleMultiplier;
						y1 = round(y1);
						y2 = getResult("V2 y", k);
						y2 = y2*imageScaleMultiplier;
						y2 = round(y2);
						
						//create two new matrix arrays for storing the x and y coords
						LineOrdinate1 = newArray(2);
						LineOrdinate2 = newArray(2);
						LineOrdinate1[0] = x1;
						LineOrdinate1[1] = x2;
						LineOrdinate2[0] = y1;
						LineOrdinate2[1] = y2;
						
						//make a line selection between the x1y1 and x2y2
						makeSelection("polyline", LineOrdinate1, LineOrdinate2);
						roiManager("Add");
						print("There is now "+x+" line(s) added to the ROI manager");
						x=x+1;
					}
				}
				//print("End of nImages loop");//uncomment if you want to see the process
				outputFolder3a=inputFolder+"ROIall"+File.separator;
				//save the ROIs as a ROI.zip
				ROIsetFileName = rootName+"ROIset.zip";
				roiManager("Save", outputFolder3a+ROIsetFileName);
				
				//print("ROI zip saved");
				
				//it should automatically select the correct window as it was last used
				//the command to show all labels in the roi manager seems to not work
				// therefore to solve this just click edit mode prior to running
				//this macro in FIJI/ImageJ
				roiManager("Show All");
				roiManager("Show None");
				roiManager("Show All with labels");//does not appear to work
				roiManager("Show All");
				
				run("Flatten");
				//print("ROI flattened");
				ROIallImageName = rootName+"ROIall.tif";
				saveAs("tiff", ""+outputFolder3a+ROIallImageName);
				selectWindow(""+ROIallImageName);
				//print("ROI tif saved");
				close();//closes the ROIall.tif
				selectWindow(""+OrigTifName);
				close();//closes Input.tif
				roiManager("Delete");//Deletes all items on the list
				//roiManager("reset");//resets the ROI manager after reading results table
				selectWindow("Results");
				run("Close");
				//run("Clear Results");//clears the results table after using it
				//print("Everything closed");
			} else {
				print("Not an image, another loop begins");
				j++;
			}
			print("This image (if there was one) has had its ROIs entered, another sample will follow");
		}
		print("Analysis is now complete for this folder");
	}
print("All analyses are now complete");
}
