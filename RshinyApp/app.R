
rm(list = ls(all = TRUE))

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

library("readxl")
# xls files

#setwd("C:/Users/abrah/Dropbox/oxford_submission/RshinyApp/")


org_data <- read_excel("hlo_database.xlsx", sheet = "HLO Database")

mydata<-org_data
vars<-c("hlo","hlo_m","hlo_f")
countries<-unique(mydata$country)

levels =c("pri","sec")
subjects=c("math","reading","science")




scatter_plot<-function(Country="Uruguay",X="hlo_m",Y="hlo_f",Z="math"){
  G2=mydata%>%filter(country==Country & subject==Z )%>% 
    ggplot(aes(x = (get(X)), y = (get(Y))))+ 
    geom_point(aes(shape = level, color = level)) + 
    labs(subtitle=paste(Country,":",  X, "vs.",Y, sep=" "), 
         y=Y, 
         x=X, 
         title=paste("Scatter plot",X,"and",Y,"across years",sep=" "))+
    theme_ft_rc()+ theme(aspect.ratio=1)
  
  
  #can have countries,choose variables and years.
  
  
  G2=ggplotly(G2,tooltip = c(''))
  G2
  
}
scatter_plot()
df <- read_dta("hci_data_september_2020.dta")
df$CODE<-df$WBCode
df$Diff_EYS_LAYS<-df$lays-df$eys

df=df %>% 
  mutate_if(is.numeric, round, digits=1)

head(df)






line_plot<-function(var="hlo",year1=2007,year2=2015,countries= c("Sweden","Belgium","Norway","Finland"),subject_choice="math",Level="sec"){
  
  
  data<-mydata%>% filter(country %in%countries )%>%filter(level==Level)%>%filter(subject==subject_choice) %>%filter(year>=year1 &year<=year2)
  
  
  G1=ggplot(data, aes(x=year, y=(get(var)),group=country)) +
    geom_line( aes(color=country),size=0.5, alpha=0.9) +
    geom_point(aes(color=country),size=1) + 
    
    labs(subtitle=paste("From",year1,"to",year2, sep=" "), 
         y=var, 
         x="Year", 
         title=paste("Evolution of",var,"for subject:",subject_choice, sep=" "))+
    
    theme_ft_rc()
  
  
  G1=ggplotly(G1,tooltip = c(''))
  G1
  
  
  
  
}

line_plot()


hist_plot<-function(Year=2012,var="hlo",countries= c("Sweden","Belgium","Norway"),subject_choice="math",Level="sec"){
  
 
  data= mydata%>% 
    replace(is.na(.), 0) %>% filter(year==Year)%>%filter(country %in%countries)%>%filter(subject==subject_choice) %>%filter(level==Level)
  
  G3=ggplot(data,aes(x=country,y=get(var),fill=country)) + 
    geom_col() +    
    labs(title=paste(var,"for selected countries,",Year, sep=" "), 
         y=var)+theme_ft_rc()+ylim(0,700)
  
  G3=ggplotly(G3,tooltip = c(''))
  G3
}



hist_plot()

