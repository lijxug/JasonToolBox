#' Print formated log
#'
#' @param ... a string or list of strings to print
#' @param printnow logical, if print on the screen or return log as a string
#' @export
#'
loginfo <- function(..., printnow = T) {
  msg = paste0(list(...), collapse = "")
  msg <- paste0("[",format(Sys.time()), "] ", msg,"\n")
  if(printnow)
    cat(msg)
  invisible(msg)
}

#' Sent message to wechat
#'
#' @param ttl string, title of the message
#' @param msg string, optional
#' @param SCKEY string, SCKEY from ServerChan, must be provided
#' @export
msgASAP <- function(ttl, msg = "", SCKEY){
  # warning: authorized access only
  website="https://sc.ftqq.com/"
  url = paste0(website, SCKEY, ".send?")

  stopifnot(is.character(ttl))
  ttl = gsub("\\s", "%20", ttl)

  url = paste0(url, "text=", ttl)
  if(nchar(msg) != 0){
    msg = gsub("\\s", "%20", msg)
    url = paste0(url, "&desp=", msg)
  }
  x = readLines(url,encoding="UTF-8", warn = F)
  invisible(x)
}

#' Process bar for loops
#'
#' a terminal process Bar, use initiatePB to initialize at the beginning of the forloop,
#' and insert processBar with objName, i, cycles inside the for loop
#'
#' @param objName String; name of the processBar object, which is actually an iterator object
#' @param i       Integer;
#' @param cycles  Integer;
#' @param title   String; Default = "Process"
#' @param scale   Integer; Default = 40
#' @param sign    Character; Default = "#"
#' @param tail    String; Default = ""
#' @param terminal String; Default = "R"
#' @param final   String; Default = "Work done!"
#'
#' @export
#'
# #' @example to be done.
processBar = function(objName,
                      i,
                      cycles,
                      title = "Process",
                      scale = 40,
                      sign = "#",
                      tail = "",
                      terminal = "R", # terminal could be R/log, others default to shell
                      final = "Work done!") {
  stopifnot(requireNamespace("iterators", quietly = TRUE))
  if (!exists(objName)) { # if first run/initialized
    if (terminal != "R")
      words_list = unlist(lapply(1:cycles, function(x) {
        sprintf(
          paste0("\033[?25l\r%s %5.1f%% | %-", scale, "s | "),
          title,
          x * 100 / cycles ,
          paste0(rep(sign, ceiling(x * scale / cycles)), collapse = "")
        )
      }))#\033[?25l hide the cursor - linux control code
    else
      words_list = unlist(lapply(1:cycles, function(x) {
        sprintf(
          paste0("\r%s %5.1f%% | %-", scale, "s | "),
          title,
          x * 100 / cycles ,
          paste0(rep(sign, ceiling(x * scale / cycles)), collapse = "")
        )
      }))
    eval(parse(text = sprintf("%s <<- iterators::iter(words_list)", objName)))
    eval(parse(text = sprintf("%s <<- Sys.time()", paste0(".TIC_",objName))))
    # if i didn't start at 1
    times = i
    while (times > 1) {
      msg = eval(parse(text = sprintf("iterators::nextElem(%s)", objName)))
      times = times - 1
    }
  }

  msg = eval(parse(text = sprintf("iterators::nextElem(%s)", objName)))
  if(tail == "ETA"){
    .tic = eval(parse(text = sprintf("%s", paste0(".TIC_",objName))))
    if(terminal != "R"){
      tail = paste0("ETA: ", format(round((Sys.time() - .tic) / i * (cycles - i), digits = 2)), "\033[K")
    }
    else {
      tail = paste0("ETA: ", format(round((Sys.time() - .tic) / i * (cycles - i), digits = 2)), "   ")
    }
  }
  if(terminal == "log")
    tail = paste0(tail, "\n")
  cat(paste0(msg, tail))
  if(i == cycles){
    if(nchar(final)) final = loginfo(final, printnow = F)
    if(terminal != "R") cat("\033[?25h")
    cat(paste0("\n", final))
    rm(list = objName, envir = parent.frame(2)) # clean the global variable in the parent environment
  }
}


#' Initiate and reset Process Bar
#'
#' @param iterOBJ String; Name of the iterator
#' @export
initiatePB = function(iterOBJ){
  .tic = sprintf("%s", paste0(".TIC_", iterOBJ))
  rm_list = c(iterOBJ, .tic)
  if(any(exists(rm_list, inherits = T)))
    rm(list = rm_list, envir = parent.frame(2))
}


test_processBar = function(){
  iter01 = ".I1"
  initiatePB(iter01)
  for(i in 1:100){
    Sys.sleep(0.1)
    processBar(objName = iter01, i = i, cycles = 100, tail = "ETA")
  }
}

