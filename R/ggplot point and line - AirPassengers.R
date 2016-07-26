
library(ggplot2)

# Convert AirPassengers from Time Series to Data Frame
dmn<-list(month.abb, unique(floor(time(AirPassengers))))
df<-as.data.frame(t(matrix(AirPassengers, 12, dimnames = dmn)))

# Pivot columns to rows and rows to columns
df2 <- data.frame(colnames(df), df[,1], df[,2], df[,3])
colnames(df2) <- c("month", "1949", "1950", "1951")

# Explicitly force order of data.frame df2
df2$month <- factor(df2$month, 
                    levels=df2$month[
                      order(as.numeric(rownames(df2)))
                      ]
                    )

# Plot the lines

ggplot(df2, aes(x=month, df2$`1949`, group=1)) + 
  
  # plot 1949
  geom_point( color="orange" ) + 
  geom_line( color="orange" ) +
  
  # plot 1950
  geom_point(y=df2$"1950", color="blue", pch=18, size=2) +
  geom_line(y=df2$"1950", color="blue") +
  
  # plot 1951
  geom_point(y=df2$"1951", color="red", pch=17, size=2) +
  geom_line(y=df2$"1951", color="red", lty=6) +
  
  labs( x = "Month",
       y = "Passengers"
       ) +
  
  # geom_text( nudge_x = 0.7 ) + #check_overlap = TRUE )
  
  theme(
   rect = element_blank(), 
   panel.grid.major.y = element_line(colour = "grey")
   )