map_plot<-function(variable="lays"){
 
  
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


ui <- fluidPage(
  
  mainPanel(
    fluidRow(
      align = "left",
      strong("Visualizations of Learning Outcomes: "),
      em( "This RShiny app provides simple visualizations of the HLO (Harmonized Learning Outcomes) Database as introduced by Angrist, N., Djankov, S., Goldberg, P.K. et al. (2021) and data 
      from the World Bank's Human Capital Project (2020). Graphs can only 
      be constructed if enough data points exist. The app is not adequately bug tested and all errors are my own.
         "),
      br(),
      code(""),
      br(),
    ), width = 12
  ),  mainPanel(
    fluidRow(
      align = "left",
      "         "
    ), width = 12
  ), fluidRow(
    column(5, 
           "",
           selectInput(
             "map_var", "Variable of interest",  c("Learning Adjusted Years of Schooling" = "lays",
                                                   "Expected Years of Schooling" = "eys",
                                                   "Harmonized Learning Outcome" = "hlo",
                                                   "Human Capital Index" = "HUMANCAPITALINDEX2020",
                                                   "Difference between EYS and LAYS" ="Diff_EYS_LAYS"),
             multiple =FALSE
           )
    )
    
  ),
  fluidRow(column(8, align="center", plotlyOutput("map_plot")
  )
    
  )
  
  ,fluidRow(
    column(5, 
           "",
           selectInput(
             "variable1", "Variable of interest",  c( "Harmonized Learning Outcome" = "hlo",
                                                      "Harmonized Learning Outcome (Male)" = "hlo_m",
                                                      "Harmonized Learning Outcome (Female)" = "hlo_f"),
             multiple =FALSE
           ),   selectInput(
             "school_level", "School Level", c( "Primary" = "pri","Secondary"="sec"),
             multiple = FALSE,selected="sec"
           ),  selectInput(
             "subject1", "Subject", subjects,
             multiple = FALSE
           ),
           selectInput(
             "countries1", "Countries", countries,
             multiple = TRUE,selected=c("Sweden","Belgium","Norway")
           ),
           sliderInput("years", "Years", value = c(2005,2015), min = 2000, max = 2016,step=1,sep = ""),
           
    ),  
    
    column(7, plotlyOutput("lineplot1")
    )
  ),  fluidRow(
    column(4, 
           "",
           selectInput(
             "variable2", "X variable",  c( "Harmonized Learning Outcome" = "hlo",
                                            "Harmonized Learning Outcome (Male)" = "hlo_m"),
             multiple = FALSE,selected="hlo_m"
           ), 
           selectInput(
             "variable3", "Y variable",  c( "Harmonized Learning Outcome" = "hlo",
                                            "Harmonized Learning Outcome (Female)" = "hlo_f"),
             multiple = FALSE,selected="hlo_f"
           ), 
           selectInput(
             "subject3", "Subject", subjects,
             multiple = FALSE
           ),
           selectInput(
             "country", "Country", countries,
             multiple = FALSE,selected=c("Sweden")
           ),
    ),
    column(8, plotlyOutput("plot2")
    )
  ), fluidRow(
    column(4, 
           "",
           selectInput(
             "variable5", "Variable of interest", c( "Harmonized Learning Outcome" = "hlo",
                                                     "Harmonized Learning Outcome (Male)" = "hlo_m",
                                                     "Harmonized Learning Outcome (Female)" = "hlo_f"),
             multiple = FALSE
           ),
           selectInput(
             inputId =  "year_choice1", 
             label = "Select time period:", 
             choices = 2000:2015
           ), 
           selectInput(
             "countries2", "Countries", countries,
             multiple = TRUE,selected=c("Sweden","Belgium","Norway")
           ),   selectInput(
             "school_level2", "School Level", levels,
             multiple = FALSE,selected="sec"
           ),  selectInput(
             "subject2", "Subject", subjects,
             multiple = FALSE,selected="math"
           ),
           
    ),column(8, plotlyOutput("plot3")
    )
  )
  
  
)


server <- function(input, output, session) {
  output$map_plot <- renderPlotly({
    req(c(input$map_var))
    map_plot(variable=input$map_var)
  })
  
  output$lineplot1 <- renderPlotly({
    req(c(input$variable1,input$years,input$countries1,input$school_level))
    line_plot(var=input$variable1,year1=round(input$years[1]),countries=input$countries1,year2=round(input$years[2]),Level=input$school_level,subject_choice = input$subject1)
  })
  output$plot2 <- renderPlotly({
    
    scatter_plot(Country=input$country,X=input$variable2,Y=input$variable3,Z=input$subject3)
  })
  
  output$plot3 <- renderPlotly({
    
    hist_plot(Year=input$year_choice1,var=input$variable5,countries=input$countries2,Level=input$school_level2,subject_choice = input$subject2)
    
  })
  
  
}



shinyApp(ui = ui, server = server)










