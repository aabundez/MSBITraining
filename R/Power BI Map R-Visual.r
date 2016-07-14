# Create dataframe
# dataset <- data.frame(DEST, Departures Performed, Load Factor, Load Factor by Origin, OriginLat, OriginLon, DestinationLat, DestinationLon, Airport, Origin)

#Remove duplicated rows
#dataset <- unique(dataset)

# TODO:
#	Draw points and text after lines, and only as many times as necessary (separate for loop)

library(maps)		# for map
library(geosphere)	# for great circle points
library(mapproj)	# for points

lat <- c(dataset$OriginLat, dataset$DestinationLat)
lon <- c(dataset$OriginLon, dataset$DestinationLon)

#do a bit of Geometry
viewport_angle <- 63.4349 * (pi/180)

# finding bounding box points
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

# create map and points
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

# order data set (to draw in order of palette shade)
dataset <- dataset[order(dataset$"Load Factor by Origin"),]
maxcnt <- max(dataset$"Load Factor by Origin")

# define and draw lines
for (j in 1:nrow(dataset)) {
    inter <- gcIntermediate( c(dataset$OriginLon[j], dataset$OriginLat[j]), c(dataset$DestinationLon[j], dataset$DestinationLat[j]), n=100, addStartEnd=TRUE)
    colindex <- round( (dataset$"Load Factor by Origin"[j] / maxcnt) * length(ln_col) )
    lines(inter, col=ln_col[colindex], lwd=1 ) # Draw lines

    # OLD CODE:
    # lines(inter, col=ln_col[colindex], lwd=colindex/10 )
    
    points(mapproject(dataset$OriginLon[j], dataset$OriginLat[j]), col="#ff9147", bg="#FFED47", pch=25, cex=1)		# Origin point
    points(mapproject(dataset$DestinationLon[j], dataset$DestinationLat[j]), col="#4C4D8B", bg=rgb( red=132, green=134, blue=242, alpha = 125, max=255 ), pch=21, cex= sqrt( dataset$"Departures Performed"[j] ) / 4 )		# Destination point

    text(dataset$OriginLon[j], dataset$OriginLat[j], dataset$Airport[j], cex=1, pos=4, col=tcol)
    text(dataset$DestinationLon[j], dataset$DestinationLat[j], dataset$DEST[j], cex=1, pos=4, col=tcol)
}

legend(
   grconvertX(0.01, "npc"), 
   grconvertY(0.15, "npc"),
   c('Origins', 'Destinations'), 
   pch=c(25, 21), 
   col=c("#ff9147", "#4C4D8B"), 
   pt.bg=c("#FFED47",rgb( red=132, green=134, blue=242, alpha = 125, max=255 ) ),
   cex = 1,
   bty = "n",
   ncol=2,
   pt.cex = 1.5
)