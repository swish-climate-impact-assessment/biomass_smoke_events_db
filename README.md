Biomass Smoke Events Database
=============================

This database is for creating and extending a list of validated bushfire smoke events in Australian cities.

License: CC BY 4.0

Please contribute your validated events data back to the Extreme Weather Events collaboration.
https://github.com/swish-climate-impact-assessment/biomass_smoke_events

# Installation instructions

- Download web2py.  This runs on windows, linux and mac.  It requires no installation
- Clone or Download this github repo as a zip
- put the files within this repo into the `applications/biomass_smoke_events` folder of your web2py download 
- run the `web2py` program as per the instructions for your OS
- use a web browser to visit the local website `http://127.0.0.1:8000/biomass_smoke_events`
- you have to register so that you can enter data 
- the references are added first, and then the events that reference validates are added

# Using R codes

- The database can be used with R
- This is the best way to import new air pollution data and calculate events using the associated R package [https://github.com/swish-climate-impact-assessment/BiosmokeValidatedEvents](https://github.com/swish-climate-impact-assessment/BiosmokeValidatedEvents)

#### Simple instructions for R interface:
```r
library(RSQLite)  
drv <- dbDriver("SQLite")
con <- dbConnect(drv, dbname = "path/to/web2py/applications/biomass_smoke_events/databases/storage.sqlite")
qc  <- dbGetQuery(con , "select * from biomass_smoke_reference")
str(qc)
qc2  <- dbGetQuery(con , "select * from biomass_smoke_event")
# etc
```

# History

It comes originally from the Biomass Smoke and Health Project of:

- David Bowman
- Fay Johnston
- Geoff Morgan
- Ivan Hanigan 
- Grant Williamson




