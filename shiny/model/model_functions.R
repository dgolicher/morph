library(shiny)
library(rgdal)
library(plotly)
library(ggplot2)
library(dismo)
library(dplyr)
library(insol)

load("/home/rstudio/morph/data/test.rob")
map<-gmap(grat,type="satellite")

FMakeTime<-function(year=2016,month=1,day=1,hr=1){
  tm<-sprintf("%04d-%02d-%02d %02d:00:00",year,month,day,hr)
  tm<-as.POSIXct(tm)
  tm
}


FSuitable<-function(fsites=sites,ftm=tm,ftides=tides,depth=-1,height=1){
  current_tide<-subset(ftides,ftides$time==ftm)
  d<-merge(fsites,current_tide)
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
  fsites$psuitable<-apply(dd,1,f)
  fsites
}


FFat2Energy<-function(fat)34.3*fat # g fat to KJoules
FEnergy2Fat<-function(energy)energy/34.3 # KJoules to g fat

FArriveBirds<-function(ftm=tm,nbirds= 10,fsites=sites,male_wt=1500,female_wt=1400,fat=300)
{
  sex<-sample(c("M","F"),nbirds,replace=T)
  lean_wt<-numeric(nbirds)
  lean_wt[sex=="M"]<-male_wt
  lean_wt[sex=="F"]<-female_wt
  lean_wt<-lean_wt+rnorm(nbirds,0,sd=20)
  fat<-rlnorm(nbirds,mean=log(fat),sd=0.2)
  wt<-lean_wt+fat
  energy_store<-FFat2Energy(fat)
  ## Add other properties here
  ##
  rid<-sample(fsites$rid,nbirds,replace=TRUE) ## Place them at random
  bid<-1:nbirds ## ID number
  birds<-data.frame(bid,arrive_time=ftm,sex=sex,weight=wt,fat=fat,energy_store=energy_store,rid=rid)
  birds
}

FAddBirds<-function(ftm=tm,nbirds= 10,fsites=sites,fbirds=birds)
{
  newbirds<-FArriveBirds(ftm,nbirds,fsites)
  newbirds$bid<-newbirds$bid+max(fbirds$bid)
  rbind(fbirds,newbirds)
}

FValueSites<-function(fsites=sites)
{
  ## Make a rule for calculating value of site 
  # for feeding
  ## Make it the amount of biomass times proportion available
  fsites$value<-fsites$psuitable/100*fsites$mean_biomass
  fsites$value[is.na(fsites$value)]<-0
  fsites
}


FMoveBirds<-function(fbirds=birds,fsites=sites,fdist=dist,search_distance=1200)
{
  ##Set the search distance
  fdist<-subset(fdist,fdist$dist_m<search_distance)
  # Merge the bird data frame to sites to get the values at the sites
  birds_sites<-merge(fbirds,fsites)
  # Take only the sites with birds
  bird_positions<-data.frame(rid=unique(birds_sites$rid))
  # Get all the possible moves from these sites by merging
  bird_moves<-merge(bird_positions,fdist)
  # Find the value of the index used for choosing the site at the destinations
  destination_value<-data.frame(rid2=fsites$rid,value=fsites$value)
  # Add this to the object used for evaluating the moves
  bird_moves<-merge(bird_moves,destination_value)
  ## the next two lines not really needed, Used in testing
  ## They order the object and set a seed for the random choice
  bird_moves<-bird_moves[order(bird_moves$rid),]
  set.seed(1)
  ###
  # A function to rank the values. Ties are assigned at random.
  f<-function(x)rank(-x,ties.method= "random")
  ## Now rank all the moves, grouping by point of origin.
  bird_moves$rank<-unlist(tapply(bird_moves$value,bird_moves$rid,f))
  # Take only the best
  bird_moves<-subset(bird_moves,bird_moves$rank==1)
  # Merge the movements with the birds data frame so that the birds know where they are going to.
  bird_moves<-merge(fbirds,bird_moves)
  # Assign the new rids to the birds
  bird_moves$rid<-bird_moves$rid2
  # Get rid of the extra columns in the dataframe to return it to the old state
  keep_columns<-1:dim(fbirds)[2]
  fbirds<-bird_moves[,keep_columns]
  fbirds
}


### Energy calculations not yet correct

FConsumption<-function(biomass)100*0.01028*(1-exp(-0.105*biomass))*(1.0373*(1-exp(-0.0184*biomass)))

FEnergyAssim<-function(consumption, a=0.464, E= 16.8)consumption*a*E

<<<<<<< HEAD
FMR<-function(temperature=-10,windspeed=2,mass=1500)
{
  TBrant<-7.5
  temperature[temperature>TBrant]<-TBrant
  windspeed[windspeed<0.5]<-0.5
=======
FMR<-function(temperature=4,windspeed=9.4,mass=1500)
{
  TBrant<-37.5
>>>>>>> dec55a03f59965ed4d221baa332c219f556ec9c8
  DeltaT<-TBrant-temperature
  b<-0.0092*mass^0.66*DeltaT^0.32
  a<-4.15-b*sqrt(0.06)
  a+b+sqrt(windspeed)
}

### Utility to check if day or night

FIsDay<-function(tm,Lat=55.32,Lon=-162.8)
{
  hr<-as.numeric(format(tm, format='%H'))
  day_len<-data.frame(daylength(Lat, Lon,JD(tm), tmz=-10))
  isday<-ifelse(hr>day_len$sunrise & hr< day_len$sunset,"Day","Night") 
  isday}



