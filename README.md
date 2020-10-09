Biomass Smoke Events Database
=============================


This database is for creating and extending a list of validated bushfire smoke events in Australian cities.

License: CC BY 4.0, see REFERENCES section below for citations

Please contribute your validated events data back to the Extreme Weather Events collaboration.
https://github.com/swish-climate-impact-assessment/biomass_smoke_events_db

# Installation instructions

- Download web2py.  This runs on windows, linux and mac.  It requires no installation, just unzip the files to the location you want to work on the biomass smoke databse (e.g. `MyDocuments/projects/bushfires` or something)
- Clone or Download this github repo as a zip
- put the files within this repo into the `applications/biomass_smoke_events_db` folder of your web2py downloaded folder
- run the `web2py` program as per the instructions for your OS
- use a web browser to visit the local website `http://127.0.0.1:8000/biomass_smoke_events_db` (note that the port:8000 used in the example here can change depending on how you start web2py)
- you have to register so that you can enter data (this is a default setting of web2py apps)
- the references are added first, and then the events that reference validates are added
- Alternatively there are instructions on how to use R to do the download and install the Web2py database software and this app here: [https://github.com/swish-climate-impact-assessment/biomass_smoke_events_db/blob/master/static/install.R](https://github.com/swish-climate-impact-assessment/biomass_smoke_events_db/blob/master/static/install.R)


# Using R codes

- The database is designed to be used with R
- This is the best way to import new air pollution data and calculate events using the associated R package [https://github.com/swish-climate-impact-assessment/BiosmokeValidatedEvents](https://github.com/swish-climate-impact-assessment/BiosmokeValidatedEvents)

#### Simple instructions for R interface:
```r
library(RSQLite)  
drv <- dbDriver("SQLite")
con <- dbConnect(drv, dbname = "path/to/web2py/applications/biomass_smoke_events_db/databases/storage.sqlite")

# GET BUSHFIRE SMOKE EVENTS TIME SERIES
qc  <- dbGetQuery(con , "select * from biomass_smoke_reference")
str(qc)
qc2  <- dbGetQuery(con , "select * from biomass_smoke_event")

# GET POLLUTION DATA
extract_obs <- dbGetQuery(ch, "select * 
from combined_pollutants")
str(extract_obs)
table(extract_obs$site)
```

Please see the R script in folder `static/get_events_and_timeseries.R` for a worked example.

# History

This database comes originally from the work written up at:

- Johnston, F. H., Hanigan, I. C., Henderson, S. B., Morgan, G. G., Portner, T., Williamson, G. J., & Bowman, D. M. J. S. (2011). Creating an Integrated Historical Record of Extreme Particulate Air Pollution Events in Australian Cities from 1994 to 2007. Journal of the Air & Waste Management Association, 61(4), 390–398. http://doi.org/10.3155/1047-3289.61.4.390

- Ivan C. Hanigan 1,2,3,* , Geoffrey G. Morgan 1,2, Grant J. Williamson 4 , Farhad Salimi 1,2, Sarah B. Henderson 5 , Murray R. Turner 6 , David M. J. S. Bowman 4 and Fay H. Johnston 2,7 (2018). Extensible Database of Validated Biomass Smoke Events for Health Research. Fire, 1, 50; http://doi.org/10.3390/fire1030050

## Recommended Citation:
- Hanigan, I. (Creator), Morgan, G. (Creator), Williamson, G. (Creator), Salimi, F. (Creator), Henderson, S. (Creator), Turner, M. (Creator), Bowman, D. M. J. S. (Creator), Johnston, F. H. (Creator) (5 Aug 2015). The Biomass Smoke Validated Events Database. ANU. 10.4225/64/59276c30b3a01 Data retrieved from Centre for Air pollution, energy and health Research. https://github.com/swish-climate-impact-assessment/biomass_smoke_events_db
