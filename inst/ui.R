ui <- tagList(
  
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "ui.css")
  ),
  
  useShinyjs(),
  useWaiter(),
  
  fluidPage(
    
    titlePanel("wppi web application"),
    
    sidebarPanel(
      
      selectizeInput(
        "example",
        label = "",
        choices = c(
          "Ovarian Cancer",
          "Pancreatic Adenocarcinoma",
          "Thyroid Cancer",
          "Urothelial Bladder Carcinoma"
        ),
        options = list(
          placeholder = 'Choose an example',
          onInitialize = I('function() { this.setValue(""); }')
        )
      ),
      
      textAreaInput(
        "genes_interest",
        label = "Genes of interest",
        value = "",
        height = "100px",
        resize = "vertical"
      ),
      
      bsCollapse(id = "settings_panels",
        bsCollapsePanel(
          "Human Phenotype Ontology settings",
          style = "info",
          
          fluidRow(
            column(8,
                   selectizeInput(
                     inputId = "HPO_interest",
                     label = "Annotations of interest",
                     choices = NULL,
                     multiple = TRUE,
                     width = "100%"
                   )
            ),
            column(4,
                   checkboxInput(
                     "HPO_annot",
                     label = "Use annotation database for weights",
                     value = TRUE,
                     width = "100%"
                   )
            )
          )
        ),
        
        bsCollapsePanel(
          "Gene Ontology settings",
          style = "info",
          
          fluidRow(
            column(6,
                   selectInput(
                     "GO_organism",
                     label = "Organism",
                     choices = c(
                       "human",
                       "chicken",
                       "cow",
                       "dog",
                       "pig",
                       "all" # uniprot_all
                     ),
                     width = "100%"
                   ),
                   checkboxInput(
                     "GO_use_slim",
                     label = "Use GO slim",
                     width = "100%"
                   )
            ),
            column(6,
                   selectInput(
                     "GO_aspects",
                     label = "Aspects",
                     choices = c(
                       "all",
                       "cellular component",
                       "molecular function",
                       "biological process"
                     ),
                     width = "100%"
                   ),
                   checkboxInput(
                     "GO_annot",
                     label = "Use annotations database for weights",
                     value = TRUE,
                     width = "100%"
                   )
            )
          ),
          
          selectInput(
            "GO_slim",
            label = "Slim",
            choices = c(
              "Generic",
              "AGR",
              "Aspergillus",
              "Andida",
              "Drosophila",
              "chEMBL",
              "Metagenomic",
              "Mouse",
              "Plant",
              "PIR",
              "Schizosaccharomyces pombe",
              "Yeast"
            ),
            width = "100%"
          ) %>% shinyjs::hidden(),
          
          p(
            HTML(
              "<i>For more details on Gene Ontology subsets, see <a href='http://geneontology.org/docs/go-subset-guide/' target='_blank'>geneontology.org</a></i>"
            )
          )
          
        ),
        
        bsCollapsePanel(
          "Omnipath settings",
          style = "info",
          
          selectizeInput(
            "omnipath_organism",
            label = "Organism",
            choices = c("human", "rat", "mouse"),
            selected = "human",
            width = "100%"
          ),
          
          selectizeInput(
            "omnipath_resources",
            label = "Exclude resources",
            choices = c(
              "omnipath",
              "kinaseextra",
              "pathwayextra",
              "ligrecextra",
              "dorothea",
              "tf_target",
              "tf_mirna",
              "mirnatarget",
              "lncrna_mrna"
            ),
            multiple = TRUE,
            selected = NULL,
            width = "100%"
          )
        ),
        
        bsCollapsePanel(
          "Random Walk settings",
          style = "info",
          
          fluidRow(
            column(6,
                   numericInput(
                     "restart_prob_rw",
                     label = "Restart prob.",
                     value = 0.4,
                     min = 0,
                     max = 1,
                     step = 0.1,
                     width = "100%"
                   )
            ),
            column(6,
                   numericInput(
                     "threshold_rw",
                     label = "Threshold",
                     value = 0.00001,
                     min = 0,
                     max = 1,
                     step = 0.00001
                   )
            )
          )
          
        ),
        
        
        bsCollapsePanel(
          "Other settings",
          style = "info",
          
          fluidRow(
            column(6,
                   numericInput(
                     inputId = "percentage_output_genes",
                     label = "% output genes",
                     value = 100,
                     min = 0,
                     max = 100,
                     step = 1,
                     width = "100%"
                   )
            ),
            column(6,
                   numericInput(
                     inputId = "graph_order",
                     label = "Graph order",
                     value = 1,
                     min = 1,
                     max = 10,
                     step = 1,
                     width = "100%"
                   )
            )
          )
          
        ),
        
        bsCollapsePanel(
          "Colour settings",
          style = "info",
          
          fluidRow(
            column(6, 
                   selectInput(
                     inputId = "vis_palette",
                     label = "Palette",
                     choices = c(
                       "default", 
                       "blue", 
                       "green", 
                       "red", 
                       "orange", 
                       "custom"
                     ),
                     width = "100%"
                   ),
                   colourInput(
                     inputId = "vertex_col_low",
                     label = "Vertex low score",
                     value = "#f7fcf0"
                   ) %>% 
                     disabled(),
                   colourInput(
                     inputId = "edge_col_low",
                     label = "Edge low score",
                     value = "#ededed"
                   ) %>% 
                     disabled()
            ),
            column(6,
                   colourInput(
                     inputId = "gene_of_interest_col",
                     label = "Gene of interest",
                     value = "#BE5D2B"
                   ) %>% 
                     disabled(),
                   colourInput(
                     inputId = "vertex_col_high",
                     label = "Vertex high score",
                     value = "#084081"
                   ) %>% 
                     disabled(),
                   colourInput(
                     inputId = "edge_col_high",
                     label = "Edge high score",
                     value = "#9b9b9b"
                   ) %>% 
                     disabled()
            )
          )
        )
      ),
      
      fluidRow(
        column(6,
               style = "padding-right: 2px;",
               loadingButton(
                 "calculate_scores",
                 label = "Calculate scores",
                 class = "btn btn-primary",
                 style = "width: 100%;"
               )
        ),
        column(6,
               style = "padding-left: 2px;",
               actionButton(
                 "cancel_calculation",
                 label = "Cancel",
                 class = "btn-danger",
                 width = "100%"
               ) %>% 
                 shinyjs::disabled()
        )
      ),
      fluidRow(
        style = "margin-top: 5px;",
        column(12,
               downloadButton(
                 "download_scores",
                 label = "Download scores",
                 class = "btn-secondary",
                 style = "width: 100%"
               )
        )
      )
    ),
    
    mainPanel(
      tabsetPanel(
        
        tabPanel(
          "Graph",
          
          sliderTextInput(
            inputId = "filter_edges",
            label = "Only show edges with score in upper %",
            choices = seq(from = 100, to = 0, by = -1),
            selected = 0,
            width = "100%",
            post = " %"
          ),
          
          visNetworkOutput(
            "sub_graph_vis",
            height = "500px"
          ),
          
          h5("Score legend", id = "score_text", style = "text-align: center;") %>% 
            shinyjs::hidden(),
          
          visNetworkOutput(
            "node_size_legend",
            height = "100px"
          )
          
        ),
        
        tabPanel(
          "Scores",
          DT::dataTableOutput("scores_dt")
        )
        
      )
    )
  )
  
)