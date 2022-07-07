library(plotly)
library(tidyverse)
library(viridis)
library(shiny)
library(ggplot2)
library(haven)
library(dplyr)
library(hrbrthemes)
library(lubridate)
library(processx)
library(gganimate)
library(plotly)
library(readxl)





map_plot<-function(variable="lays"){
df <- read_dta("C:/Users/abrah/Dropbox/RA Task Oxford/Clean_data/hci_data_september_2020.dta")
  
df$CODE<-df$WBCode
  
df$Diff_EYS_LAYS<-df$lays-df$eys
  
df=df %>% 
    mutate_if(is.numeric, round, digits=1)
  

  
  
  
bound_col <- list(color = toRGB("grey"), width = 0.5)

# map options
g <- list(
  showframe = F,
  projection = list(type = 'Mercator')
)

# plot
fig <- plot_geo(df)
fig <- fig %>% add_trace(
  z = ~((get(variable))), color = ~((get(variable))), colors = 'Blues',
  text = ~df$CountryName,locations=~df$CODE, marker = list(line = bound_col)
)

# title and legend config
fig <- fig %>% colorbar(title = '')
fig <- fig %>% layout(
  title = "",
  geo = g)
  
fig
  


}

map_plot(variable="hlo")