
##group members:
##Maria Pereyra, Antonio Reybol Jr, Daiana Vega, Esmeralda Hoxha

install.packages("readxl")
library(readxl)
library(tidyverse)
library(dplyr)
library(ggplot2)
library(lubridate)
library(rpart)
library(randomForest)
install.packages("randomForest")
library(ISLR)
install.packages("scales") 
library("scales") 
library("RColorBrewer")
install.packages("tinytex")
library(tinytex)
library(modelr)
library(rpart.plot)


##Importing the data set into R, and filtering out rows to only look at data from years 2017-2019


us_accidents <- read_csv("US_Accidents_June20.csv")
us_accidents <- us_accidents %>% filter(Start_Time <= '2019-12-31')
us_accidents <- us_accidents %>% filter(Start_Time >= '2017-01-01')
arrange(us_accidents, Start_Time)


##Removing columns that we do not need, and only keeping columns that we feel are necessary to our
##project and the type of analysis that we are trying to conduct


us_accidents <- select(us_accidents, -Source, -Description, -Number, -Street, -Country, -Timezone, 
                       -Weather_Timestamp, -Side, -Airport_Code, -Bump, -Sunrise_Sunset, -Civil_Twilight, 
                       -Nautical_Twilight, -Astronomical_Twilight, -Start_Lat, -Start_Lng, -End_Lat, -End_Lng, -TMC, -`Wind_Chill(F)`)



##Cleaning up the data, converting times into a simple format and rearranging columns


us_accidents$Date <- format(as.Date(us_accidents$`Start_Time`,"%Y-%m-%d"), format = "%d/%m/%Y")
us_accidents$Year <- format(as.Date(us_accidents$`Start_Time`,"%Y-%m-%d"), format = "%Y")


us_accidents <- us_accidents %>% relocate(Date, .after = Severity)
us_accidents <- us_accidents %>% relocate(Year, .after = Date)


us_accidents$S_Time <- format(us_accidents$Start_Time,"%H")
us_accidents$E_Time <- format(us_accidents$End_Time,"%H:%M")


##Find the duration of the "clean-up" time for each accident, and converting the given duration from seconds
##into minutes, to have an easier number to work with.


us_accidents <- us_accidents %>% mutate(Duration = End_Time - Start_Time)
us_accidents <- us_accidents %>% tidyr::separate(Duration, c("Duration_Seconds"),extra='drop')
us_accidents %>% transmute(S_Time, Start_Time, E_Time, End_Time, Duration_Seconds)
us_accidents <- us_accidents %>% mutate ( Duration_Minutes = as.numeric(Duration_Seconds) / 60 )
us_accidents %>% transmute(S_Time, Start_Time, E_Time, End_Time, Duration_Minutes)


##Creating a column for Season, in order to use Seasons as a variable for our analysis 


months <- as.numeric(format(as.Date(us_accidents$Date, '%m/%d/%Y'), '%m'))
indx <- setNames( rep(c('winter', 'spring', 'summer',
                        'fall'),each=3), c(12,1:11))
us_accidents$Season <- unname(indx[as.character(months)])
us_accidents


##Now we are ready to use the data set! 


us_accidents1 <- us_accidents %>% drop_na()


#Making categorical data factors 


us_accidents$Weather_Condition = as.factor(us_accidents$Weather_Condition)
us_accidents1$Weather_Condition = as.factor(us_accidents1$Weather_Condition)
us_accidents1$Date <- as.Date(us_accidents1$Date, "%d/%m/%Y")
##us_accidents1$County <- as.factor(us_accidents1$County)


##tibble of accidents by county in CA:

CAcounties <- us_accidents_CA %>%group_by(County)

CA_counties <- us_accidents_CA %>% group_by(County) %>% summarise(CAcounties,Accident_Count = n())

##-----------------------------------------------------------------------------------------------
##CALIFORNIA
##-----------------------------------------------------------------------------------------------
##Filtering to get only Counties in CA

us_accidents_CA <- filter(us_accidents1, State == "CA")


##Getting Frequency of categorical data for CA


most_freq_weather_CA <- table(us_accidents_CA$Weather_Condition, useNA = "ifany")%>%
  sort( decreasing = TRUE)%>%
  head(15)
plot(most_freq_weather_CA)


