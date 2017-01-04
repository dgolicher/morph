#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(rgdal)
library(plotly)
library(ggplot2)
library(dismo)
load("/home/rstudio/morph/data/test.rob")
dist<-subset(dist,dist$dist_m<15000)
#f<-function(x)x-max(x)
#tides$ht<-unlist(tapply(tides$ht,tides$name,f))

### 

FMakeTime<-function(year=2016,month=1,day=1,hr=1){
  tm<-sprintf("%04d-%02d-%02d %02d:00:00",year,month,day,hr)
  tm<-as.POSIXct(tm)
  tm
}

FArriveBirds<-function(tm,nbirds= 100,sites=grat)
  {
  wt<-rnorm(nbirds,mean=1.5,sd=0.2) ##Change this later
  rid<-sample(sites$rid,nbirds)
  birds<-data.frame(arrive_time=tm,weight=wt,rid=rid)
  birds
}



birds<-FArriveBirds("01-Jan-2016",20)
birds<-rbind(birds,FArriveBirds("02-Jan-2016",20))

#birds_site<-merge(birds,grat@data,by.x="site",by.y="rid")
#dist_site<-merge(dist,grat@data)

FValueSites<-function(sites=current_grat)
{
  ## Make a rule for calculating value of site 
  # for feeding
  sites$value<-sites$psuitable/100*sites$mean_biomass
  sites
}


### Find the best site to move to from any other site
## Works through grouped ranking of sites within distance
FBestMove<-function(sites=current_grat){
  ## Merges are instantaneous as they use lazy evaluation
  dist_sites<-merge(sites@data,dist)
  f<-function(x)rank(-x,ties.method= "random")
  dist_sites$rank<-unlist(tapply(dist_sites$value,dist_sites$rid2,f))
  d<-subset(dist_sites,dist_sites$rank==1)
  d<-data.frame(rid=d$rid,rid2=d$rid2,dist_m=d$dist_m)
  d
}

#### Function to calculate the proportion of patch that is at a suitable
# depth

FSuitable<-function(sites=current_grat,ftm=tm,ftides=tides,depth=-1,height=1){
  current_tide<-subset(ftides,ftides$time==ftm)
  d<-merge(grat@data,current_tide)
  tide<-d$ht
  depth<-depth+tide
  height<-height+tide
  dd<-cbind(d$min,d$q10,d$q25,d$median,d$q75,d$q90,d$max,depth,height)
  f<-function(x)
  {
    q<-c(0,10,25,50,75,90,100)
    qs<-x[1:7]
    depth<-x[8]
    height<-x[9]
    x2<-q[qs>=depth&qs<=height]
    # The supress warnings are needed as the vector may be of zero
    # length. This also leads to results of -inf instead of zero
    suppressWarnings(x2<-max(x2,na.rm=TRUE)-min(x2,na.rm=TRUE))
    if(is.na(x2))x2<-0
    if(x2==-Inf)x2<-0
    x2
  }
  sites@data$psuitable<-apply(dd,1,f)
  sites
}


## Model

#1. Change grat to reflect state of tide

day<-01
month<-01
year<-2016
hr<-01
tm<-FMakeTime(year,month,day,hr)

current_grat<-FSuitable(ftm=tm,sites = grat)
current_grat<-FValueSites(sites=current_grat)
system.time(moves<-FBestMove())
str(moves)

map<-gmap(grat,type="satellite")
# Define server logic required to draw a histogram
shinyServer(function(input, output) {
   
output$distPlot <- renderPlot({
    
    day<-input$Day
    month<-input$Month
    year<-2016
    hr<-input$Hour
    tm<-FMakeTime(year,month,day,hr)
    
    depth<-input$Depth
    height<-input$Height
   

    current_grat<-FSuitable(ftm=tm,sites=grat,depth=depth,height=height)
    plot(map)
    eelgrass<-((current_grat@data$psuitable/100)*current_grat@data$median_biomass)/200
    points(coordinates(current_grat),cex=eelgrass,pch=23,bg="red")
    
  })
output$tides = renderTable({
  day<-input$Day
  month<-input$Month
  year<-2016
  hr<-input$Hour
  
  subset(tides,tides$time==tm)
})
  
})
