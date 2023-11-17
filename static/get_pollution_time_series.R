## a script to extract pollution from the bushfire smoke event database
## ivanhanigan

library(RSQLite)
library(data.table)
drv <- dbDriver("SQLite")
## NB non-CAR affiliated researchers cannot use West Australian air
## pollution currently because of licence restrictions

## start with the online database (note that it does not have WA data due to licence)
ch <- dbConnect(drv, dbname = "databases_with_wa/storage.sqlite")
qc  <- dbGetQuery(ch , "select * from biomass_smoke_reference")
str(qc)
qc2  <- dbGetQuery(ch , "select * from biomass_smoke_event")
str(qc2)
unique(qc2$place)
qc3 <- dbGetQuery(ch, "select * from pollution_stations_combined_final")
str(qc3)
unique(qc3$region)
qc4 <- dbGetQuery(ch, "select * from combined_pollutants")
str(qc4)
unique(qc4$site)

## here use city-wide averages, not imputing or weighting
extract  <- dbGetQuery(ch,
"select t1.region as studysite, date, avg(pm25_av) as pm2p5, avg(pm10_av) as pm10
from
(select * from pollution_stations_combined_final) t1
left join combined_pollutants t2
on t1.site = t2.site
group by region, date"
)
setDT(extract)
length(is.na(extract$date))
extract <- extract[!is.na(date),]
idx <- extract[,is.na(pm2p5) & is.na(pm10)]
extract <- extract[!idx]
extract
extract[,.(
  begin_date = min(date, na.rm = T),
  end_date = max(date, na.rm = T)
),
by = c("studysite")][order(studysite)]

## now do WA
"
       studysite begin_date   end_date
 1:       Albany 2006-06-24 2007-12-31
 2:       Albury 2001-09-07 2009-03-11
 3:     Bathurst 2000-07-11 2009-03-11
 4:      Bunbury 1997-03-15 2007-12-31
 5:    Busselton 2006-11-01 2007-12-31
 6:    Geraldton 2005-09-22 2007-12-31
 7:       Hobart 2006-04-22 2008-06-04
 8:    Illawarra 1994-02-15 2009-03-11
 9:   Launceston 1992-05-04 2008-05-28
10: Lower Hunter 1994-02-02 2009-03-11
11:        Perth 1994-02-15 2007-12-31
12:       Sydney 1994-01-01 2015-08-21
13:     Tamworth 2000-10-13 2009-03-11
14:  Wagga Wagga 2001-09-06 2009-03-11

"
## NOTE that sydney was extended to 2020 by Joe but he did not supply the pollution data
## also Melbourne was done by Farhad
## https://cloud.car-dat.org/index.php/apps/files/?dir=/Shared/CAR_staging_area/data_sharing/from_ivan/Biomass_Smoke_Validated_Events/Biosmoke_UCRH_extended_Farhad_2017/data_provided&fileid=413496
"
studysite begin_date       end_date
Melbourne 10-November-2009 16-December-2014
"