##Filtering the data among weather condition types; can use for CA
us_accidents_CA <- filter(us_accidents_CA, Weather_Condition == "Fair" |
                            Weather_Condition == "Cloudy" |
                            Weather_Condition == "Partly Cloudy" |
                            Weather_Condition == "Mostly Cloudy" |
                            Weather_Condition == "Light Rain" |
                            Weather_Condition == "Overcast" |
                            Weather_Condition == "Haze" |
                            Weather_Condition == "Rain" |
                            Weather_Condition == "Fog" |
                            Weather_Condition == "Heavy Rain" |
                            Weather_Condition == "Fair / Windy" |
                            Weather_Condition == "Smoke" |
                            Weather_Condition == "Clear" |
                            Weather_Condition == "Scattered Clouds" |
                            Weather_Condition == "Partly Cloudy / Windy")


#Getting the count of accidents AND mean of other variable by hour per day for CA


CA_group <- us_accidents_CA %>% group_by(County,Date, S_Time)


overall_accidents_info_CA <- summarise(CA_group,
                                       Accident_Count = n(),
                                       Visibility_Mean = mean(`Visibility(mi)`),
                                       Temperature_Mean = mean(`Temperature(F)`),
                                       Humidity_Mean = mean(`Humidity(%)`),
                                       Pressure_Mean = mean(`Pressure(in)`),
                                       Wind_Speed_Mean = mean(`Wind_Speed(mph)`),
                                       Precipitation = mean(`Precipitation(in)`))


##Pivot Wide for CA
CA_df <- us_accidents_CA %>% mutate(dummy = 1) %>% pivot_wider(names_from = Weather_Condition, values_from = dummy, values_fill = 0) %>%
  group_by(County,Date,S_Time) %>% summarise(
    Fair = mean(Fair),
    Cloudy = mean(Cloudy),
    `Partly Cloudy` = mean(`Partly Cloudy`),
    `Mostly Cloudy` = mean(`Mostly Cloudy`),
    `Light Rain` = mean(`Light Rain`),
    Overcast = mean(Overcast),
    Haze = mean(Haze),
    Fog = mean(Fog),
    `Heavy Rain` = mean(`Heavy Rain`),
    `Fair / Windy` = mean(`Fair / Windy`),
    Smoke = mean(Smoke),
    Clear = mean(Clear),
    Scattered_Clouds = mean(`Scattered Clouds`),
    `Partly Cloudy / Windy` = mean(`Partly Cloudy / Windy`))


##Inner Join numerical data with categorical data for CA


overall_accidents_info_CA <- overall_accidents_info_CA %>% inner_join(CA_df, by = c("County", "Date", "S_Time"))


##Getting Mean of Logicals for CA


CA_group2 <- us_accidents_CA %>% group_by(County,Date, S_Time)


overall_accidents_info_CA2 <- summarise(CA_group2,
                                        Amenity_Mean = mean(`Amenity`),
                                        Crossing_Mean = mean(`Crossing`),
                                        Junction_Mean = mean(`Junction`),
                                        No_Exit_Mean = mean(`No_Exit`),
                                        Railway_Mean = mean(`Railway`),
                                        Roundabout_Mean = mean(`Roundabout`),
                                        Station_Mean = mean(`Station`),
                                        Stop_Mean = mean(`Stop`),
                                        Traffic_Calming_Mean = mean(`Traffic_Calming`),
                                        Traffic_Singnal_Mean = mean(`Traffic_Signal`))


##Final Inner Join that includes all means among data types for CA


CA_overall_accidents_info <- overall_accidents_info_CA %>% inner_join(overall_accidents_info_CA2, by = c("County", "Date", "S_Time"))

##-----------------------------------------------------------------------------------------------
## TEXAS
##-----------------------------------------------------------------------------------------------
us_accidents_TX <- filter(us_accidents1, State == "TX")


##Getting Frequency of categorical data for TX


most_freq_weather_TX <- table(us_accidents_TX$Weather_Condition, useNA = "ifany")%>%
  sort( decreasing = TRUE)%>%
  head(15)
most_freq_weather_TX 
plot(most_freq_weather_TX)



##Filtering the data for most frequent weather condition types for Texas


TX_weather <- filter(us_accidents_TX, 
                     Weather_Condition == "Fair" |
                       Weather_Condition == "Mostly Cloudy" |
                       Weather_Condition == "Partly Cloudy" |
                       Weather_Condition == "Cloudy" |
                       Weather_Condition == "Light Rain" |
                       Weather_Condition == "Overcast" |
                       Weather_Condition == "Rain" |
                       Weather_Condition == "Light Drizzle" |
                       Weather_Condition == "Fog" |
                       Weather_Condition == "Heavy Rain" |
                       Weather_Condition == "Light Thunderstorms and Rain" |
                       Weather_Condition == "Haze" |
                       Weather_Condition == "Light Rain with Thunder" |
                       Weather_Condition == "Heavy Thunderstorms and Rain" |
                       Weather_Condition == "Thunderstorms and Rain  " |
                       Weather_Condition == "Partly Cloudy / Windy") 
