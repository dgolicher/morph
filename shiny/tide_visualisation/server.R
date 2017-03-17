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
library(leaflet)
load("test.rob")

dist<-subset(dist,dist$dist_m<15000)
grat<-spTransform(grat,CRS("+init=epsg:4326"))

FMakeTime<-function(year=2016,month=1,day=1,hr=1){
  tm<-sprintf("%04d-%02d-%02d %02d:00:00",year,month,day,hr)
  tm<-as.POSIXct(tm,tz = "Aleutian")
  tm
}

day<-1
month<-1
year<-2016
hr<-12
tm<-FMakeTime(year,month,day,hr)
tm

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


shinyServer(function(input, output) {
  
  Ftm <- reactive({
    day<-input$Day
    month<-input$Month
    year<-2016
    hr<-input$Hour
    tm<-FMakeTime(year,month,day,hr)
    tm})
  
  Fdata <- reactive({
    day<-input$Day
    month<-input$Month
    year<-2016
    hr<-input$Hour
    tm<-FMakeTime(year,month,day,hr)
    depth<-input$Depth
    height<-input$Height
    
    current_grat<-FSuitable(ftm=tm,sites=grat,depth=depth,height=height)
    current_grat
    
  })  
   
output$mymap <- renderLeaflet({
 
  
  mymap<-leaflet() %>%
    setView(lat = 55.32035, lng = -162.8156, zoom = 10) %>%
    addProviderTiles("Esri.WorldImagery", group = "Satellite") %>%
    addTiles(group="OSM") %>%
    #addPolygons(data=Fdata()) %>%
    addScaleBar() %>%
    addLayersControl(
      baseGroups = c("OSM","Satellite"),
      overlayGroups = c("Suitability","daylight"),
      options = layersControlOptions(collapsed = TRUE))
   
  mymap
  })


observe({
 
  dd<-Fdata()
  pal <- colorNumeric(
    palette = "Reds",
    domain = dd$psuitable)
  
  leafletProxy("mymap",data=dd) %>%
  clearShapes() %>%
  addPolygons(group="Suitability",data=dd,stroke = FALSE, smoothFactor = 0.2, fillOpacity = 0.5,
    color = ~pal(psuitable)) %>%
    addTerminator(
      resolution=10,
      time = Ftm()--10*60*60,
      group = "daylight")
   })

observe(
  {
    dd<-Fdata()
    pal <- colorNumeric(
      palette = "Reds",
      domain = dd$psuitable)
    leafletProxy("mymap",data=dd) %>%
      #clearControls() %>%  
    addLegend("topleft", pal = pal, values = ~dd$psuitable,
              title = "Suitability",
              labFormat = labelFormat(suffix = "%"),
              opacity = 1, layerId=1)
  }
)

output$tides = renderTable({
  tm<-Ftm()
  subset(tides,tides$time==tm)
})
  
})
