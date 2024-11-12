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
library(data.table)
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

effort_regional_ts <- qs::qread("/home/ubuntu/gem/private/users/yannickr/DKRZ_EffortFiles/effort_histsoc_1841_2017_regional_models.qs") %>%
  filter(region != "") %>%
  mutate(NomActive = as.numeric(NomActive))


catch_regional_ts <- qs::qread("/home/ubuntu/gem/private/users/yannickr/DKRZ_EffortFiles/calibration_catch_histsoc_1850_2017_regional_models.qs") %>%
  mutate(catch = Reported + IUU + Discards) # why doesn't this have gear? 

region_keys <- unique(effort_regional_ts$region)

# Define variables for each dataset type
effort_variables <- c("FGroup", "Sector", "Gear")
catch_variables <- c("FGroup", "Sector")  # without "Gear"

# Define user interface ------------------------------------------------------
## Global UI -------------------------------------------------------------------
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
                 
                 # Choose catch or effort data
                 p("1. Select dataset to view:"),
                 selectInput(inputId = "catch_effort_select", label = NULL,
                             choices = c("Effort", "Catch"), 
                             selected = "Effort"),
                 
                 # Choose region of interest
                 p("2. Select a FishMIP region:"),
                 selectInput(inputId = "region_gfdl", label = NULL,
                             choices = region_keys, 
                             selected = "East Bass Strait"),
                 
                 # Choose variable of interest
                 p("3. Select dimension:"),
                 selectInput(inputId = "variable_effort", 
                             label = NULL,
                             choices = effort_variables,
                             selected = "FGroup"),
                 
                 # Inline layout for download button
                 fluidRow(
                   column(6, p("4. Download the displayed data:")),
                   column(6, downloadButton(outputId = "download_data", 
                                            label = "Download Data"))
                 )
               ),
               mainPanel(
                 tabPanel("",
                          mainPanel(
                            br(), 
                            withLoader(plotlyOutput(outputId = "ts_effort", width = "100%", height = "500px"),
                                       type = "html")
                          )
                 )
               )
             )
    )
  )
)


# Define actions ---------------------------------------------------------------
# Server code
server <- function(input, output, session){
  
  # Update `variable_effort` choices based on dataset selection
  observeEvent(input$catch_effort_select, {
    new_choices <- if (input$catch_effort_select == "Effort") effort_variables else catch_variables
    updateSelectInput(session, "variable_effort", choices = new_choices, selected = new_choices[1])
  })
  
  # Loading relevant data based on selection
  selected_data <- reactive({
    if (input$catch_effort_select == "Effort") {
      effort_regional_ts
    } else {
      catch_regional_ts
    }
  })
  
  # Filtered data for plotting and downloading
  filtered_data <- reactive({
    req(selected_data()) # Ensure data is available
    #validate(need(nrow(selected_data()) > 0, "No data available for this selection.")) # Provide feedback if data is empty
    selected_data() %>%
      filter(region == input$region_gfdl) %>%
      group_by(Year, region, !!sym(input$variable_effort)) %>%
      summarise(value = ifelse(input$catch_effort_select == "Effort",
                               sum(NomActive, na.rm = TRUE),
                               sum(catch, na.rm = TRUE))) %>%
      ungroup() %>%
      filter(value > 0, Year >= 1950) %>%
      mutate(Information = glue("<br>Year: {Year}<br>{input$variable_effort}: {get(input$variable_effort)}<br>Value: {value}"))
  })
  
  output$ts_effort <- renderPlotly({
    # Plotting data
    df <- filtered_data() %>%
      group_by(region, !!sym(input$variable_effort)) %>%
      complete(Year = full_seq(Year, 1), fill = list(value = 0)) %>%
      ungroup()
    
    # Define y-axis label based on dataset choice
    y_axis_label <- if (input$catch_effort_select == "Effort") "Nominal Fishing Hours" else "Catch (tonnes)"
    
    # Create ggplot
    p <- ggplot(df, aes(x = Year, y = value, fill = !!sym(input$variable_effort), label = Information)) +
      geom_area(stat = "identity", alpha = 0.85, na.rm = TRUE) +
      prettyts_theme +
      labs(y = y_axis_label, x = "Year")
    
    # Convert ggplot to an interactive plot with ggplotly
    ggplotly(p, tooltip = 'label') %>%
      layout(
        height = 600,
        width = 800,
        legend = list(
          orientation = "h",
          xanchor = "center",
          x = 0.5,
          yanchor = "top",
          y = -0.2,
          font = list(size = 10),
          traceorder = "normal"
        ),
        legendtitle = list(text = ""),
        margin = list(l = 20, r = 20, t = 20, b = 20)
      )
  })
  
  output$download_data <- downloadHandler(
    filename = function() {
      paste("filtered_data_", input$region_gfdl, ".csv", sep = "")
    },
    content = function(file) {
      data <- filtered_data() %>%
        mutate(data_type = input$catch_effort_select) %>%
        dplyr::select(-Information)
      validate(need(nrow(data) > 0, "No data available for download."))
      write.csv(data, file, row.names = FALSE)
    }
  )
}

shinyApp(ui = ui, server = server)
