library(shiny)
library(plotly)
library(dplyr)
library(ggplot2)
library(tidyverse)

path <- "data/data_cleaned.csv/"
data_sets <- c('gambling_category_cleaned', 'recomm_streams_cleaned', 'streamer_information_cleaned', 'top_category_cleaned')

for (set in data_sets) {
# Remove "_cleaned" from the file name
  file_name <- gsub("_cleaned", "", set)

# Read the CSV file and assign it to a variable with the modified file name
  assign(file_name, read_csv(paste0(path, set, ".csv")))
}

# set the files to the correct format
gambling_category <- gambling_category %>%
  mutate(across(c(Subcategory), as.factor))

recomm_streams <- recomm_streams %>%
  mutate(across(c(Streamer_Secret,Category), as.factor))

streamer_information <- streamer_information %>%
  mutate(across(c(Streamer_Secret,Subcategory,Language),as.factor))

top_category <- top_category %>%
  mutate(across(c(Category,Subcategory),as.factor))

# Define a function to calculate mean and standard deviation of viewer count
avg_viewercount <- function(data, category_col) {
  agg_data <- data %>%
    group_by(.data[[category_col]]) %>%
    summarise(mean_viewercount = mean(Viewercount),
              sd_viewercount = sd(Viewercount)) %>%
    ungroup()
  
  return(agg_data)
}

# Define UI
ui <- fluidPage(
  titlePanel("Combined Shiny App"),
  sidebarLayout(
    sidebarPanel(
      # Dropdown menu for dataset selection in the first app
      selectInput("categoryType", "Cool Descriptive Plots", choices = c("Subcategory", "Category"), selected = "Subcategory"),
      # Dropdown menu for dataset selection in the second app
      selectInput("dataset", "Select Dataset:",
                  choices = c('top_category', 'streamer_information', 'gambling_category', 'recomm_streams')),
      # Dropdown menu for column format selection in the second app
      selectInput("format", "Select Column Format:",
                  choices = c('factor', 'numeric', 'POSIX')),
      # Conditional rendering of dropdown menus based on selected format in the second app
      uiOutput("column_selector", label = "Select Column"),
      # Dropdown menu for pie chart selection
      selectInput("pie_chart_type", "Select Pie Chart Type:",
                  choices = c("Languages" = "pie_chart_languages",
                              "Subcategories" = "pie_chart_subcategories",
                              "Top Streamers" = "pie_chart_meanviews"))
    ),
    mainPanel(
      # Output plot for the first app
      plotlyOutput("categoryPlot"),
      # Output for the second app
      uiOutput("output"),
      # Output for pie chart
      plotlyOutput("pie_chart_output")
    )
  )
)

