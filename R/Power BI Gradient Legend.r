# Create dataframe
# dataset <- data.frame(Origin, Load Factor by Origin)

# Remove duplicated rows
# dataset <- unique(dataset)


#set margins and transparency
par(mar=c(1.8,1.5,1,1.2), bg="transparent")


color.bar <- function(lut, min, max, nticks=2, ticks=seq(min, max, len=nticks), title='Load Factor') {
    scale = (length(lut)-1)/(max-min)

    #dev.new(width=1.75, height=5)
    plot(c(min,max), c(0,10), type='n', bty='n', xaxt='n', xlab='', yaxt='n', ylab='', main=title, cex.main = 1.05, font.main = 1 )
    axis(1, at=ticks, labels=paste(round(ticks, 4) * 100, "%"), cex.axis=1 )
    for (i in 1:(length(lut)-1)) {
     x = (i-1)/scale + min
     rect(x,0,x+1/scale,10, col=lut[i], border=NA)
    }
}

maxcnt <- max(dataset$"Load Factor by Origin")
mincnt <- min(dataset$"Load Factor by Origin", rm.na=TRUE)

color.bar(colorRampPalette(c("#02B8AB", "#01655E"))(100), mincnt, maxcnt)