Stanley Brook
=============
The scripts and workflows specific to creating the visualization map of the 
Stanley Brook sample site. The scripts produce the event tables used in the 
universal linear referencing process described in the parent repository.
<br><br>


# Workflow
## Flowline Editing
The Stanley Brook sections map is based on the NHD high resolution flowlines 
and the guidelines provided by Matt O'Donnell, who has firsthand knowledge of 
the study area. Some alterations to the source data and guidelines are 
necessary for mapping purposes. High resolution flowlines are edited so that 
one flowline exists per stream reach in the sample. Each stream segment 
receives a new unique ID. 

Section lengths in the mainstem and west branch were edited to fit known 
stream layout in reference to the base map. This step involved shortening the 
reach lengths evenly to force the points to fall within known road boundaries 
along the reaches. The "section_length" column in the flowlines layer reflects 
the new section lengths for each reach. 
<br><br>


## Section Midpoints Mapping
### Description
The raw `data_habitat` table in the "westbrook" database and the flowlines 
layer are used to generate the event table associated with the midpoint of each 
section midpoints relative to the stream segments. The "section_length" column 
is used in the calculation of relative position.

### Execution 
Open the `createSectionMidpoints.R` script and edit the variables in the "Specify 
inputs" section. The `baseDir` variable is the filepath to the project directory. 
The `user` and `password` variables are your credentials for the "westbrook" 
database on osensei. 

### Output
The event table is used as input for the linear referencing process (outlined 
in the parent repository) to create the section locations. Table 1 shows a 
sample output for the event table of section midpoints.

| id | section |  line_meas  | offset |
|:--:| :-----: |  ---------  | ------ |
| 1  | 1	     | 1899.724244 | 	0     |
| 1	 | 2	     | 1877.674244 | 	0     |
| 1	 | 3	     | 1856.524244 | 	0     |
| 2  | 1	     | 1686.330934 | 	0     |
| 2  | 2	     | 1666.030934 | 	0     |
Table 1: Sample section midpoints event table
<br><br>


## Section Widths Mapping
### Description
Stream width changes over time based on discharge. Event tables representing 
the section boundaries are generated for each sample in order to visualize 
the temporal variation in stream width. Section widths are recorded during 
each sample (1-15).

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

| id | section |  line_meas  | sample_name |  offset | 
|:--:| :-----: |  ---------  | ----------- |  ------ | 
| 2	 | 34	     | 750.0730775 | 1           | -1.7125 |
| 2	 | 35	     | 710.0730775 | 1           | -1.5075 |
| 2  | 36	     | 670.0730775 | 1           | -1.0725 |
| 1	 | 1	     | 1170.578181 | 1           | -1.8675 |
| 1  | 2	     | 1134.560391 | 1           | -1.6625 |
Table 2: Sample section width event table
<br><br>


# Contact Info
Kyle O'Neil  
koneil@usgs.gov  