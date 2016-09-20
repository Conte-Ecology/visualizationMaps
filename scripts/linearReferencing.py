# Description
# -----------
# Project: Visualization Maps

# This script accesses the flowlines and the event tables to 
#   map the position of the sections along the stream segments.


# Libraries
# ---------
import os
import arcpy

# Specify inputs
# --------------
# Path to base directory
baseDir = "C:/KPONEIL/visualizationMaps/stanleySections"


# Define directories
# ------------------
# Spatial directory
spatialDir = baseDir + "/spatial"

# Events directory
eventDir = baseDir + "/tables/events/"

# Create linear referencing database
linearRefDB = spatialDir + "/linearReferencing.gdb"
if not arcpy.Exists(linearRefDB): 
  arcpy.CreateFileGDB_management(spatialDir, "linearReferencing.gdb")


# Processing
# ----------
# Create routes
routes = arcpy.CreateRoutes_lr(spatialDir + "/source.gdb/flowlines",
								"ID",
								linearRefDB + "/routes",
								"TWO_FIELDS",
								"from_meas",
								"to_meas")						 				 
								 
# Loop through events tables
for eventsTable in os.listdir(eventDir):
    
	# Get the table name
	tableName = os.path.splitext(eventsTable)[0]

    # Create events 
	events = arcpy.MakeRouteEventLayer_lr(routes,
                                            "ID",
	    						            eventDir + "/" + eventsTable,
		    					            "ID POINT line_meas",
			    				            tableName,
				    			            "offset",
					    		            "#", "#", "#", "#", "#",
						    	            "POINT")
								
	# Reproject in order to calculate Lat/Lon
	locations = arcpy.Project_management(events,
										 linearRefDB + "/" + 
										   tableName + "_nad83", 
										 arcpy.SpatialReference(4269))
										   
	# Calculate lat/lon coordinates
	arcpy.AddXY_management(locations)
	arcpy.AlterField_management(locations, 'POINT_X', 'longitude')
	arcpy.AlterField_management(locations, 'POINT_Y', 'latitude')