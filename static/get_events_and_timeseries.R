
library(RSQLite) 
drv <- dbDriver("SQLite")
ch <- dbConnect(drv, dbname = "~/web2py/applications/biomass_smoke_events_db/databases/storage.sqlite")
qc  <- dbGetQuery(ch , "select * from biomass_smoke_reference")
str(qc)
qc2  <- dbGetQuery(ch , "select * from biomass_smoke_event")

projdir <- "Q:/Research/Environment_General/Biomass_Smoke_Validated_Events/"
#projdir <- "~/projects_environment_general_local/Biomass_Smoke_Validated_Events/"
datadir <- file.path(projdir, "biomass_smoke_events_db")

setwd(projdir)

outdir <- file.path(projdir, "biomass_smoke_events_db/static/data_extracts")
outdir
if(!file.exists(outdir)) dir.create(outdir)
outfile <- sprintf("biomass_smoke_events_db_sydney_extracted_%s.csv", Sys.Date())
 file.path(outdir, outfile)



#### now extract the LFS data
events <- dbGetQuery(ch,
"select t2.biomass_smoke_reference_id, 'Sydney' as place, 'lfs' as event_type, min_date, max_date
from biomass_smoke_event t2
join biomass_smoke_reference t3
on t2.biomass_smoke_reference_id = t3.id
where place like 'Sydney%' and (event_type = 'bushfire' or event_type = 'prescribed burn' or event_type = 'possible biomass')
order by min_date
")
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
                      data.frame(place = "Sydney",
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
dbDisconnect(ch)
# GET THE POLLUTION DATA
# ONE IDEA IS TO SHIP IT WITH THE SQLITE DATABASE
#extract <- dbGetQuery(ch,
#"SELECT date, pm25_lag0, pm10_lag0, o3_max, temperature, humidity
#FROM biomass_smoke_pollutants_sydney_20160229 t1
#"
#)

# but I don't like this as the SQLite db will become very large
# perhaps the PostGIS server on the ANU data commons can be made a public access source, or share a common password?
# for the time being just reference the data on Q drive

extract <- read.csv("../Air_Pollution_Monitoring_Stations_NSW/AP_monitor_NSW_1994_2013_hrly/data_derived//nswaq9413.daily.sydney.csv",
                    as.is = T)
extract$date <- as.Date(extract$date)
str(extract)
names(extract) <- c("date",       "pm25_lag0",      "pm10_lag0",       "o3",         "o3_max",      "humidity",   "temperature",
"co",         "no",         "no2",        "nox",        "so2",        "pm2.5_lag",  "pm2.5_lead")

extracted <- merge(extract, events_out, all.x = T)
str(extracted)
head(extracted, 25)
extracted$place <- "Sydney"
extracted$lfs_pm10_lag0 <- ifelse(extracted$pm10_lag0 >= quantile(extracted$pm10_lag0, .95, na.rm = T),
                                  ifelse(is.na(extracted$lfs_event), 0, extracted$lfs_event),
                                  0
                                  )
head(extracted, 25)
tail(extracted[,c("date", "lfs_event", "lfs_pm10_lag0")], 25)
# NB there is an issue when selecting days above 95% but with NA LFS
# date pm10pct_lag0 lfs_pm10_lag0
# 7282 2013-12-08   0.76670318             0
# 7283 2013-12-09   0.95228642            NA
# 7284 2013-12-10   0.60460022             0


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
subset(extracted, lfs99 == 1)
#add all the %iles
extracted$pm10pct_lag0[!is.na(extracted$pm10_lag0)] <- (rank(extracted$pm10_lag0[!is.na(extracted$pm10_lag0)])-1)/(length(extracted$pm10_lag0[!is.na(extracted$pm10_lag0)])-1)

extracted$pm25pct_lag0[!is.na(extracted$pm25_lag0)] <- (rank(extracted$pm25_lag0[!is.na(extracted$pm25_lag0)])-1)/(length(extracted$pm25_lag0[!is.na(extracted$pm25_lag0)])-1)



tail(extracted, 25)
str(extracted)



with(extracted, plot(date, pm10_lag0, type = "l", ylim = c(0, 250)))
points(
  extract[extracted$lfs_pm10_lag0 == 1, "date"]
                   ,
  extract[extracted$lfs_pm10_lag0 == 1, "pm10_lag0"]
                   , col = 'red', pch = 16, cex = .7
  )

# and the final dataset that Pernilla wanted had a lot of uneccesary columns
# but include these so no chance the SAS code will break
final_out <- data.frame(
studysite                = extracted$place,
admdate                  = rep(NA, nrow(extracted)),
date                     = extracted$date,
maximum_temperatur       = rep(NA, nrow(extracted)),
minimum_temperatur       = rep(NA, nrow(extracted)),
dewpt                    = rep(NA, nrow(extracted)),
temp_lag                 = rep(NA, nrow(extracted)),
dew_lag                  = rep(NA, nrow(extracted)),
flu                      = rep(NA, nrow(extracted)),
pm10pct_lag0             = extracted$pm10pct_lag0,
pm25pct_lag0             = extracted$pm25pct_lag0,
bushfire_lag0            = rep(NA, nrow(extracted)),
dust_lag0                = rep(NA, nrow(extracted)),
nonbiomassfire_lag0      = rep(NA, nrow(extracted)),
nonbiomassnonfire_lag0   = rep(NA, nrow(extracted)),
possiblebiomass_lag0     = rep(NA, nrow(extracted)),
prescribedburn_lag0      = rep(NA, nrow(extracted)),
woodsmoke_lag0           = rep(NA, nrow(extracted)),
lfs_pm10_lag0            = extracted$lfs_pm10_lag0,
lfs_pm25_lag0            = extracted$lfs_pm25_lag0,
lfs_pm2599               = extracted$lfs_pm2599,
pubhol                   = rep(NA, nrow(extracted)),
lfs_99_NA                = rep(NA, nrow(extracted)),
lfs_99                   = extracted$lfs99,
pm25_lag0                = extracted$pm25_lag0,
pm10_lag0                = extracted$pm10_lag0,
o3_max                   = extracted$o3_max,
temperature              = rep(NA, nrow(extracted)),
humidity                 = rep(NA, nrow(extracted)),
lfs_any_type             = extracted$lfs_event,
protocol_used            = rep(NA, nrow(extracted))
)

final_out$protocol_used <- ifelse(final_out$date >= as.Date("2007-07-01"), "Satellite Only", "Johnston2011")

str(final_out)
tail(final_out)

write.csv(final_out, file.path(outdir, outfile), row.names = F)
# from my own utility library
library(disentangle)
dd <- data_dictionary(final_out)
write.csv(dd, file.path(outdir, gsub(".csv", "_data_dictionary.csv", outfile)), row.names = F)
vl <- variable_names_and_labels(datadict = dd, infile = file.path(outdir, outfile))
vl[,1:3]
write.csv(vl[,1:3], file.path(outdir, gsub(".csv", "_variable_names_and_labels.csv", outfile)), row.names = F)



#### QC against the file Farhad originally provided
namlist <- vl[vl$Type != 'missing',1]
qc1 <- final_out[,which(names(final_out) %in% namlist)]
str(qc1)
dir()
farhad <- read.csv("Biosmoke_UCRH_extended_Farhad_June_2015/data_provided/sydney_LSF_1jan94_31Dec2013_new.csv")
farhad$date <- as.Date(farhad$date)
str(farhad)
farhad <- farhad[,names(farhad) %in% namlist]

qc2 <- merge(qc1, farhad, by = 'date')
qc2 <- qc2[,order(names(qc2))]
str(qc2)
write.csv(qc2, file.path(outdir, "temp.csv"), row.names = F)
# and then look at this and delete once happy
