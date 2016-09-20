Visualization Maps
==================

# Description
This repository contains the scripts and project specific directories for 
creating visualization maps of stream sections used for sampling. Currently 
the two projects are the Westbrook in Whately, MA and Stanley Brook on 
Mt Desert Island, ME.
<br><br>


# Directory Structure
This repository relies on a common directory structure to reference different 
files from different scripts. The base directory (`baseDir` variable in the 
scripts) refers to the project-specific directory (e.g. 
`C:\gis\vizMaps\westbrookSections`). Most directories are created in the 
scripts. For example, the events directory accessed by the universal 
`linearReferencing.py` script is created by the raw data processing scripts in 
the individual project directories. The `../spatial/source.gdb` geodatabase, 
which contains the flowlines layer, should be created in the base directory 
prior to running any of the scripts.
<br><br>


# Workflow
Raw data are processed within the project-specific sub-directories. This work 
includes generating a spatial flowlines layer that is both representative of 
the study area and functions within the linear referencing functions. Stream
structure data is accessed to generate a common output format used to drive 
the linear referencing process. Raw data processing is unique to each project.  
The "Linear Referencing" and "Finalize Products" sections below are universal 
to all projects.
<br><br>


## Generate Flowlines
A clean set of flowlines is created for the study area with each stream reach 
represented by a single polyline. Four columns are required in the attributes 
table:
 - "id" - a unique stream segment identifier corresponding with entries in the 
 events tables
 - "from_meas" - Postition at the start point of the line (zero for all lines)
 - "to_meas" - Postition at the end point of the line (length of the line, in 
 meters)
 - "river" - The name of the stream that matches the column of the same name 
 in the westbrook database
 
The polyline direction is checked to correspond to stream flow direction. The 
flowlines layer is saved specifically as `../spatial/source.gdb/flowlines` in 
the base directory of the project repository. This naming scheme is necessary 
for script referencing.
<br><br>


## Create Event Tables
Stream structure information including section locations, widths, and antenna 
locations can be accessed directly from the "westbrook" database on osensei. 
Data are pre-processed into event tables for the linear referencing steps used 
to create the stream section maps. The event tables indicate the position of 
the sections relative to the stream segment on which they fall. This table is 
used in the spatial processing to get the coordinates of each section marker. 
Each section is represented by one row in the table with four columns: 
 - "id" - The unique ID of the stream segment the section falls on
 - "section" - The unique ID of the stream section
 - "line_meas" - The section's distance along the stream segment (typically 
 in meters) from the upstream node
 - "offset" - Denotes how far offset from the flowline the point should be. 
 This is used primarly when generating locations marking stream widths.

A fifth, "sample_name" column is added for measuremets that change over time, 
such as width or antenna location. The tables are in CSV format and structured 
as in Table 1. 

| id | section | line_meas   | offset       |
|:--:| :-----: | ---------   | ------       |
| 1  | 1       | 1170.578182 | -1.673833333 |
| 1	 | 2       | 1134.560392 | -1.900166667 |
| 2  | 51	     | 750.073078	 | -2.083333333 |
| 2	 | 52	     | 710.073078	 | -1.848       |
Table 1: Event table example

Each event table may have duplicates in the "id" column, but should have unique 
sections. This means that separate events tables are created for section markers 
and width markers. Width events have two tables, one for each side of the 
stream, typically denoted as postive and negative offsets. All events tables are 
saved into the `..tables/events/` directory within the project base directory 
and given a clearly identifying name. This name will be used to identify the 
final products. No other files should be saved to this directory. 
<br><br>


## Linear Referencing 
### Description
The linear referencing script uses the inputs described above to spatially 
assign section IDs to the flowlines. This may need to be an iterative process 
if the map is being compared to firsthand knowledge of the study site. 

### Execution
Open the `linearReferencing.py` script and define the `baseDir` variable as the 
path to the project directory. Execute the script in Arc Python. The script 
loops through events tables in the `../tables/events/` directory. One spatial 
points layer is created per table with one point for each row. Latitude and 
longitude coordinates are calculated for the events in the NAD83 coordinate 
system.

### Output
The script saves each of the event tables as a new feature class in the 
`../spatial/linearReferencing.gdb` geodatabase.
<br><br>


## Finalize Products
### Description
This script reads the attribute tables from the features created in the 
previous step to CSV files with only the necessary columns for use in the 
visualiztion. 

### Execution
Open the `finalizeProducts.R` script and set the `baseDir` variable as in the 
previous section. The `projectID` variable is set to a character string 
identifying the project that gets added on to the output (e.g. "stanley"). Run 
the script in the R workspace.

### Output
The output CSV contains the same information as the events table with spatial 
coordinates in the NAD83 coordinate system (Table 2).

|    id     |         section         |  latitude	  |  longitude   |	line_meas	 | sample_name | 	  offset	  |        description         | 
| :-------: |        :-------:        |  --------   |  ---------   |  ---------  | ----------- |    ------    |        -----------         | 
| 201480754	| wb obear stationary 3-1	| 42.43474151	| -72.6714166	 | 1689.080934 | 56	         | 0	          | antennae_locations_nad83   | 
| 201480754	| wb obear stationary 3-1	| 42.43474151	| -72.6714166	 | 1689.080934 | 67	         | 0	          | antennae_locations_nad83   | 
| 201480742	| section 18 antenna      | 42.43310163	| -72.66785075 | 36.35       | 41	         | 0	          | antennae_locations_nad83   | 
| 201480670 | 2	                      | 42.43360367	| -72.66806129 | 1873.074244 | 40	         | -0.651786147	| sample_40_widths_neg_nad83 | 
| 201480647	| 10	                    | 42.43571043	| -72.67199792 | 2084.321035 | 40	         | -1.271722624	| sample_40_widths_neg_nad83 | 
Table 2: Sample final product table 
<br><br>


# Contact Info
Kyle O'Neil  
koneil@usgs.gov