# Define server logic
server <- function(input, output) {
  
  # Output for the first app's plot
  output$categoryPlot <- renderPlotly({
    category_col <- input$categoryType
    
    # Select data based on category type
    data <- if (category_col == "Subcategory") gambling_category else top_category
    
    # Calculate average viewer count for each category
    avg_data <- avg_viewercount(data, category_col)
    
    # Plot
    p <- ggplot(avg_data, aes(x = .data[[category_col]], y = mean_viewercount, fill = .data[[category_col]])) +
      geom_bar(stat = "identity", position = "dodge") +
      geom_errorbar(aes(ymin = mean_viewercount - sd_viewercount, ymax = mean_viewercount + sd_viewercount), position = "dodge", width = 0.4) +
      labs(x = category_col, y = "Average Viewercount", fill = category_col) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 90, hjust = 1))  # Rotate x-axis labels
    
    ggplotly(p, tooltip = c("x", "y", "text"))  # Convert ggplot to plotly with category, viewer count, and tooltip
  })
  
  # Render dropdown menu for selecting columns based on selected format
  output$column_selector <- renderUI({
    # Get selected dataset
    selected_data <- get(input$dataset, envir = .GlobalEnv)
    
    if (input$format == "factor") {
      # Filter columns that are formatted as factors
      factor_cols <- names(selected_data)[sapply(selected_data, is.factor) & names(selected_data) != "Streamer_Secret"]
      # Create dropdown menu for factor columns with scrolling option
      selectInput("column", "Select Factor Column:", choices = factor_cols)
    } else if (input$format == "numeric") {
      # Filter columns that are formatted as numeric
      numeric_cols <- names(selected_data)[sapply(selected_data, is.numeric)]
      # Create dropdown menu for numeric columns
      selectInput("column", "Select Numeric Column:", choices = numeric_cols)
    } else if (input$format == "POSIX") {
      # Filter columns that are formatted as POSIXct
      posix_cols <- names(selected_data)[sapply(selected_data, is.POSIXct)]
      # Create dropdown menu for POSIX columns
      selectInput("column", "Select POSIX Column:", choices = posix_cols)
    }
  })
  
  # Render plot for factor columns
  output$output <- renderUI({
    # Get selected dataset
    selected_data <- get(input$dataset, envir = .GlobalEnv)
    
    # Check the selected column format and render plot or summary table accordingly
    if (input$format == "factor") {
      # Check if a factor column is selected
      if (!is.null(input$column)) {
        # Create a bar plot with plotly for factor columns
        plotlyOutput("factor_plot")
      }
    } else if (input$format == "numeric") {
      # Check if a numeric column is selected
      if (!is.null(input$column)) {
        # Create a summary table for the selected numeric column
        tableOutput("numeric_table")
      }
    } else if (input$format == "POSIX") {
      # Check if a POSIX column is selected
      if (!is.null(input$column)) {
        # Create a line plot for POSIX columns
        plotlyOutput("posix_plot")
      }
    }
  })
  
  # Render plot for factor columns using plotly
  output$factor_plot <- renderPlotly({
    # Get selected dataset
    selected_data <- get(input$dataset, envir = .GlobalEnv)
    
    # Check if a factor column is selected
    if (!is.null(input$column)) {
      # Create a bar plot with plotly for factor columns
      plot_ly(selected_data, x = ~get(input$column),  color = ~get(input$column), type = 'histogram') %>%
        layout(barmode = 'group', 
               xaxis = list(title = input$column),
               yaxis = list(title = 'Count'))
      
    }
  })
  
  
  # Render table for numeric columns
  output$numeric_table <- renderTable({
    # Get selected dataset
    selected_data <- get(input$dataset, envir = .GlobalEnv)
    
    # Check if a numeric column is selected
    if (!is.null(input$column)) {
      # Create a summary table for the selected numeric column
      summary_table <- selected_data %>%
        summarise(
          Maximum = max(!!sym(input$column)),
          Minimum = min(!!sym(input$column)),
          Mean = mean(!!sym(input$column)),
          Standard_Deviation = sd(!!sym(input$column)),
          Median = median(!!sym(input$column)),
          Percentile_25 = quantile(!!sym(input$column), 0.25),
          Percentile_75 = quantile(!!sym(input$column), 0.75)
        )
      summary_table
    }
  })
  
  # Render plot for POSIX columns
  output$posix_plot <- renderPlotly({
    selected_data <- get(input$dataset, envir = .GlobalEnv)
    ggplot(selected_data, aes(timestamp_of_extraction, Viewercount)) +
      geom_line() +
      labs(title = "Total ViewerCount per Day",
           x = "Date",
           y = "Total ViewerCount")
    
  })
  
  # Render pie chart based on selection
  output$pie_chart_output <- renderPlotly({
    pie_chart <- switch(input$pie_chart_type,
                        "pie_chart_languages" = {
                          language_counts <- streamer_information %>%
                            group_by(Language) %>%
                            summarise(count = n())
                          plot_ly() %>%
                            add_pie(labels = as.factor(language_counts$Language), values = language_counts$count, textinfo = 'none') %>%
                            layout(title = "Number of Streamers Speaking Each Language")
                        },
                        "pie_chart_subcategories" = {
                          category_counts <- streamer_information %>%
                            group_by(Subcategory) %>%
                            summarise(count = n())
                          plot_ly() %>%
                            add_pie(labels = as.factor(category_counts$Subcategory), values = category_counts$count, textinfo = 'none') %>%
                            layout(title = "Number of Times Streamers Stream a Given Category")
                        },
                        "pie_chart_meanviews" = {
                          streamer_avg_viewercount <- streamer_information %>%
                            select(Streamer_Secret, Viewercount) %>%
                            group_by(Streamer_Secret) %>%
                            summarise(mean_viewercount = mean(Viewercount))
                          top_streamers <- streamer_avg_viewercount %>%
                            top_n(10, mean_viewercount) %>%
                            arrange(desc(mean_viewercount))
                          plot_ly(data = top_streamers, labels = ~Streamer_Secret, values = ~mean_viewercount, type = 'pie') %>%
                            layout(title = "Top 10 Streamers with Highest Average Watch Count", showlegend=FALSE) %>%
                            add_pie(textinfo = 'none')
                        }
    )
    
    pie_chart
  })
}

# Run the application
shinyApp(ui = ui, server = server)


