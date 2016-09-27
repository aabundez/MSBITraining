#========== SETUP DATA FRAMES =================
  
  # COLLECT AIRPORT DATA
  airports <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat", header = FALSE)
  colnames(airports) <- c("ID", "name", "city", "country", "IATA_FAA", "ICAO", "lat", "lon", "altitude", "timezone", "DST")
  
  sort(unique(airports$country))
  
  us_airports <- subset(airports, country=='United States')
  
  # COLLECT ROUTE DATA
  routes <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat", header=F)
  colnames(routes) <- c("airline", "airlineID", "sourceAirport", "sourceAirportID", "destinationAirport", "destinationAirportID", "codeshare", "stops", "equipment")
  
  # MERGE LAT LON from flights
  routesD <- merge(routes, us_airports, by.x = "destinationAirportID", by.y="ID")
  routesAll <- merge(routesD, us_airports, by.x = "sourceAirportID", by.y="ID")


#========== START BASE MAP VISUALIZATION =========================
library(maps)
library(mapproj)

map("world", col="#F1F1F1", fill=TRUE, bg="#FFFFFF", lwd=0.05, mar=rep(0,4))

map("state", col="#000000", fill = FALSE, add = TRUE)

map.scale(
  grconvertX(0.01, "npc"),
  grconvertY(0.07, "npc"),
  metric = FALSE,
  relwidth = .18,
  ratio = FALSE
)

points(
  mapproject(us_airports$lon, us_airports$lat),
  col = "#4C4D8B",
  bg = rgb(
    red = 132,
    green = 134,
    blue = 242,
    alpha = 125,
    max = 255
  ),
  pch = 21,
  cex = 1
)


#============ US BASEMAP ===============================

xlim <- c(-171.738281, -56.601563)
ylim <- c(12.039321, 71.856229)
map("world", col="#f2f2f2", fill=TRUE, bg="light blue", lwd=0.05, xlim=xlim, ylim=ylim)
map("state", col="#000000", fill = FALSE, add = TRUE)
map.scale(grconvertX(0.01, "npc"), grconvertY(0.07, "npc"), metric = FALSE, relwidth = .18, ratio = FALSE)


#============ PLOT POINTS ==============================

help(points)


points(mapproject(us_airports$lon, us_airports$lat), col="#000000", pch=19, cex= .5 )
points(mapproject(us_airports$lon, us_airports$lat), col="#4C4D8B", bg=rgb( red=132, green=134, blue=242, alpha = 125, max=255 ), pch=21, cex= 1 )


#============ PLOT GREAT CIRCLES ========================

laflights <- routesAll[routesAll$sourceAirport=='LAX',]
sfoflights <- routesAll[routesAll$sourceAirport=='SFO',]

map("world", col="#f2f2f2", fill=TRUE, bg="light blue", lwd=0.05, xlim=xlim, ylim=ylim)

#PLOT LINES WITH NO COLOR SCALE
library(geosphere)
help(gcIntermediate)

for (j in 1:nrow(laflights)) {
  
  inter <- gcIntermediate(c(laflights$lon.y[j], laflights$lat.y[j]), c(laflights$lon.x[j], laflights$lat.x[j]), n=100, addStartEnd=TRUE)
  
  lines(inter, col="red", lwd=0.8)
}


help(gcIntermediate)


for (j in 1:nrow(sfoflights)) {
  
  inter <- gcIntermediate(c(sfoflights$lon.y[j], sfoflights$lat.y[j]), c(sfoflights$lon.x[j], sfoflights$lat.x[j]), n=100, addStartEnd=TRUE)
  
  lines(inter, col="blue", lwd=0.8)
}


#============== PUT IT ALL TOGETHER ========================

# PLOT BASE MAP
map("world", col="#f2f2f2", fill=TRUE, bg="light blue", lwd=0.05, xlim=xlim, ylim=ylim)


# PLOT FLIGHTS FROM LAX
for (j in 1:nrow(laflights)) {
  
  inter <- gcIntermediate(c(laflights$lon.y[j], laflights$lat.y[j]), c(laflights$lon.x[j], laflights$lat.x[j]), n=100, addStartEnd=TRUE)
  
  lines(inter, col="gray", lwd=0.8)
}


# PLOT DESTINATION MARK
points(mapproject(laflights$lon.x, laflights$lat.x), col="#4C4D8B", bg=rgb( red=132, green=134, blue=242, alpha = 125, max=255 ), pch=21, cex= 1 )

# PLOT ORIGIN MARK
points(mapproject(laflights$lon.y, laflights$lat.y), col="#ff9147", bg="#FFED47", pch=25, cex= 2 )

# ADD DESTINATION TEXT
text(laflights$lon.x, laflights$lat.x, laflights$destinationAirport, cex=.5, pos=4, col="#000000")

# ADD SCALE
map.scale(grconvertX(0.01, "npc"), grconvertY(0.07, "npc"), metric = FALSE, relwidth = .18, ratio = FALSE)


# Add Marks Legend

legend(
  grconvertX(0.01, "npc"), 
  grconvertY(0.15, "npc"),
  c('Origin', 'Destination'), 
  pch=c(25, 21), 
  col=c("#ff9147", "#4C4D8B"), 
  pt.bg=c("#FFED47",rgb( red=132, green=134, blue=242, alpha = 125, max=255 ) ),
  cex = 1,
  bty = "n",
  ncol=2,
  pt.cex = 1.5
)