TX_weather

#Getting the count of accidents AND mean of other variable by hour per day for TX

TX_group <- us_accidents_TX %>% group_by(County,Date, S_Time)

overall_accidents_info_TX <- summarise(TX_group,
                                       Accident_Count = n(),
                                       Visibility_Mean = mean(`Visibility(mi)`),
                                       Temperature_Mean = mean(`Temperature(F)`),
                                       Humidity_Mean = mean(`Humidity(%)`),
                                       Pressure_Mean = mean(`Pressure(in)`),
                                       Wind_Speed_Mean = mean(`Wind_Speed(mph)`),
                                       Precipitation = mean(`Precipitation(in)`))


##Pivot Wide for TX
TX_df <- us_accidents_TX %>% mutate(dummy = 1) %>% pivot_wider(names_from = Weather_Condition, values_from = dummy, values_fill = 0) %>%
  group_by(County,Date,S_Time) %>% summarise(
    Fair = mean(Fair),
    `Mostly Cloudy` = mean(`Mostly Cloudy`),
    `Partly Cloudy` = mean(`Partly Cloudy`),
    Cloudy = mean(Cloudy),
    `Light Rain` = mean(`Light Rain`),
    Overcast = mean(Overcast),
    Rain = mean(Rain),
    `Light Drizzle` = mean(`Light Drizzle`),
    Fog = mean(Fog),
    `Heavy Rain` = mean(`Heavy Rain`),
    `Light Thunderstorms and Rain` = mean(`Light Thunderstorms and Rain`),
    Haze = mean(Haze),
    `Light Rain with Thunder` = mean(`Light Rain with Thunder`),
    `Heavy Thunderstorms and Rain` = mean(`Heavy Thunderstorms and Rain`),
    `Thunderstorms and Rain` = mean(`Thunderstorms and Rain`),
    `Partly Cloudy / Windy` = mean(`Partly Cloudy / Windy`))

####Inner Join numerical data with categorical data for TX

overall_accidents_info_TX <- overall_accidents_info_TX %>% inner_join(TX_df, by = c("County", "Date", "S_Time"))

##Getting Mean of Logicals for TX

TX_group2 <- us_accidents_TX %>% group_by(County,Date, S_Time)


