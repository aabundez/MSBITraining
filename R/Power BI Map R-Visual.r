# Create dataframe
# dataset <- data.frame(DestinationLat, DestinationLon, DEST, Load Factor, Load Factor by Origin, OriginLat, OriginLon, Origin, Departures Performed, Airport)

#Remove duplicated rows
#dataset <- unique(dataset)

# TODO:
#   Bubble Legend
#   Remove Color Palette for Points. Using alpha value to identify patterns when overplotting points.

library(maps)		# for map
library(geosphere)	# for great circle points
library(mapproj)	# for points
library(shape)          # for gradient legend


# Calculate best map limits to maintain 2:1 aspect ratio

lat <- c(dataset$OriginLat, dataset$DestinationLat)
lon <- c(dataset$OriginLon, dataset$DestinationLon)
viewport_angle <- 63.4349 * (pi/180)                               # angle b/t left side of viewport and diagnoal (hypotenuse)

if ( (max(lat) - min(lat)) / (max(lon) - min(lon)) >= .5 ) {
  x <- c( (    ( max(lon) - ( (max(lon) - min(lon)) / 2 ) )    -    ( ((max(lat)+1) - (min(lat)-1)) / 2 ) * tan(viewport_angle )      ) ,
             (    ( max(lon) - ( (max(lon) - min(lon)) / 2 ) )    +    ( ((max(lat)+1) - (min(lat)-1)) / 2 ) * tan(viewport_angle )      )
            )
  y <- c(min(lat)-1, max(lat)+1 )	
} else {
x <- c(min(lon)-5, max(lon)+5 )
y <- c( (    ( max(lat) - ( (max(lat) - min(lat)) / 2 ) )    -    ( ((max(lon)+5) - (min(lon)-5)) / 2 ) / tan(viewport_angle )      ) ,
           (    ( max(lat) - ( (max(lat) - min(lat)) / 2 ) )    +    ( ((max(lon)+5) - (min(lon)-5)) / 2 ) / tan(viewport_angle )      )
          )
}

# Draw world map with states and scale
map("world", col="#F1F1F1", fill=TRUE, bg="#FFFFFF", lwd=0.05, xlim=x, ylim=y, mar=rep(0,4))   # map w/ zoom
map("state", col="#d2d2d2", fill = FALSE, add = TRUE)
map.scale(grconvertX(0.01, "npc"), grconvertY(0.07, "npc"), metric = FALSE, relwidth = .18, ratio = FALSE)


# define color palette for lines
pal <- colorRampPalette(c("#02B8AB", "#01655E"))
ln_col <- pal(100)

# define color palette for points
pnt <- colorRampPalette(c("#8486F2", "#4C4D8B"))
pn_col <-pnt(100)

# point color
pcol <- "#E74C3C"

# text color
tcol <-"#002F2F"

# Order dataset (to draw in order of palette shade)
dataset <- dataset[order(dataset$"Load Factor by Origin"),]
maxcnt <- max(dataset$"Load Factor by Origin")

# Draw Flight Routes
for (j in 1:nrow(dataset)) {
    inter <- gcIntermediate( c(dataset$OriginLon[j], dataset$OriginLat[j]), c(dataset$DestinationLon[j], dataset$DestinationLat[j]), n=100, addStartEnd=TRUE)
    colindex <- round( (dataset$"Load Factor by Origin"[j] / maxcnt) * length(ln_col) )
    lines(inter, col=ln_col[colindex], lwd=1 ) # Draw lines
    
    # points(mapproject(dataset$OriginLon[j], dataset$OriginLat[j]), col="#ff9147", bg="#FFED47", pch=25, cex=1)		# Origin point
    # text(dataset$OriginLon[j], dataset$OriginLat[j], dataset$Airport[j], cex=1, pos=4, col=tcol)                                             # Origin airport code text
}

# Sum Flights by Destination
dataset2 <- aggregate(dataset$"Departures Performed", by=list(dataset$"DEST", dataset$"DestinationLat", dataset$"DestinationLon"), FUN=sum)
names(dataset2) <- c("DEST", "DestinationLat", "DestinationLon", "Departures by Destination")  #change column names

# Draw bubbles for Flights by Destination
for (a in 1:nrow(dataset2)) {
    
    if ( max(dataset2$"Departures by Destination"[a])  < 500 ) {
        bubble_size_factor <- 5 
    } else {
        bubble_size_factor <- 10
    } 

    points(mapproject(dataset2$DestinationLon[a], dataset2$DestinationLat[a]), col="#4C4D8B", bg=rgb( red=132, green=134, blue=242, alpha = 125, max=255 ), pch=21, cex= sqrt( dataset2$"Departures by Destination"[a] ) / bubble_size_factor ) # Destination point
    text(dataset2$DestinationLon[a], dataset2$DestinationLat[a], dataset2$DEST[a], cex=1, pos=4, col=tcol)  #Destination airport text
}

# Draw Origin Marks
for (j in 1:nrow(dataset)) {
    
    points(mapproject(dataset$OriginLon[j], dataset$OriginLat[j]), col="#ff9147", bg="#FFED47", pch=25, cex=1)		# Origin point
    text(dataset$OriginLon[j], dataset$OriginLat[j], dataset$Airport[j], cex=1, pos=4, col=tcol)                                             # Origin airport code text
}

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

# Add Lines Legend

maxcnt <- max(dataset$"Load Factor by Origin")
mincnt <- min(dataset$"Load Factor by Origin")

if( maxcnt == mincnt) {
    mincnt = 0.0 } 

max_formatted <- maxcnt * 100
min_formatted <- mincnt * 100

colorlegend(
    posx = c(0.9, 0.93), 
    posy = c(0.05, 0.3), 
    col = ln_col,
    zlim =c(min_formatted,max_formatted ),
    zval=c(min_formatted, max_formatted ),
    main="Load Factor",
    main.cex = 1, 
    main.col = "black", 
    lab.col = "black", 
    digit = 2)