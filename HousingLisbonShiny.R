defaultEncoding <- 'UTF-16'
library(shiny)
library(rgdal)
library(dplyr)
library(shinydashboard)
library(leaflet)
library(leaflet.extras)
library(DT)
library(rsconnect)
library(ggplot2)
library(wrapr)
library(grr)

#LOADING DATA
#load cleaned Casa Sapo data - used for Choropleth map
Sapo <- read.csv('avg_price_PerSqm_SAPO.csv',header=TRUE, sep=",", encoding = defaultEncoding)
#load Casa Sapo distribution data
DistData <- read.csv('SapoDistData.csv')
#Lisbon shape file
LisbonMap <- readOGR('Freguesias2012/Freguesias2012.shp')


countrypolygons.df <- as.data.frame(LisbonMap$polygons)
#match data from Sapo (Parish) with Lisbon shapefile (NOME)
MatchedData <- Sapo[order(matches(Sapo$Parish, LisbonMap$NOME)),]

#Bins for choropleth
bins <- c(3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
#pal <- colorNumeric('viridis', domain = c(0, 12)) #, bins = bins)
pal <- colorBin('viridis', domain = c(0, 12), bins=bins) #, bins = bins)


#UI - DASHBOARD
ui <- dashboardPage(
  skin = 'yellow',
  dashboardHeader(title='Lisbon Housing Price Overview',titleWidth = 300),
  dashboardSidebar(
    selectInput('dataMeasure', 'Nbr. Rooms', choices=c(#'Studio' = 0,
                                                       'T1' = 1,
                                                       'T2' = 2,
                                                       'T3' = 3,
                                                       'T4' = 4), selected=1),
                                                     #  'T5' = 5), selected=0),
    selectInput('distMeasure', 'Select A Parish to Compare', choices=as.vector(DistData['Parish']), 
                selected=1)
  ),
  dashboardBody(
    fluidRow(
      column(width = 11,
             #Leaflet Map
             box(width = NULL, solidHeader = TRUE,
                 leafletOutput('LisbonMap', height=350)
             ),
             #dist plot
             box(width=NULL,
                 plotOutput('DistPlot', height=300)
             ),
             #dist plot
             box(width=NULL,
                 plotOutput('DistPlotComp', height=300)
             )
      )
    )
  )
)


#SERVER
server <- function(input, output, session){
  #Data used for Choropleth Map
  data_input <- reactive({
    MatchedData %>%
    filter(NbrBedrooms == input$dataMeasure) #%>%
      
  })

  #align data
  data_input_ordered <- reactive({
    data_input()[order(match(data_input()$Parish, LisbonMap$NOME)),] #%>%
  })
  
  #Map labels when hovered over
  labels <- reactive({
    paste('<p>', '<b>', 'Parish: ', data_input_ordered()$Parish , '</b>', '<p>',
          '<p>', '<b>', 'Price Per m2 (€): ', round(data_input_ordered()$PriceSqM, 2) ,'K','</b>', '<p>')
  })
  
  #Choropleth output map
  output$LisbonMap <- renderLeaflet({
    leaflet() %>%
      setView(-9.179, 38.735, 12) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addPolygons(data = LisbonMap, 
                  layerId=~NOME,
                  weight = 1, 
                  smoothFactor = 0.5, 
                  color='white', 
                  fillOpacity = 0.87,
                  fillColor = pal(data_input_ordered()$PriceSqM),
                  highlightOptions = highlightOptions(color = "black", weight = 3,
                                                      bringToFront = TRUE),
                  label = lapply(labels(), HTML)) %>%
      addLegend(pal = pal,
                title = "Price/m2 Ranges",
                values = data_input_ordered()$PriceSqM,
                opacity = 0.7,
                position = 'topright')
  
      
  })
  
  #update the location selectInput on map clicks
  observeEvent(input$LisbonMap_shape_click, {
    clickedParish <- input$LisbonMap_shape_click$id
  }) 
  
  #data used for distribution plot
  plot_input <- reactive({
    DistData %>%
      filter(NbrBedrooms == input$dataMeasure) %>%
      filter(Parish == input$LisbonMap_shape_click$id)
  })
  
  #Distribution output
  output$DistPlot <- renderPlot({
    if(is.null(input$LisbonMap_shape_click$id)) { 
      validate(
        need(input$LisbonMap_shape_click$id != 0, 
             "Please click on a Parish on the map to view it's price distribution")
      )} 
    else {
    ggplot(plot_input(), aes(x=plot_input()$price)) +
      geom_histogram(bins = 20,
                     fill = 'steelblue3',
                     colour = 'grey30') +
      labs(title = input$LisbonMap_shape_click$id,
           subtitle = sprintf('Total listings: %s.', nrow(plot_input())),
           caption = "Source: CASA SAPO website listings, Feb. 2019", 
           x = 'Price Range (in Ks €)', y = 'Number of listings') +
     # theme(plot.title = element_text(lineheight=.8, face="bold")) + 
      theme_minimal()
      }
  })
  
  #data used for comparison distribution plot
  plot_input_compare <- reactive({
    DistData %>%
      filter(NbrBedrooms == input$dataMeasure) %>%
      filter(Parish == input$distMeasure)
  })
  
  #comparison distribution plot
  output$DistPlotComp <- renderPlot({
    ggplot(plot_input_compare(), aes(x=plot_input_compare()$price)) +
      geom_histogram(bins = 20,
                     fill = 'orange',
                     colour = 'black') +
      labs(title = sprintf('Compare: %s', input$distMeasure),
           subtitle = sprintf('Total listings: %s.', nrow(plot_input_compare())),
           caption = "Source: CASA SAPO website listings, Feb. 2019", 
           x = 'Price Range (in Ks €)', y = 'Number of listings') +
      theme_minimal()
  })

} 

shinyApp(ui, server)