overall_accidents_info_TX2 <- summarise(TX_group2,
                                        Amenity_Mean = mean(`Amenity`),
                                        Crossing_Mean = mean(`Crossing`),
                                        Junction_Mean = mean(`Junction`),
                                        No_Exit_Mean = mean(`No_Exit`),
                                        Railway_Mean = mean(`Railway`),
                                        Roundabout_Mean = mean(`Roundabout`),
                                        Station_Mean = mean(`Station`),
                                        Stop_Mean = mean(`Stop`),
                                        Traffic_Calming_Mean = mean(`Traffic_Calming`),
                                        Traffic_Singnal_Mean = mean(`Traffic_Signal`)


##Final Inner Join that includes all means among data types for TX

TX_overall_accidents_info <- overall_accidents_info_TX %>% inner_join(overall_accidents_info_TX2, by = c("County", "Date", "S_Time"))

##-----------------------------------------------------------------------------------------------------------------------------


##Models:

##CALIFORNIA

##regression tree:

CA_tree <- rpart(Accident_Count ~ ., data = trainingCA, control = rpart.control(cp = 0.01))

#examination of the most important variables:
summary(CA_tree)
print(CA_tree)
printcp(CA_tree)##display the results 
plotcp(CA_tree) ##visualize cross-validation results

##root-mean-square error:
rmse(CA_tree ,testingCA) ##2.1094

#plotting the regression tree:
rpart.plot(CA_tree)

plot(CA_tree, uniform=TRUE,
     main="CA Regression Tree")
text(CA_tree, use.n=TRUE, all=TRUE, cex=.8)


##change the col names: 
colnames(CA_overall_accidents_info)[colnames(CA_overall_accidents_info) %in% c("Partly Cloudy", "Mostly Cloudy", "Light Rain", "Heavy Rain", "Fair / Windy", "Partly Cloudy / Windy")] <- c("Partly_Cloudy","Mostly_Cloudy", "Light_Rain", "Heavy_Rain", "Fair_Windy", "Partly_Cloudy_Windy")


##Sampling the data:

data_set_sizeCA = floor(nrow(CA_overall_accidents_info) * .80)
indexCA <- sample(1:nrow(CA_overall_accidents_info), size = data_set_sizeCA)
trainingCA <- CA_overall_accidents_info[indexCA,]
testingCA <- CA_overall_accidents_info[-indexCA,]


RandomForestCA <- randomForest(Accident_Count ~ ., data = trainingCA, ntree = 500, importance = TRUE, do.trace = 10)

plot(RandomForestCA)##this plot shows the error and the number of trees.
print(RandomForestCA)
importance(RandomForestCA)
varImpPlot(RandomForestCA)


##finding the best mtry value:
mtryCA <- tuneRF(trainingCA[-1], trainingCA$Accident_Count, ntreeTry= 400,
               stepFactor = 1.5, improve = 0.01, trace = TRUE, plot = TRUE)
Best.mCA <- mtry[mtry[,2] == min (mtry[,2]),1]
print(mtryCA)
print(best.mCA)

##new randomforest with best mtry value:

set.seed(123)
BestRandomForestCA <- randomForest(Accident_Count ~ .,data = trainingCA, mtry=Best.mCA, importance = TRUE, ntree = 400, do.trace = 10)

print(BestRandomForestCA)
plot(BestRandomForestCA)##this plot shows the error and the number of trees.

##plot of the nodes:
hist(treesize(BestRandomForestCA),
     main= "No. of nodes for the Random Forest"
     col = "green"
     
## Variable Importance to find out which variables play an important role in the model
varImpPlot(BestRandomForestCA)          ## variable importance for CA random forest model
     
importance(BestRandomForestCA)
varUsed(BestRandomForestCA)
     
varImpPlot(BestRandomForestCA,
                sort = T ,
                n.var = 15 ,
                main = "Top 15 - Variable Importance",
                col = "blue" )
     
     
## residuals plot: 
trainingCA %>% add_residuals(BestRandomForestCA) %>%
ggplot(aes(x = resid)) + geom_histogram() + xlab('Residuals') + ylab('Count') + ggtitle('Histogram of residuals of random forest CA')
     
##rmse:
rmse(BestRandomForestCA,testingCA) 
     
      
##------------------------------------------------------------------------------------------------------------------------------------


##TEXAS:

##regression tree:

TX_tree <- rpart(Accident_Count ~ ., data = trainingTX , control = rpart.control(cp = 0.01))

#examination of the most important variables:
summary(TX_tree)
print(TX_tree)
printcp(TX_tree)##display the results 
plotcp(TX_tree) ##visualize cross-validation results

##root-mean-square error:
rmse(TX_tree ,testingTX) ##2.1094

#ploting the regression tree:
rpart.plot(TX_tree)

plot(TX_tree, uniform=TRUE,
     main="TX Regression Tree")
text(TX_tree, use.n=TRUE, all=TRUE, cex=.8)

##change the col names: 

colnames(TX_overall_accidents_info)[colnames(TX_overall_accidents_info) %in% 
                                      c("Mostly Cloudy","Partly Cloudy", "Light Rain", "Light Drizzle", "Heavy Rain", "Light Thunderstorms and Rain", "Light Rain with Thunder", "Heavy Thunderstorms and Rain", "Thunderstorms and Rain", "Partly Cloudy / Windy")] <- c("Mostly_Cloudy","Partly_Cloudy", "Light_Rain", "Light_Drizzle", "Heavy_Rain", "Light_Thunderstorms_Rain", "Light_Rain_Thunder", "Heavy_Thunderstorms_Rain", "Thunderstorms_Rain", "Partly_Cloudy_Windy")

##Sampling the data:
data_set_sizeTX = floor(nrow(TX_overall_accidents_info) * .80)
indexTX <- sample(1:nrow(TX_overall_accidents_info), size = data_set_sizeTX)
trainingTX <- TX_overall_accidents_info[indexTX,]
testingTX <- TX_overall_accidents_info[-indexTX,]


RandomForestTX <- randomForest(Accident_Count ~ ., data = trainingTX, ntree = 500, importance = TRUE, do.trace = 10)
print(RandomForestTX)
importance(RandomForestTX)
varImpPlot(RandomForestTX)

##finding the best mtry value:
mtryTX <- tuneRF(trainingTX[-1], trainingTX$Accident_Count, ntreeTry= 400,
               stepFactor = 1.5, improve = 0.01, trace = TRUE, plot = TRUE)
Best.mTX <- mtry[mtry[,2] == min (mtry[,2]),1]
print(mtryTX)
print(best.mTX)

##new randomforest with best mtry value:

set.seed(123)
BestRandomForestTX <- randomForest(Accident_Count ~ .,data = trainingTX, mtry=Best.mTX, importance = TRUE, ntree = 400, do.trace = 10)
print(BestRandomForestTX)
plot(BestRandomForestTX)##this plot shows the error and the number of trees.

## No. of nodes for the trees:
hist(treesize(BestRandomForestTX),
     main= "No. of nodes for the Random Forest",
     col = "green")
     
## Variable Importance to find out which variables play an important role in the model
varImpPlot(BestRandomForestTX)          ## variable importance for TX random forest model

importance(BestRandomForestTX)
varUsed(BestRandomForestTX)

varImpPlot(BestRandomForestTX,
           sort = T ,
           n.var = 15 ,
           main = "Top 15 - Variable Importance",
           col = "blue" )

## residuals plot: 
trainingTX %>% add_residuals(BestRandomForestTX) %>%
  ggplot(aes(x = resid)) + geom_histogram() + xlab('Residuals') + ylab('Count') + ggtitle('Histogram of residuals of random forest TX')

##rmse:
rmse(BestRandomForestTX,testingTX) ##1.08




##----------------------------------------------------------------------------------------------------------------------------------
##linear models:
##__________________________________________________________________________________________________________________________________

##CALIFORNIA

##Multi Linear Model for CA - Top 5 variables identified as important 
ML_CA <- lm(`Accident_Count` ~ `Junction_Mean` + `Traffic_Singnal_Mean` + `County` + `Date` + `Visibility_Mean`, data = trainingCA)
summary(ML_CA)

##Our p-value of the F-statistic is <2.2e-16, which is conveys a high significance
##This means that, at least, one of the predictor variables is significantly related
##to the outcome variable, we will analize this further by seeing the coefficients table
##which shows the estimates of regession beta coefficients and the associated t-static
##p-values:

summary(ML_CA)$coefficient

##Looking at the below summary, changes in Traffic_Singal_Mean and Date are 
##significantly associated to changes in the Accident count, while changes in the County and Visibility_Mean
##are not as significant with the total number of accidents. 
##Therefore, we've removed all the variables, but Traffic_Singal_Mean and Date to produce a better
##model: ML_CA2:

ML_CA2 <- lm(`Accident_Count` ~ `Traffic_Singnal_Mean` + `Date`, data = trainingCA)
summary(ML_CA2)

##The confidence interval of the model can be extracted as follows:
confint(ML_CA2)

##residuals:
plot(trainingCA$Accident_Count, residuals(ML_CA))
plot(trainingCA$Accident_Count, residuals(ML_CA2))

##rmse:
rmse(ML_CA, data=testingCA)##2.87
rmse(ML_CA2,data=testingCA)##3.25



##------------------------------------------------------------------------------------------------------------------------------------
##TEXAS

##we did  the linear model out the most important variables determined by our random forest:

LinearModelTX <- lm (Accident_Count ~ Traffic_Singnal_Mean + Junction_Mean + Mostly_Cloudy + Crossing_Mean + Light_Rain, data=trainingTX)
summary(LinearModelTX)
##our p-value of the F-statistic is <2.2e-16, which is highly significant. this means that, at least, one of the predictor variables is significantly related to the outcome variable, we will analize this 
##further by seeing the coefficients table, which shows the estimate of regression beta coefficients and the associated t-static p-values:

summary(LinearModelTX)$coefficient
## it can be seen that, changes in Traffic_Signal and Light rain are significantly associated to changes in the Accident count, while changes in the Junction, weather type: mostly cloudy
## and light rain are not significantly associated with the accidents count. 

##as the junction mean and weather condition:mostly cloudy and light rain variables are not significant, it is possible to remove them from the model:

LinearModelTX1 <- lm(Accident_Count ~ Traffic_Singnal_Mean + Crossing_Mean, data = trainingTX)
summary(LinearModelTX1)

##The confidence interval of the model can be extracted as follows:
confint(LinearModelTX1)


##residuals:
plot(trainingTX$Accident_Count, residuals(LinearModelTX))
plot(trainingTX$Accident_Count, residuals(LinearModelTX1))

##rmse:
rmse(LinearModelTX, data=testingTX)##2.76
rmse(LinearModelTX1,data=testingTX)##2.76





