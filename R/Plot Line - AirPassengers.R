
# Plot lines out of AirPassengers dataset

dmn<-list(month.abb, unique(floor(time(AirPassengers))))
df<-as.data.frame(t(matrix(AirPassengers, 12, dimnames = dmn)))
plot(df$Jan, type="o", pch=20, col="red")