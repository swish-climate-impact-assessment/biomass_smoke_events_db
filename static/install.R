
#### name:install ####
# download web2py
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
   
    return (OsLinux)
  }
if(linux_os()){
download.file("http://web2py.com/examples/static/web2py_src.zip", 
              destfile = "~/web2py_src.zip", mode = "wb")
unzip("~/web2py_src.zip")
} else {
download.file("http://web2py.com/examples/static/web2py_win.zip", 
              destfile = "~/web2py_win.zip", mode = "wb")
unzip("~/web2py_win.zip")
}

setwd("~/web2py/applications/")
downloader::download("https://github.com/swish-climate-impact-assessment/biomass_smoke_events_db/archive/master.zip", 
         "temp.zip", mode = "wb")
unzip("temp.zip")
file.rename("biomass_smoke_events_db-master", "biomass_smoke_events_db")
setwd("~/web2py/")
#dir()

if(linux_os()){
  system("python web2py.py -a xpassword -i 0.0.0.0 -p 8181", wait = F)
} else {
  system("web2py.exe -a xpassword -i 0.0.0.0 -p 8181", wait = F)
}
browseURL("http://127.0.0.1:8181/biomass_smoke_events_db")
