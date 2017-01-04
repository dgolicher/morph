source("/home/rstudio/morph/scripts/db_functions.R")
PgMakeDb("brant")
PgInit("brant")
PgPlr("brant")

PgLoadRaster(flnm="dem.tif",x=120,y=120,tabnm="dem",
             db="brant",srid=3857,
             path="/home/rstudio/morph/rasters/")
PgLoadRaster(flnm="biomass.tif",x=120,y=120,tabnm="biomass",
             db="brant",srid=3857,
             path="/home/rstudio/morph/rasters/")
PgLoadRaster(flnm="shootlength.tif",x=120,y=120,tabnm="shootlength",
             db="brant",srid=3857,
             path="/home/rstudio/morph/rasters/")

PgMakeGrat(xdim=30,ydim=30)
PgPSuitable(depth=-0.4,height=0.4)
PgAddResource(db="brant",resource="biomass")
PgAddResource(db="brant",resource="shootlength")
PgLoadVector()
PgAddVector()
PgMakeDist()
PgMakeCentroidDist()
source("/home/rstudio/morph/scripts/Xtide.R")
source("/home/rstudio/morph/scripts/climate.R")
PgBackupDb()
con<-odbcConnect("brant")
grat<-PgGetQuery()
sites<-sqlQuery(con,"select 
                st_X(st_centroid(geom)) x, 
                st_y(st_centroid(geom)) y,
                * from grat")
sites$geom<-0

dist<-sqlQuery(con,"select * from centerdistances")
tides<-sqlQuery(con,"select * from tides")
clim<-sqlQuery(con,"select * from clim")
save(grat,sites,clim,dist,tides,file="/home/rstudio/morph/data/test.rob")
