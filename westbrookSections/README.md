Westbrook
=========
The scripts and workflows specific to creating the visualization map of the 
Westbrook sections. The scripts produce the event tables used in the universal 
linear referencing process described in the parent repository. 

Current datasets:
 - Section locations
 - Section widths
 - Antenna locations
<br><br>


# Workflow

## Flowline Editing
The flowlines are created in accordance with the guidelines outlined in the 
parent directory. The stream reach IDs match the featureids in the NHDHRDV2 
delineation. Flowlines are manually edited to reflect firsthand knowledge of 
the stream and known section lengths. Specifically, the confluence of Jimmy 
Brook with the mainstem of the West Brook is incorrect in the source NHD 
flowlines. Flowlines are saved according to the directory structure outlined 
in the parent directory.

In addition to the standard fields in the flowline layer, two additional 
columns are added that coincide with the Westbrook database tables:
 - "conlfuence_river_meter" - The river meter of the downstream confluence of 
 each stream segment. This matches the same field in the "data_sites" table in 
 the "westbrook" database, with the correct values filled in for the West Brook 
 segments (downstream segment gets a value of 0).
 - "estimated_bank_offset" - This is an estimated value of bank width of the 
 mainstem at the mouth of each tributary. Based on the maximum wet width at the 
 nearest mainstem section to the confluence, this column is only populated for 
 rows representing tributaries. Mainstem rows get a value of 0.
<br><br>


## Section Midpoints Mapping
### Description
The raw `data_sites` table in the "westbrook" database and the flowlines layer 
are used to generate the event table associated with the midpoint of each 
section relative to the stream segments. 

### Execution 
Open the `createSectionMidpoints.R` script and edit the variables in the "Specify 
inputs" section. The `baseDir` variable is the filepath to the project directory. 
The `user` and `password` variables are your credentials for the "westbrook" 
database on osensei. 

### Output
The event table is used as input for the linear referencing process (outlined 
in the parent repository) to create the section locations. Table 1 shows a 
sample output for the event table for section midpoints.

|    id     | section |  line_meas  | offset |
| :-------: | :-----: |  ---------  | ------ |
| 201480670	| 1	      | 1899.724244 | 	0    |
| 201480670	| 2	      | 1877.674244 | 	0    |
| 201480670	| 3	      | 1856.524244 | 	0    |
| 201480754 | 1	      | 1686.330934 | 	0    |
| 201480754	| 2	      | 1666.030934 | 	0    |
Table 1: Example of the section midpoint event table
<br><br>


## Section Widths Mapping
### Description
Stream width changes over time based on discharge. Event tables representing the 
section boundaries are generated for each sample in order to visualize the 
temporal variation in stream width. Section widths are recorded during each 
sample, beginning with sample 40.

A basic linear model is generated for each section to predict missing section 
widths based on discharge. A comparison of the two existing flow records shows 
the "discharge" column in the `data_daily_discharge` table to be slightly 
better predictor of section width. Sampling data for all sections in sample 42 
and the tributaries in sample 44 are omitted from the database. Width 
predictions are not made for these sections.

There is uncertainty in the record about which dates during the sample the wet 
widths are taken on. In light of this knowledge, the discharge on the median 
date of the sample is used to predict the widths. If it is desireable in the 
future to switch to exact dates, it should also be noted that the 
`data_tagged_captures` table contains different dates for identical sections. 

Two width event tables, one positive and one negative offset, are created for 
each sample. The script uses the `data_sites`, `data_habitat`, 
`data_seasonal_sampling`, and `data_daily_discharge` tables in the "westbrook" 
database along with the flowlines layer to generate the tables.

### Execution 
Open the `createSectionWidths.R` script and edit the variables in the "Specify 
inputs" section. The `baseDir` variable is the filepath to the project directory. 
The `user` and `password` variables are your credentials for the "westbrook" 
database on osensei.

### Output
The event table is used as input for the linear referencing process (outlined 
in the parent repository) to create the section locations. Table 2 shows a 
sample output for one of the width event tables.

|     id    | section |  line_meas  | sample_name | offset |
| :-------: | :-----: |  ---------  | ----------- | ------ |
| 201480662	| 36      | 1311.174433 | 	40	      | 3.4    |
| 201480742	| 1       | 397.95      | 	40	      | 3.725  |
| 201480742	| 2       | 376.15      | 	40        | 3.725  |
| 201480742	| 3       | 354.3	      |   40        | 4.65   |
| 201480742	| 4       | 333.75      | 	40        | 4.6    |
Table 2: Sample widths event table
<br><br>


## Antennae Mapping
### Description
Antennae locations are mapped to the flowlines based on existing deployment 
information. Antennae have been added, moved, and removed over the history of 
the sample, so locations are mapped to the flowlines based on their location 
at the time of each sample. 

The script uses the `antenna_deployment`, `data_seasonal_sampling`, and 
`data_sites` tables in the "westbrook" database along with the flowlines layer 
to generate a single output table for all of the antenna locations. If the 
antenna deployment information is updated in the future to include new drainages, 
the script may need to be updated as well. 

### Execution 
Open the `createAntennaLocations.R` script and edit the variables in the "Specify 
inputs" section. The `baseDir` variable is the filepath to the project directory. 
The `user` and `password` variables are your credentials for the "westbrook" 
database on osensei.

### Output
The event table is used as input for the linear referencing process (outlined 
in the parent repository) to create the section locations. Table 3 shows an 
example of the output table structure.

|    id     |           section	         |  line_meas	 | sample_name | offset |
| :-------: |           :-----:          |  ---------  | ----------- | ------ |
| 201480647	| wb jimmy stationary 2-1    | 2288.521035 | 46	         | 0      |
| 201480647	| wb jimmy stationary 2-1    | 2288.521035 | 47          | 0      |
| 201480647	| wb jimmy stationary 2-1    | 2288.521035 | 48          | 0      |
| 201480647 | wb jimmy section 2 antenna | 2259.221035 | 79          | 0      |
| 201480647 |	wb jimmy section 2 antenna | 2259.221035 | 80          | 0      |
Table 3: Sample antennae event table 
<br><br>


# Contact Info
Kyle O'Neil  
koneil@usgs.gov  