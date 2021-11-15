server <- function(input, output, session) {
  
  shinyjs::hide("filter_edges")
  
  zoom_overlay <- Waiter$new(
    id = "sub_graph_vis",
    html = h4("Scroll to zoom", style = "color: black"),
    color = waiter::transparent(.5)
  )
  
  download_overlay <- Waiter$new(
    html = h4("Preparing download", style = "color: black"),
    color = waiter::transparent(.5)
  )
  
  rv <- reactiveValues(
    running = FALSE,
    zoom_shown = FALSE
  )
  
  updateSelectizeInput(
    session,
    inputId = "HPO_interest",
    choices = available_hpo_annots,
    server = TRUE
  )
  
  # Choosing an example updates the inputs ----
  observeEvent(input$example, {
    
    if (input$example == "Ovarian Cancer") { # OV
      
      updateTextAreaInput(
        session,
        "genes_interest",
        value = OV_genes %>% paste(collapse = ", ")
      )
      
      updateSelectizeInput(
        session,
        "HPO_interest",
        choices = available_hpo_annots,
        selected = c(
          "Ovarian carcinoma", 
          "Ovarian neoplasm", 
          "Ovarian serous cystadenoma"
        ),
        server = TRUE
      )
      
      updateCollapse(session, "settings_panels", open = "Human Phenotype Ontology settings")
      
    } else if (input$example == "Pancreatic Adenocarcinoma") { # PAAD
      
      updateTextAreaInput(
        session,
        "genes_interest",
        value = PAAD_genes %>% paste(collapse = ", ")
      )
      
      updateSelectizeInput(
        session,
        "HPO_interest",
        choices = available_hpo_annots,
        selected = c(
          "Pancreatic adenocarcinoma",
          "Pancreatic endocrine tumor",
          "Pancreatic squamous cell carcinoma"
        ),
        server = TRUE
      )
      
      updateCollapse(session, "settings_panels", open = "Human Phenotype Ontology settings")
      
    } else if (input$example == "Thyroid Cancer") { # THCA
      
      updateTextAreaInput(
        session,
        "genes_interest",
        value = THCA_genes %>% paste(collapse = ", ")
      )
      
      updateSelectizeInput(
        session,
        "HPO_interest",
        choices = available_hpo_annots,
        selected = c(
          # "Anaplastic thyroid carcinoma", not available
          "Medullary thyroid carcinoma",
          "Neoplasm of the thyroid gland",
          "Non-medullary thyroid carcinoma",
          "Papillary thyroid carcinoma",
          "Thyroid carcinoma"
        ),
        server = TRUE
      )
      
      updateCollapse(session, "settings_panels", open = "Human Phenotype Ontology settings")
      
    } else if (input$example == "Urothelial Bladder Carcinoma") { # BLCA
      
      updateTextAreaInput(
        session,
        "genes_interest",
        value = BLCA_genes %>% paste(collapse = ", ")
      )
      
      updateSelectizeInput(
        session,
        "HPO_interest",
        choices = available_hpo_annots,
        selected = c(
          "Bladder carcinoma"
        ),
        server = TRUE
      )
      
      updateCollapse(session, "settings_panels", open = "Human Phenotype Ontology settings")
      
    }
    
  })
  
  # If an example is chosen and the input genes of interest match, 
  # load the corresponding scores and visualisation ----
  observe({
    
    if ( # OV
      input$example == "Ovarian Cancer" && 
      input$genes_interest == (OV_genes %>% paste(collapse = ", "))
    ) {
      
      load("data/OV_data.RData")
      rv$results <- list(sub_graph = sub_graph, scores = scores)
      
    } else if ( # PAAD
      input$example == "Pancreatic Adenocarcinoma" && 
      input$genes_interest == (PAAD_genes %>% paste(collapse = ", "))
    ) {
      
      load("data/PAAD_data.RData")
      rv$results <- list(sub_graph = sub_graph, scores = scores)
      
    } else if ( # THCA
      input$example == "Thyroid Cancer" && 
      input$genes_interest == (THCA_genes %>% paste(collapse = ", "))
      ) {
      
      load("data/THCA_data.RData")
      rv$results <- list(sub_graph = sub_graph, scores = scores)
      
    } else if ( # BLCA
      input$example == "Urothelial Bladder Carcinoma" && 
      input$genes_interest == (BLCA_genes %>% paste(collapse = ", "))
      ) {
      
      load("data/BLCA_data.RData")
      rv$results <- list(sub_graph = sub_graph, scores = scores)
      
    }
  })
  
  # Show the GO slim selectInput when the corresponding checkbox is marked ----
  observeEvent(input$GO_use_slim, {
    
    if (input$GO_use_slim) {
      shinyjs::show("GO_slim")
    } else {
      shinyjs::hide("GO_slim")
    }
    
  })
  
  # Calculate scores and visualisation ----
  observeEvent(input$calculate_scores, {
    
    shinyjs::enable("cancel_calculation")
    progress <- shiny::Progress$new()
    
    # Make sure genes of interest are valid input
    genes_interest <- input$genes_interest %>%
      str_split(", ") %>%
      unlist()
    
    HPO_interest <- input$HPO_interest
    
    percentage_output_genes <- input$percentage_output_genes
    graph_order <- input$graph_order
    GO_annot <- input$GO_annot
    
    # Transform readable inputs into proper function arguments
    GO_slim <- case_when(
      input$GO_slim == "AGR"                       ~ "agr",
      input$GO_slim == "Generic"                   ~ "generic",
      input$GO_slim == "Aspergillus"               ~ "aspergillus",
      input$GO_slim == "Candida"                   ~ "candida",
      input$GO_slim == "Drosophila"                ~ "drosophila",
      input$GO_slim == "chEMBL"                    ~ "chembl",
      input$GO_slim == "Metagenomic"               ~ "metagenomic",
      input$GO_slim == "Mouse"                     ~ "mouse",
      input$GO_slim == "Plant"                     ~ "plant",
      input$GO_slim == "PIR"                       ~ "pir",
      input$GO_slim == "Schizosaccharomyces pombe" ~ "pombe",
      input$GO_slim == "Yeast"                     ~ "yeast"
    )
    
    GO_aspects <- case_when(
      input$GO_aspects == "cellular component" ~ "C",
      input$GO_aspects == "molecular function" ~ "F",
      input$GO_aspects == "biological process" ~ "P",
      TRUE                                     ~ c("C", "F", "P")
    )
    
    GO_organism <- input$GO_organism
    HPO_annot <- input$HPO_annot
    restart_prob_rw <- input$restart_prob_rw
    threshold_rw <- input$threshold_rw
    
    percentage_output_genes <- input$percentage_output_genes
    graph_order <- input$graph_order
    databases <- NULL
    
    tryCatch({
      
      # Used to enable the cancel button
      # Cancel button only works if the app is started outside of RStudio 
      # (i.e. base R, server)
      scores_future <<- future({
        
        progress$set(message = "Executing WPPI workflow.")
        
        # import data object
        data_info <-
          databases %||%
          wppi_data(
            GO_slim = {if (is.na(GO_slim)) NULL else GO_slim},
            GO_aspects = GO_aspects,
            GO_organism = GO_organism,
            shinyProgress = progress
          )
        
        if (!is.null(HPO_interest)) {
          HPO_data <- data_info$hpo %>% filter(Name %in% HPO_interest)
        } else {
          HPO_data <- data_info$hpo
          progress$set(message = "Using all HPO annotations available.")
        }
        
        # graph object from PPI data
        progress$set(message = "Building graph from PPI data.")
        graph_op <- graph_from_op(op_data = data_info$omnipath)
        
        # build ith-order graph based on genes of interest
        progress$set(message = "Extracting subgraph around genes of interest.")
        sub_graph <- subgraph_op(
          graph_op = graph_op,
          gene_set = genes_interest,
          sub_level = graph_order
        )
        
        # subset GO info based on PPI
        GO_data_sub <- `if`(
          GO_annot,
          {progress$set(message = "Filtering GO info based on graph")
            filter_annot_with_network(
              data_annot = data_info$go,
              graph_op = sub_graph
            )},
          NULL
        )
        
        # subset HPO info based on PPI
        HPO_data_sub <- `if`(
          HPO_annot,
          {progress$set(message = "Filtering HPO info based on graph")
            filter_annot_with_network(
              data_annot = HPO_data,
              graph_op = sub_graph
            )},
          NULL
        )
        
        # weight PPI based on annotations
        weighted_adj_sub <- weighted_adj(
          graph_op = sub_graph,
          GO_data = GO_data_sub,
          HPO_data = HPO_data_sub
        )
        
        # random walk algorithm on weighted PPI
        random_walk_sub <- wppi::random_walk(
          weighted_adj_matrix = weighted_adj_sub,
          restart_prob = restart_prob_rw,
          threshold = threshold_rw,
          shinyProgress = progress
        )
        
        # compute and rank scores of candidate genes based on given genes
        scores <- prioritization_genes(
          graph_op = sub_graph,
          prob_matrix = random_walk_sub,
          genes_interest = genes_interest,
          percentage_genes_ranked = percentage_output_genes,
          shinyProgress = progress
        )
        
        progress$set(message = "WPPI workflow completed.")
        
        list(
          scores = scores,
          sub_graph = sub_graph
        )
        
      })
      
      prom <- scores_future %...>% {. -> rv$results}
      prom <- catch(scores_future,
                    function(err) {
                      resetLoadingButton("calculate_scores")
                      shinyjs::disable("cancel_calculation")
                      progress$close()
                    })
      
      scores_future <- finally(scores_future, function() {
        resetLoadingButton("calculate_scores")
        shinyjs::disable("cancel_calculation")
        progress$close()
      })
      
      NULL
    },
    error = function(err) {
      resetLoadingButton("calculate_scores")
      shinyjs::disable("cancel_calculation")
      progress$close()
      print(err$message)
    })
  })
  
  # Cancel calculation ----
  observeEvent(input$cancel_calculation, {
    stopMulticoreFuture(scores_future)
  })
  
  # Download results ----
  output$download_scores <- downloadHandler(
    
    filename = paste0(Sys.Date(), "_results.zip"),
    
    content = function(zip_fn) {
      
      download_overlay$show()
      fn_list <- c()
      
      tmpdir <- tempdir()
      setwd(tmpdir)
      
      # Create html with visualization
      fn <- "visualization.html"
      fn_list <- c(fn_list, fn)
      
      legend_nodes <- create_size_legend(
        rv$results$scores,
        palette = input$vis_palette,
        colors = list(
          nodes = c(input$vertex_col_high, input$vertex_col_low),
          edges = c(input$edge_col_high, input$edge_col_low),
          genes_interest = input$gene_of_interest_col
        ),
        direction = 2
      ) %>% 
        .$x %>% 
        .$nodes
      
      visualization <- rv$visualization 
      
      visualization %>% 
        visLegend(
          addNodes = legend_nodes,
          useGroups = FALSE,
          position = "right",
          zoom = FALSE
        ) %>% 
        visOptions(
          selectedBy = "Gene_Symbol",
          highlightNearest = TRUE#,
          # width = "900px",
          # height = "900px"
        ) %>% 
        visSave(fn)
      
      # Create excel file with score table
      scores_fn <- "scores.csv"
      fn_list <- c(fn_list, scores_fn)
      
      sub_graph <- rv$results$sub_graph
      scores <- rv$results$scores 
      
      write.csv(scores, scores_fn)
      
      # Create RData object with visualization as visNetwork object and 
      # scores as data.frame
      rdata_fn <- "R_objects.RData"
      fn_list <- c(fn_list, rdata_fn)
      
      save(sub_graph, scores, visualization, file = rdata_fn)
      
      download_overlay$hide()
      
      system2("zip", args = paste(zip_fn, fn_list, sep = " "))
      
    },
    
    contentType = "application/zip"
  )
  
  # Things to happen once calculation is done ----
  observeEvent(rv$results, {
    
    # Render scores data table
    output$scores_dt <- rv$results$scores %>% 
      renderDataTable()
    
    # Create visualisation
    rv$visualization <- visualize_graph(
      sub_graph = rv$results$sub_graph,
      genes_interest = input$genes_interest %>%
        str_split(", ") %>%
        unlist(),
      scores = rv$results$scores,
      palette = {
        if (input$vis_palette != "custom") input$vis_palette else NULL
      },
      colors = if (input$vis_palette == "custom") list(
        nodes = c(input$vertex_col_high, input$vertex_col_low),
        edges = c(input$edge_col_high, input$edge_col_low),
        genes_interest = input$gene_of_interest_col
      ) else NULL,
      legend = FALSE
    )
    
    # Store graph data for edge filtering
    rv$graph_data <- rv$visualization %>%
      .$x %>%
      .[c("nodes", "edges")]
    
    # Show edge filter input
    shinyjs::show("filter_edges")
    
    # Show legend title
    shinyjs::show("score_text")
    
    # Render legend
    output$node_size_legend <- create_size_legend(
      rv$results$scores,
      palette = input$vis_palette,
      colors = list(
        nodes = c(input$vertex_col_high, input$vertex_col_low),
        edges = c(input$edge_col_high, input$edge_col_low),
        genes_interest = input$gene_of_interest_col
      )
    ) %>%
      renderVisNetwork()
    
  })
  
  # Things to happen once the visualisation is created ----
  observeEvent(rv$visualization, {
    
    # Render visualisation
    output$sub_graph_vis <- rv$visualization %>%
      renderVisNetwork()
    
    # Show overlay that the network is zoomable
    if (!rv$zoom_shown) {
      shinyjs::delay(10, {
        zoom_overlay$show()
        Sys.sleep(3)
        zoom_overlay$hide()
      })
      rv$zoom_shown <<- TRUE
    }
  })
  
  # Filter edges ----
  observeEvent(input$filter_edges, {
    
    req(rv$graph_data)
    
    # Collect edge IDs with scores below given percentile
    edge_ids_to_remove <- rv$graph_data$edges %>% 
      filter(
        score < quantile(score, input$filter_edges/100, na.rm = TRUE)
      ) %>% 
      .$id
    
    # Update network
    visNetworkProxy("sub_graph_vis") %>% 
      visUpdateEdges(edges = rv$graph_data$edges) %>% 
      visRemoveEdges(edge_ids_to_remove)
  })
  
  # En-/disable custom color inputs if a pre-set palette is chosen or not
  observeEvent(input$vis_palette, {
    
    if (input$vis_palette == "custom") {
      
      enable("vertex_col_low")
      enable("vertex_col_high")
      enable("edge_col_low")
      enable("edge_col_high")
      enable("gene_of_interest_col")
      
    } else {
      
      disable("vertex_col_low")
      disable("vertex_col_high")
      disable("edge_col_low")
      disable("edge_col_high")
      disable("gene_of_interest_col")
      
    }
    
  })
  
  # Change colours of network nodes if any color input is changed ----
  observeEvent(
    c(
      input$vis_palette, 
      input$vertex_col_high, 
      input$vertex_col_low, 
      input$edge_col_high, 
      input$edge_col_low, 
      input$gene_of_interest_col
    ), {
      
      req(rv$visualization)
      
      rv$visualization <- visualize_graph(
        rv$results$sub_graph,
        input$genes_interest %>%
          str_split(", ") %>%
          unlist(),
        rv$results$scores,
        palette = {
          if (input$vis_palette != "custom") input$vis_palette else NULL
        },
        colors = if (input$vis_palette == "custom") list(
          nodes = c(input$vertex_col_high, input$vertex_col_low),
          edges = c(input$edge_col_high, input$edge_col_low),
          genes_interest = input$gene_of_interest_col
        ) else NULL,
        legend = FALSE
      )
      
      rv$graph_data <- rv$visualization %>%
        .$x %>%
        .[c("nodes", "edges")]
      
      output$node_size_legend <- create_size_legend(
        rv$results$scores,
        palette = input$vis_palette,
        colors = list(
          nodes = c(input$vertex_col_high, input$vertex_col_low),
          edges = c(input$edge_col_high, input$edge_col_low),
          genes_interest = input$gene_of_interest_col
        )
      ) %>%
        renderVisNetwork()
    }
  )
  
}