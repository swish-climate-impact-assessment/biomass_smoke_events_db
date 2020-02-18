## a script to extract events from the bushfire smoke event database
## ivanhanigan
library(RSQLite)
drv <- dbDriver("SQLite")
ch <- dbConnect(drv, dbname = "databases/storage.sqlite")
qc  <- dbGetQuery(ch , "select * from biomass_smoke_reference")
str(qc)
qc2  <- dbGetQuery(ch , "select * from biomass_smoke_event")

##projdir <- "Q:/Research/Environment_General/Biomass_Smoke_Validated_Events/"

##datadir <- file.path(projdir, "biomass_smoke_events_db")

##setwd(projdir)

outdir <- "static/data_extracts"
dir(outdir)
if(!file.exists(outdir)) dir.create(outdir)

towns <- c("Sydney","Illawarra","Lower Hunter","Hobart","Launceston")
## "PERTH", cannot do West Australian towns currently because of
## licence restrictions
town <- towns[2]
town
outfile <- sprintf("biomass_smoke_events_db_%s_extracted_%s.csv", tolower(town), Sys.Date())
file.path(outdir, outfile)



#### now extract the LFS data
events <- dbGetQuery(ch,
paste0("select t2.biomass_smoke_reference_id, '",town,"' as place, 'lfs' as event_type, min_date, max_date
from biomass_smoke_event t2
join biomass_smoke_reference t3
on t2.biomass_smoke_reference_id = t3.id
where place like '",town,"%' and (event_type = 'bushfire' or event_type = 'prescribed burn' or event_type = 'possible biomass')
order by min_date
"))
str(events)
events$min_date <- as.Date(events$min_date)
events$max_date <- as.Date(events$max_date)
head(events)
#disentangle::data_dict(events, "event_type")

dateranges  <- events[!is.na(events$max_date),]
dateranges[1,]
head(dateranges[,4])

events_out <- data.frame(matrix(NA, ncol = 3, nrow = 0))
names(events_out) <- c("place", "date", "lfs_event")
for(i in 1:nrow(dateranges))
  {
  #  i =1
  dates <- data.frame(seq(dateranges[i,"min_date"], dateranges[i,"max_date"], 1))
  names(dates) <- "date"
  events_out  <- rbind(events_out,
                      data.frame(place = town,
                                 date = dates,
                                 lfs_event = 1)
                      )
  }
head(events_out, 25)

single_dates  <- events[is.na(events$max_date), c("place", "min_date")]
head(single_dates)
single_dates$lfs_event  <- 1
names(single_dates)  <- c("place", "date", "lfs_event")
events_out <- rbind(single_dates, events_out)
events_out <- sqldf::sqldf("select *
from events_out
group by place, date, lfs_event
order by date", drv = "SQLite")
head(events_out, 25)


## GET THE POLLUTION DATA
dbGetQuery(ch, "select site, region from pollution_stations_combined_final")
dbGetQuery(ch, paste0("select site, region from pollution_stations_combined_final
where lower(region) like '",tolower(town),"%'")
)

extract  <- dbGetQuery(ch,
paste0("select t1.region as studysite, date, avg(pm25_av) as pm2p5, avg(pm10_av) as pm10
from
(select * from pollution_stations_combined_final where
        lower(region) like '",tolower(town),"%' or
lower(region) = '",tolower(town),"') t1
left join combined_pollutants t2
on t1.site = t2.site
group by region, date")
)

extract$date <- as.Date(extract$date)
str(extract)
extract$studysite <- NULL
names(extract) <- c("date", "pm25_lag0", "pm10_lag0")
extract$pm25_lag0 <- as.numeric(extract$pm25_lag0)

extracted <- merge(extract, events_out, all.x = T)
str(extracted)
head(extracted, 25)
extracted$place <- town

extracted$lfs_pm10_lag0 <- ifelse(extracted$pm10_lag0 >= quantile(extracted$pm10_lag0, .95, na.rm = T),
                                  ifelse(is.na(extracted$lfs_event), 0, extracted$lfs_event),
                                  0
                                  )
head(extracted, 25)
tail(extracted[,c("date", "lfs_event", "lfs_pm10_lag0")], 25)

## make indicators
extracted$lfs_pm25_lag0 <- ifelse(extracted$pm25_lag0 >= quantile(extracted$pm25_lag0, .95, na.rm = T),
                                  ifelse(is.na(extracted$lfs_event), 0, extracted$lfs_event),
                                  0
                                  )

extracted$lfs_pm2599 <- ifelse(extracted$pm25_lag0 >= quantile(extracted$pm25_lag0, .99, na.rm = T),
                                  ifelse(is.na(extracted$lfs_event), 0, extracted$lfs_event),
                                  0
                                  )

extracted$lfs99 <- ifelse(!is.na(extracted$pm25_lag0), 0, NA)
extracted$lfs99 <- ifelse(!is.na(extracted$pm10_lag0), 0, extracted$lfs99)

extracted$lfs99 <- ifelse(
  extracted$pm25_lag0 >= quantile(extracted$pm25_lag0, .99, na.rm = T)
  |
  extracted$pm10_lag0 >= quantile(extracted$pm10_lag0, .99, na.rm = T)
  ,
  ifelse(is.na(extracted$lfs_event), 0, extracted$lfs_event),
  0
  )
head(extracted)
tail(extracted, 25)
subset(extracted, lfs_pm2599 == 1)
subset(extracted, lfs99 == 1)

## add all the %iles
extracted$pm10pct_lag0[!is.na(extracted$pm10_lag0)] <- (rank(extracted$pm10_lag0[!is.na(extracted$pm10_lag0)])-1)/(length(extracted$pm10_lag0[!is.na(extracted$pm10_lag0)])-1)

extracted$pm25pct_lag0[!is.na(extracted$pm25_lag0)] <- (rank(extracted$pm25_lag0[!is.na(extracted$pm25_lag0)])-1)/(length(extracted$pm25_lag0[!is.na(extracted$pm25_lag0)])-1)


tail(extracted, 25)
str(extracted)


## visualise this
par(mfrow = c(2,1))
with(extracted, plot(date, pm10_lag0, type = "l", ylim = c(0, 250)))
points(
  extract[extracted$lfs_pm10_lag0 == 1, "date"]
                   ,
  extract[extracted$lfs_pm10_lag0 == 1, "pm10_lag0"]
                   , col = 'red', pch = 16, cex = .7
)


with(extracted, plot(date, pm25_lag0, type = "l", ylim = c(0, 250)))
points(
  extract[extracted$lfs_pm25_lag0 == 1, "date"]
                   ,
  extract[extracted$lfs_pm25_lag0 == 1, "pm25_lag0"]
                   , col = 'red', pch = 16, cex = .7
)
dev.off()


## compare to Sydney plots in williamson (2016) and horsley (2018)
town
if(town == "Sydney"){
par(mfrow = c(2,1))
xmin <- min(extracted[extracted$lfs_pm25_lag0 == 1,"date"], na.rm = T)
xmax <- as.Date("2014-12-31")
with(extracted[extracted$date >= xmin & extracted$date <= xmax,], plot(date, pm25_lag0, type = "l", ylim = c(0, 100)))
points(
  extract[extracted$lfs_pm25_lag0 == 1, "date"]
                   ,
  extract[extracted$lfs_pm25_lag0 == 1, "pm25_lag0"]
                   , col = 'red', pch = 16, cex = .7
  )
with(extract[extracted$lfs_pm25_lag0 == 1,], plot(date, pm25_lag0, type = "h", xlim = c(xmin, xmax), ylim = c(0,110)))
abline(25, 0)
dev.off()
}

## final write to CSV
final_out <- extracted
## TODO need to extract protocol used in original db query
#final_out$protocol_used <- ifelse(final_out$date >= as.Date("2007-07-01"), "Satellite Only", "Johnston2011")

str(final_out)
tail(final_out)

## TODO if the extraction is acceptable then write the result out to CSV
##write.csv(final_out, file.path(outdir, outfile), row.names = F)

## end
##dbDisconnect(ch)