#' Extract legend from a ggplot object
#'
#' @param a.gplot A ggplot object
#'
#' @export
#'
extractLegend<-function(a.gplot){
  stopifnot(requireNamespace("ggplot2", quietly = TRUE))
  # a function to extract legends from ggplot object
  # http://stackoverflow.com/questions/12041042/how-to-plot-just-the-legends-in-ggplot2
  tmp <- ggplot2::ggplot_gtable(ggplot2::ggplot_build(a.gplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)
}


#' Initiate a openxlsx workbook
#'
#' Inititate a openxlsx workbook with hard-coded format. Will be upgraded in the future (if necessary)
#'
#' @param ... Need nothing
#'
#' @export
#'
EXWB.initiate = function(...) {
  # suppressPackageStartupMessages(require(openxlsx))
  stopifnot(requireNamespace("openxlsx", quietly = TRUE))
  args = list(...)

  wb <- openxlsx::createWorkbook()
  options("openxlsx.borderColour" = "#4F80BD")
  options("openxlsx.borderStyle" = "thin")
  openxlsx::modifyBaseFont(wb, fontSize = 16, fontName = "Arial")
  invisible(wb)
}

#' Initiate a openxlsx workbook
#'
#' Inititate a openxlsx workbook with hard-coded format. Will be upgraded in the future (if necessary)
#'
#' @param wb An openxlsx wb object to be written in
#' @param sheetName String; Name of the sheet to write.
#' Sheet name must have <= 31 characters without any strange characters like !\@\#\$\%\^\&\*\(\)
#' @param sheetData Data frame or tibble to write.
#' @param overwrite Logical; if to overwrite the sheet with the same name.
#'
#' @export
#'
EXWB.writeSheet = function(wb, sheetName, sheetData, overwrite = F, ...){
  # suppressPackageStartupMessages(require(openxlsx))
  # suppressPackageStartupMessages(require(dplyr))
  stopifnot(requireNamespace("openxlsx", quietly = TRUE))
  args = list(...)

  stopifnot(nchar(sheetName) <= 31)
  sheetIndex = ifelse(length(which(wb$sheet_names == sheetName)) == 0, -1, which(wb$sheet_names == sheetName))
  if(sheetIndex>0){ # exists
    if(overwrite){
      openxlsx::removeWorksheet(wb, sheetIndex)
    }else{
      return(invisible(wb))
    }
  }
  openxlsx::addWorksheet(wb, sheetName = sheetName, gridLines = T)
  # sheetData = sheetData %>% mutate_if(is.double, round, digits = 4)
  openxlsx::writeDataTable(wb, sheet = sheetName, x = sheetData, colNames = TRUE, rowNames = TRUE,tableStyle = "TableStyleLight9")
  invisible(wb)
}


#' Generate ggplot default colors
#'
#' adopted from \url{https://stackoverflow.com/questions/8197559/emulate-ggplot2-default-color-palette}
#' @param n Integer; number of the generated colors
#' @export
gg_color_hue <- function(n) {
  hues = seq(15, 375, length = n + 1)
  grDevices::hcl(h = hues, l = 65, c = 100)[1:n]
}

#' Differential expression analysis using Wilcoxon test
#'
#'@param x A list with two named expression matrixces of n genes * m cells.
#'@param ... Other options. Placeholder, not used yet.
#'
#'@export
dea.wilcox = function(x, ...) {
  # x being the list with two named expression matrixes,
  # ... whose rownames correspond to tx_names and colnames to sample_names
  # other augments:
  mt1 = x[[1]]
  mt2 = x[[2]]

  args = list(...)
  progress = ifelse(is.null(args$progress), T, args$progress)

  stopifnot(nrow(mt1) == nrow(mt2))

  n_tx = nrow(mt1)
  p_vals = rep(NA, n_tx)
  means_mt1 = rep(NA, n_tx)
  means_mt2 = rep(NA, n_tx)
  iter01 = ".I1_fun"
  initiatePB(iter01)
  for (i in 1:n_tx) {
    t_res = wilcox.test(mt1[i,], mt2[i,])
    p_vals[i] = t_res$p.value
    means_mt1[i] = mean(mt1[i, ])
    means_mt2[i] = mean(mt2[i, ])
    if (progress)
      processBar(iter01, i, n_tx, tail = "ETA")
  }
  FC = means_mt2 / (means_mt1 + .0001)
  LFC = log2(FC)
  p_adjs = p.adjust(p_vals)

  res_tbl = tibble(
    id = rownames(mt1),
    means_mt1 = means_mt1,
    means_mt2 = means_mt2,
    FoldChange = FC,
    LogFC = LFC,
    P.Value = p_vals,
    adj.P.Val = p_adjs
  )

  return(res_tbl)
}

#' Apply for Sparse matrix
#'
#' Use it with cautions! Only apply FUN to all the non-zero values!!
#'
#' @param X, a sparse matrix
#' @param MARGIN 1 or 2, indicating row-wise or column-wise
#' @param FUN a function
#'
#' @return Numeric vector
#'
#' @export
#'
apply.MM <- function(X, MARGIN = 1, FUN) {
  stopifnot(requireNamespace("Matrix", quietly = TRUE))
  X2 <- as(X, "dgTMatrix")
  if(MARGIN == 1){
    res <- numeric(nrow(X))
    tmp <- tapply(X2@x, X2@i, FUN)

  } else if(MARGIN == 2){
    res <- numeric(ncol(X))
    tmp <- tapply(X2@x, X2@j, FUN)

  }
  res[as.integer(names(tmp)) + 1] <- tmp
  res
}
