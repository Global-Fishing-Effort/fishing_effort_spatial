library(arrow)
library(shiny)
library(shinyWidgets)
library(shinycustomloader)
library(readr)
library(bslib)
library(tibble)
library(stringr)
library(dplyr)
library(rnaturalearth)
library(tidyr)
library(sf)
library(ggplot2)
library(plotly)
library(glue)
library(qs)
library(here)
options(scipen = 99)

prettyts_theme <- list(theme_bw(),
                       theme(axis.text.y = element_text(size = 14),
                             axis.text.x = element_text(angle = 45, vjust = 1, 
                                                        hjust = 1, size = 14),
                             axis.title.y = element_text(size = 15), 
                             axis.title.x = element_blank(),
                             plot.title = element_text(hjust = 0.5, size = 18),
                             legend.position = "bottom", 
                             legend.text = element_text(size = 18)))

effort_regional_ts <- qs::qread(here("data/fishmip/regional_effort_old.qs"))


region_keys <- unique(effort_regional_ts$region)

effort_variables <- c("Sector", "FGroup", "Gear")

# Defining user interface ------------------------------------------------------
## Global UI -------------------------------------------------------------------
# Replace plotOutput with plotlyOutput in the UI
ui <- fluidPage(
  theme = bs_theme(bootswatch = "materia"),
  titlePanel(title = span(
    h1("Regional Climate Forcing Data Explorer",
       style = "color: #095c9e; background-color:#f3f3f3; 
                             border:1.5px solid #c9d5ea; 
                             padding-left: 15px; padding-bottom: 10px; 
                             padding-top: 10px;
                             text-align: center; font-weight: bold")),
    windowTitle = "FishMIP Regional Climate Forcing Data Explorer"),
  ## Model tab -----------------------------------------------------------------
  tabsetPanel(
    tabPanel("Regional fishing effort data",
             sidebarLayout(
               sidebarPanel(
                 h4(strong("Instructions:")),
                 
                 # Choose region of interest
                 p("1. Select a FishMIP region:"),
                 selectInput(inputId = "region_gfdl", label = NULL,
                             choices = region_keys, 
                             selected = "East.Bass.Strait"),
                 
                 # Choose variable of interest
                 p("2. Select dimension:"),
                 selectInput(inputId = "variable_effort", 
                             label = NULL,
                             choices = effort_variables,
                             selected = "FGroup"),
                 
               ),
               mainPanel(
                 tabPanel("Time series plot",
                          mainPanel(
                            br(), 
                               plotlyOutput(outputId = "ts_effort", 
                                            width = "100%", height = "500px"))
                             #plotOutput(outputId = "ts_effort", 
                              #            width = "100%"))
                          
                 )
               )
             )
    )
    
  )
)


# Define actions ---------------------------------------------------------------
# Server code

server <- function(input, output, session){
  
  
  # Loading relevant data
  gfdl_data <- reactive({
    # Loading time series dataset
    df_ts <- effort_regional_ts
    return(list(df_ts = df_ts))
  })
  
  gfdl_ts_df <- reactive({
    df <- gfdl_data()$df_ts
    
    title <- paste0("Reconstructed effort data 1841-2017") 
    
    return(list(df = df, title = title))
  })
  
output$ts_effort <-  # renderPlot({
   renderPlotly({
  
  df <- gfdl_ts_df()$df %>%
    filter(region == input$region_gfdl) %>%
    group_by(Year, region, !!sym(input$variable_effort)) %>%
    summarise(NomActive = sum(NomActive, na.rm = TRUE)) %>%
    ungroup() %>%
    filter(NomActive > 0, 
           Year >= 1950) %>%
    mutate(Information = glue("<br>Year: {Year}<br>{input$variable_effort}: {get(input$variable_effort)}<br>NomActive: {NomActive}"))
  

  # Create ggplot
  p <- ggplot(df, aes(x = Year, y = NomActive, fill = !!sym(input$variable_effort), label = Information
                      )) +
     geom_area(stat = "identity") +
    prettyts_theme +
    labs(y = "Nominal Fishing Hours", x = "Year")

  # Convert ggplot to an interactive plot with ggplotly
   ggplotly(p, tooltip = 'label') %>%
     layout(
       height = 600,
       width = 800,
       legend = list(
         orientation = "h",  # Horizontal orientation
         xanchor = "center", # Center horizontally
         x = 0.5,            # Positioning on x-axis
         yanchor = "top",    # Anchor at the top
         y = -0.2,           # Adjust the y position to avoid overlap with the plot
         font = list(size = 10),  # Adjust legend font size
         traceorder = "normal"  # Ensure legend items appear in the order of appearance in the plot
       ),
       legendtitle = list(text = ""),  # If you have a legend title, set it or leave empty
       margin = list(l = 20, r = 20, t = 20, b = 20)  # Adjust margins if necessary
     )
  #p 
})
# , height = 500, width = 800)
  
  
}

shinyApp(ui = ui, server = server)

