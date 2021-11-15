#' @export
run <- function() {
  appDir <- system.file("inst", package = "wppi.shiny")
  if (appDir == "") {
    stop("Could not find example directory. Try re-installing `wppi.shiny`.", call. = FALSE)
  }
  
  shiny::runApp(appDir, display.mode = "normal")
}