## a script to extract events from the bushfire smoke event database
## ivanhanigan
library(reshape2)
library(RSQLite)
drv <- dbDriver("SQLite")
ch <- dbConnect(drv, dbname = "databases/storage.sqlite")
qc  <- dbGetQuery(ch , "select * from biomass_smoke_reference")
str(qc)
qc2  <- dbGetQuery(ch , "select * from biomass_smoke_event")
str(qc2)
qc3 <- dbGetQuery(ch, "select * from pollution_stations_combined_final")
str(qc3)
qc4 <- dbGetQuery(ch, "select * from combined_pollutants")
str(qc4)

outdir <- "data_extracts"
if(!file.exists(outdir)) dir.create(outdir)
dir(outdir)

dbGetQuery(ch , "select place, place_other, count(*) as N from biomass_smoke_event group by place, place_other")

dbGetQuery(ch , "select region, nam from pollution_stations_combined_final group by region, nam order by nam, region")
"
         region               nam
1        Albury   NEW SOUTH WALES
2      Armidale   NEW SOUTH WALES
3      Bathurst   NEW SOUTH WALES
4     Illawarra   NEW SOUTH WALES
5  Lower Hunter   NEW SOUTH WALES
6        Sydney   NEW SOUTH WALES
7      Tamworth   NEW SOUTH WALES
8   Wagga Wagga   NEW SOUTH WALES
9        Hobart          TASMANIA
10   Launceston          TASMANIA
11       Albany WESTERN AUSTRALIA
12      Bunbury WESTERN AUSTRALIA
13    Busselton WESTERN AUSTRALIA
14    Geraldton WESTERN AUSTRALIA
15        Perth WESTERN AUSTRALIA
"
table(qc2$place)

towns <- c("Sydney","Illawarra","Lower Hunter","Hobart","Launceston", "Perth", "Bunbury", "Busselton", "Geraldton", "Gosford", "Wyong")
## NB non-CAR affiliated researchers cannot use West Australian air
## pollution currently because of licence restrictions


