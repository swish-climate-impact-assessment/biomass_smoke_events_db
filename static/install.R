
#### name:install ####
"
if on linux_os I assume you will use this from user_home (~/)
else assume windows and I assume you will use web2py from C:/Temp
"
download_web2py <- FALSE
# function to decide which download of web2py, linux or win
linux_os <- function(){
  if(length(grep('linux',sessionInfo()[[1]]$os)) == 1)
  {
    #print('Linux')
    os <- 'linux'
    OsLinux <- TRUE
  }else if (length(grep('ming',sessionInfo()[[1]]$os)) == 1)
  {
    #print('Windows')
    os <- 'windows'
    OsLinux <- FALSE
  }else
  {
    # don't know, do more tests
    print('Non linux or windows os detected. Assume linux-alike.')
    os <- 'linux?'
    OsLinux <- TRUE
  }
}
if(linux_os()){
if(!file.exists("~/web2py_src.zip")) download_web2py <- TRUE
  if(download_web2py){
  # I assume you will use this from ~/
  download.file("http://web2py.com/examples/static/web2py_src.zip",
                destfile = "~/web2py_src.zip", mode = "wb")
  unzip("~/web2py_src.zip")
  }
  setwd("~/web2py/applications/")
} else {
if(!file.exists("C:/Temp/web2py_win.zip")) download_web2py <- TRUE
  if(download_web2py){
  # I assume you will use web2py from the top of C
  dir.create("C:/Temp",showWarnings = F)
  download.file("http://web2py.com/examples/static/web2py_win.zip",
                destfile = "C:/Temp/web2py_win.zip", mode = "wb")
  setwd("C:/Temp/")
  unzip("web2py_win.zip")
  }
  setwd("C:/Temp/web2py/applications/")
}
if(file.exists("biomass_smoke_events_db")){
   file.rename("biomass_smoke_events_db",
               sprintf("biomass_smoke_events_db_%s",make.names(Sys.time()))
               )    
}

if(!require(downloader)) install.packages("downloader");
downloader::download("https://github.com/swish-climate-impact-assessment/biomass_smoke_events_db/archive/master.zip",
                     "temp.zip", mode = "wb")
unzip("temp.zip")
file.rename("biomass_smoke_events_db-master", "biomass_smoke_events_db")
#dir()

if(linux_os()){
  setwd("~/web2py")
  sink("w2p.py")
cat("python web2py.py -a xpassword -i 0.0.0.0 -p 8181\n")
cat("firefox http://127.0.0.1:8181/biomass_smoke_events_db")  
  sink()
  print(cat('you have a go script in ~/web2py/w2p.py\n
bash it to run it\n'))
# or just try to do it from R
  system("python web2py.py -a xpassword -i 0.0.0.0 -p 8181", wait = F)
  browseURL("http://127.0.0.1:8181/biomass_smoke_events_db")

} else {
  setwd("C:/Temp/")
  sink("w2p.cmd")
cat("cd C:/Temp/web2py\n")
cat("start web2py.exe -a xpassword -i 0.0.0.0 -p 8181\n")
cat("cmd /c start http://127.0.0.1:8181/biomass_smoke_events_db")  
  sink()
  print(cat('you have a batch file now: C:/Temp/w2p.cmd\n
Double click to run it\n'))
# or just try to do it from R
shell("w2p.cmd")
}
