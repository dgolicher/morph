#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Eelgrass available biomass"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
       sliderInput("Month",
                   "Month:",
                   min = 1,
                   max = 12,
                   value = 1),
       sliderInput("Day",
                   "Day:",
                   min = 1,
                   max = 31,
                   value = 20),
       sliderInput("Hour",
                   "Hour:",
                   min = 0,
                   max = 23,
                   value = 1),
       sliderInput("Height",
                   "Height in meters:",
                   min = 0,
                   max = 1,
                   value = 0.2,
                   step =0.1),
       sliderInput("Depth",
                   "Depth in meters (negative):",
                   min = -1,
                   max = 0,
                   value = -0.5,
                   step =0.1)
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
       plotOutput("distPlot"),
       tableOutput('tides')
    )
  )
))