for(town in towns[c(1:3,10:11)]){
## town <- towns[10]
town
outfile <- sprintf("biomass_smoke_events_db_%s_extracted_%s.csv", gsub(" ", "_", tolower(town)), Sys.Date())
file.path(outdir, outfile)



#### now extract the LFS data
    ## relabel town names if needed
    town_in <- ifelse(town == "Lower Hunter", "Newcastle", town)
#### qc the query when checking Joe's updates
# qc <- dbGetQuery(ch,
# paste0("select t2.biomass_smoke_reference_id, '",town,"' as place, 'lfs' as event_type, min_date, max_date, protocol_used
# from biomass_smoke_event t2
# join biomass_smoke_reference t3
# on t2.biomass_smoke_reference_id = t3.id
# where place like '",town_in,"%' and (event_type = 'bushfire' or event_type = 'prescribed burn' or event_type = 'possible biomass') and t2.biomass_smoke_reference_id = 801
# order by min_date
# "))    

#### do the query    
events <- dbGetQuery(ch,
paste0("select t2.biomass_smoke_reference_id, '",town,"' as place, 'lfs' as event_type, min_date, max_date, protocol_used
from biomass_smoke_event t2
join biomass_smoke_reference t3
on t2.biomass_smoke_reference_id = t3.id
where place like '",town_in,"%' and (event_type = 'bushfire' or event_type = 'prescribed burn' or event_type = 'possible biomass')
order by min_date
"))

    str(events)

    events$min_date <- as.Date(events$min_date)
    events$max_date

    events$max_date <- as.Date(events$max_date)
events <- events[order(events$min_date),]
    
    head(events)
    tail(events)

    ## sanity check: maxdate should be greater than mindate, if not just
    ## remove it
    events$max_date2 <- ifelse(events$max_date < events$min_date, NA, as.character(events$max_date))

    events$max_date <- as.Date(events$max_date2)
    events$max_date2 <- NULL
    str(events)
dateranges  <- events[!is.na(events$max_date),]
dateranges[1:4,]
head(dateranges[,4])

## loop over event range and create intervening events days
events_out <- data.frame(matrix(NA, ncol = 4, nrow = 0))
names(events_out) <- c("place", "date", "protocol_used", "lfs_event")
if(nrow(dateranges) != 0){
for(i in 1:nrow(dateranges))
  {
  ##  i =1
  dates <- data.frame(seq(dateranges[i,"min_date"], dateranges[i,"max_date"], 1))
  names(dates) <- "date"
  events_out  <- rbind(events_out,
                      data.frame(place = town,
                                 date = dates,
                                 protocol_used = dateranges[i,"protocol_used"],
                                 lfs_event = 1)
                      )
}
} else {
  
}
head(events_out, 25)

single_dates  <- events[is.na(events$max_date), c("place", "min_date", "protocol_used")]
head(single_dates)
single_dates$lfs_event  <- 1
names(single_dates)  <- c("place", "date", "protocol_used", "lfs_event")
events_out <- rbind(single_dates, events_out)

## order by date, and assess how many refs support each date
events_out <- sqldf::sqldf("select place, date, lfs_event, protocol_used, count(*) as refs_used
from events_out
group by place, date, lfs_event, protocol_used
order by date", drv = "SQLite")
head(events_out, 25)
tail(events_out, 25)

##args(dcast)
qc <- dcast(events_out, place + date + lfs_event ~ protocol_used, value.var = "refs_used")
head(qc)
tail(qc)
## are any dates covered by more than one protocol?
qc2 <- sqldf::sqldf("select place, date, count(*) as n_protocols_used
from events_out
group by place, date, lfs_event
order by date", drv = "SQLite")
head(qc2[rev(order(qc2$n_protocols_used)),])
"
     place       date n_protocols_used
522 Sydney 2009-02-07                2
521 Sydney 2009-02-06                2
515 Sydney 2009-01-15                2
512 Sydney 2009-01-06                2
"
    str(qc)
names(events)
events[events$min_date > as.Date("2009-01-01") & events$protocol_used == "Johnston2011",]
    qc[qc$date >= as.Date("2009-01-03") & qc$date <= as.Date("2009-01-21"),]
events[events$min_date > as.Date("2008-11-01") & events$protocol_used == "Johnston2011",]
## OK this looks correct, Tahlia must have inserted these 2009 events
## prior to focussing on events before 2007-06-30

pused <- names(qc)[4:length(names(qc))]
tail(qc, 32)
qc$protocols_used <- ''
    for(p in 1:length(pused)){
        ##        p = 1
        for(nr in 1:nrow(qc)){
        qc$protocols_used[nr] <-
            ifelse(!is.na(qc[nr,3+p]), paste(qc$protocols_used[nr], pused[p], collapse = "", sep = ", "), qc$protocols_used[nr])
        }
    }
    str(qc)
    qc[612,]
    qc[qc$date == "2009-01-06",]
    qc$protocols_used <- gsub("^, ", "", qc$protocols_used)
        head(qc,25)
    tail(qc, 32)
    qcout <- data.frame(table(qc$date))
    head(qcout[rev(order(qcout$Freq)),])
## good
events_out <- qc[,c("place", "date", "lfs_event", "protocols_used")]
    str(events_out)
    ##events_out

#### GET THE POLLUTION DATA / NOT FOR UPDATE 2020 ####
# dbGetQuery(ch, "select * from pollution_stations_combined_final")
# dbGetQuery(ch, paste0("select site, region from pollution_stations_combined_final
# where lower(region) like '",tolower(town),"%'")
# )
# 
# ## example of Black Christmas in Sydney 2001
# town_toget <- 'Sydney'
# extract_eg <-  dbGetQuery(ch,
# paste0("select t1.site, region, lat, lon, date, pm25_av, pm10_av
# from
# (select * from pollution_stations_combined_final where
#         lower(region) like '",tolower(town_toget),"%' or
# lower(region) = '",tolower(town_toget),"') t1
# left join combined_pollutants t2
# on t1.site = t2.site
# where date == '2001-12-25'")
# )
# extract_eg
# 
# ## here use city-wide averages, not imputing or weighting
# extract  <- dbGetQuery(ch,
# paste0("select t1.region as studysite, date, avg(pm25_av) as pm2p5, avg(pm10_av) as pm10
# from
# (select * from pollution_stations_combined_final where
#         lower(region) like '",tolower(town),"%' or
# lower(region) = '",tolower(town),"') t1
# left join combined_pollutants t2
# on t1.site = t2.site
# group by region, date")
# )
# tail(extract)
# extract$date <- as.Date(extract$date)
# str(extract)
# extract$studysite <- NULL
# names(extract) <- c("date", "pm25_lag0", "pm10_lag0")
# extract$pm25_lag0 <- as.numeric(extract$pm25_lag0)
# extract$pm10_lag0 <- as.numeric(extract$pm10_lag0)
# 
# extracted <- merge(extract, events_out, all.x = T)
# str(extracted)
# head(extracted, 25)
# extracted$place <- town
# summary(extracted$pm10_lag0)
# extracted$lfs_pm10_lag0 <- ifelse(extracted$pm10_lag0 >= quantile(extracted$pm10_lag0, .95, na.rm = T),
#                                   ifelse(is.na(extracted$lfs_event), 0, extracted$lfs_event),
#                                   0
#                                   )
# head(extracted, 25)
# tail(extracted[,c("date", "lfs_event", "lfs_pm10_lag0")], 25)
# 
# ## make indicators
# extracted$lfs_pm25_lag0 <- ifelse(extracted$pm25_lag0 >= quantile(extracted$pm25_lag0, .95, na.rm = T),
#                                   ifelse(is.na(extracted$lfs_event), 0, extracted$lfs_event),
#                                   0
#                                   )
# 
# extracted$lfs_pm2599 <- ifelse(extracted$pm25_lag0 >= quantile(extracted$pm25_lag0, .99, na.rm = T),
#                                   ifelse(is.na(extracted$lfs_event), 0, extracted$lfs_event),
#                                   0
#                                   )
# 
# extracted$lfs99 <- ifelse(!is.na(extracted$pm25_lag0), 0, NA)
# extracted$lfs99 <- ifelse(!is.na(extracted$pm10_lag0), 0, extracted$lfs99)
# 
# extracted$lfs99 <- ifelse(
#   extracted$pm25_lag0 >= quantile(extracted$pm25_lag0, .99, na.rm = T)
#   |
#   extracted$pm10_lag0 >= quantile(extracted$pm10_lag0, .99, na.rm = T)
#   ,
#   ifelse(is.na(extracted$lfs_event), 0, extracted$lfs_event),
#   0
#   )
# head(extracted)
# tail(extracted, 25)
# subset(extracted, lfs_pm2599 == 1)
# subset(extracted, lfs99 == 1)
# 
# ## add all the %iles
# extracted$pm10pct_lag0[!is.na(extracted$pm10_lag0)] <- (rank(extracted$pm10_lag0[!is.na(extracted$pm10_lag0)])-1)/(length(extracted$pm10_lag0[!is.na(extracted$pm10_lag0)])-1)
# 
# extracted$pm25pct_lag0[!is.na(extracted$pm25_lag0)] <- (rank(extracted$pm25_lag0[!is.na(extracted$pm25_lag0)])-1)/(length(extracted$pm25_lag0[!is.na(extracted$pm25_lag0)])-1)
# 
# 
# tail(extracted, 25)
# str(extracted)
# 
# str(extracted)
# tail(extracted, 25)
# ## visualise this
# dir()
# #dir.create("figures_and_tables")
# #png(sprintf("figures_and_tables/%s_bushfires.png", town), width = 1000, height = 700, res = 80)
# #par(mfrow = c(2,1))
# with(extracted, plot(date, pm10_lag0, type = "l", ylim = c(0, 250), xlim = c(min(extracted$date),as.Date("2019-12-31"))))
# qc JOe's work
    with(events_out, plot(date, rep(0, nrow(events_out)), type = "l", ylim = c(0, 150), xlim = c(min(events_out$date),as.Date("2019-12-31"))))
tail(events_out)
with(events_out, segments(date, lfs_event, date, lfs_event*100, col = 'grey', lty = 2))
outfile
dir()
summary(events_out)
write.csv(events_out, file.path("data_extracts", outfile), row.names = F)
}


##############################################################
# start back up with the old work
points(
  extract[extracted$lfs_pm10_lag0 == 1, "date"]
                   ,
  extract[extracted$lfs_pm10_lag0 == 1, "pm10_lag0"]
                   , col = 'red', pch = 16, cex = .7
)
title(paste(town, "validated bushfire smoke events (red)"))

with(extracted, plot(date, pm25_lag0, type = "l", ylim = c(0, 250)))
points(
  extract[extracted$lfs_pm25_lag0 == 1, "date"]
                   ,
  extract[extracted$lfs_pm25_lag0 == 1, "pm25_lag0"]
                   , col = 'red', pch = 16, cex = .7
)
dev.off()
#}

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
##dev.off()
}

## final write to CSV
final_out <- extracted
## TODO need to extract protocol used in original db query
#final_out$protocol_used <- ifelse(final_out$date >= as.Date("2007-07-01"), "Satellite Only", "Johnston2011")

str(final_out)

## TODO if the extraction is acceptable then write the result out to CSV
write.csv(final_out, file.path(outdir, outfile), row.names = F, na = '')
}
## end
##dbDisconnect(ch)
