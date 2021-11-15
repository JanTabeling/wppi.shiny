library(tidyverse)
library(wppi)
library(igraph)
library(logger)

library(shiny)
library(shinyBS) # collapse panels
library(bsplus) # info tooltips
library(shinyjs) # enable/disable buttons
library(shinyFeedback) # loading button
library(shinyWidgets) # Reverse sliderInput
library(colourpicker) # Colour picker input
library(visNetwork)
library(DT)
library(waiter)

library(ipc)
library(future)
library(promises)
plan(multicore)

available_hpo_annots <- wppi_hpo_data() %>% 
  .$Name

BLCA_genes <- readRDS("data/BLCA_genes.rds")
OV_genes <- readRDS("data/OV_genes.rds")
PAAD_genes <- readRDS("data/PAAD_genes.rds")
THCA_genes <- readRDS("data/THCA_genes.rds")

create_size_legend <- function(scores, palette, colors, n_nodes = 7, direction = 1) {

  min_score <- scores$score %>% min()
  max_score <- scores$score %>% max()
  
  if (palette != "custom") {
    colors <- case_when(
      
      palette == "blue" ~ list(
        nodes = c(
          "#084081",
          "#0868ac",
          "#2b8cbe",
          "#4eb3d3",
          "#7bccc4",
          "#a8ddb5",
          "#ccebc5",
          "#e0f3db",
          "#f7fcf0"
        ),
        edges = c("#9b9b9b", "#ededed"),
        genes_interest = "#BE5D2B"
      ),
      
      palette == "red" ~ list(
        nodes = c(
          "#800026",
          "#bd0026",
          "#e31a1c",
          "#fc4e2a",
          "#fd8d3c",
          "#feb24c",
          "#fed976",
          "#ffeda0",
          "#ffffcc"
        ),
        edges = c("#9b9b9b", "#ededed"),
        genes_interest = "#00BD97"
      ),
      
      palette == "green" ~ list(
        nodes = c(
          "#00441b",
          "#006d2c",
          "#238b45",
          "#41ae76",
          "#66c2a4",
          "#99d8c9",
          "#ccece6",
          "#e5f5f9",
          "#f7fcfd"
        ),
        edges = c("#9b9b9b", "#ededed"),
        genes_interest = "#AE4179"
      ),
      
      palette == "orange" ~ list(
        nodes = c(
          "#662506",
          "#993404",
          "#cc4c02",
          "#ec7014",
          "#fe9929",
          "#fec44f",
          "#fee391",
          "#fff7bc",
          "#ffffe5"
        ),
        edges = c("#9b9b9b", "#ededed"),
        genes_interest = "#1490EC"
      ),
      
      TRUE ~ list(
        nodes = c(
          "#FDE725",
          "#8FD744",
          "#35B779",
          "#22908C",
          "#30688E",
          "#443A83",
          "#440D54"
        ),
        edges = c("#9b9b9b", "#ededed"),
        genes_interest = "#FF0000"
      )
      
    )
    
    names(colors) <- c("nodes", "edges", "genes_interest")
  }
  
  node_color_gradient_fn <- colorRampPalette(colors$nodes)
  
  nodes <- data.frame(
    id = 1:n_nodes,
    score = seq.int(max_score, min_score, length.out = n_nodes),
    color = node_color_gradient_fn(n_nodes),
    shape = "dot"
  ) %>% 
    mutate(
      label = score %>% round(3),
      size = (score * 8 + 1) * 10
    ) %>% 
    rbind.data.frame(
      data.frame(
        id = "gene_of_interest",
        score = 1,
        color = colors$genes_interest,
        shape = "diamond",
        label = "gene of interest",
        size = 15
      )
    )
  
  dist_between_nodes <- (1000 - 2 * sum(nodes$size) + head(nodes$size, 1) + tail(nodes$size, 1)) / (nrow(nodes) - 1)

  x <- c(0)
  for (i in 1:nrow(nodes)-1) {
    x_next <- x[i] - nodes$size[i] - dist_between_nodes - nodes$size[i+1]
    
    x <- c(x, x_next)
  }
  
  
  nodes$x <- if (direction == 1) x else rep(0, times = nrow(nodes))
  nodes$y <- if (direction == 1) rep(0, times = nrow(nodes)) else -x
  
  nodes %>% 
    visNetwork() %>% 
    visNodes(
      color = list(
        background = "white",
        border = "black"
      )
    ) %>% 
    visPhysics(enabled = FALSE) %>% 
    visEdges(smooth = FALSE) %>% 
    visInteraction(
      dragNodes = FALSE,
      dragView = FALSE,
      zoomView = FALSE
    )
  
}