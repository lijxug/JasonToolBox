#' @import methods
#' @import stats
#' @import utils 
NULL

#' Get the lower triangle of a symmetric matrix
#'
#' @param x_mt A symmetric matrix
#' @param keep_diag Logical. Keep diagonal values or not.
#' @return A data frame
#' @export
getLowerTri2df = function(x_mt, keep_diag = T){
  stopifnot(all(rownames(x_mt) == colnames(x_mt)))
  clusters = rownames(x_mt)
  row_tags = clusters[row(x_mt)]
  col_tags = clusters[col(x_mt)]
  low_idx = lower.tri(x_mt, diag = keep_diag)
  out_df = data.frame(row_tag = row_tags[low_idx], col_tag = col_tags[low_idx], 
                      value = x_mt[low_idx])
  return(out_df)
}

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
  website="https://sctapi.ftqq.com/"
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
  if(any(unlist(lapply(rm_list, function(x){exists(x, inherits = T)}))))
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
#' @param ... Other arguments for openxlsx::writeDataTable
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
  openxlsx::writeDataTable(wb, sheet = sheetName, x = sheetData, colNames = TRUE, rowNames = TRUE,tableStyle = "TableStyleLight9", ...)
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
#' @param x A list with two named expression matrixces of n genes * m cells.
#' @param ... Other options. Placeholder, not used yet.
#' 
#' @return a data.frame
#' @export
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
    t_res = stats::wilcox.test(mt1[i,], mt2[i,])
    p_vals[i] = t_res$p.value
    means_mt1[i] = mean(mt1[i, ])
    means_mt2[i] = mean(mt2[i, ])
    if (progress)
      processBar(iter01, i, n_tx, tail = "ETA")
  }
  FC = means_mt2 / (means_mt1 + .0001)
  LFC = log2(FC)
  p_adjs = stats::p.adjust(p_vals)

  res_tbl = data.frame(
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
apply_MM <- function(X, MARGIN = 1, FUN) {
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

#' Function for permutation test
#' 
#' @param x,y numeric vector of data values. Non-finite values will be ommitted
#' @param n_perm permutation times
#' @param alternative a character string specifying the alternative hypothesis, must be one of "two.sided" (default), "greater" or "less". You can specify just the initial letter.
#' @param seed Set permutation seed. Default = 1
#' @param verbose logical value specify whether to print logs. Default = TRUE
#' 
#' @return A named list
#' @export
permu.test = function(x, y, n_perm = 2000, alternative = 'two.sided', seed = 1, verbose = T){
  set.seed(seed)
  x = x[is.finite(x)]
  y = y[is.finite(y)]
  observed = median(x) - median(y)
  all_values = c(x, y)
  if(verbose){
    iFUN = pbmcapply::pbmclapply
  } else {
    iFUN = parallel::mclapply
  }
  perm_dist = unlist(iFUN(mc.cores = 50, 1:n_perm, function(x){
    perm_x = sample(all_values, size = length(x))
    perm_y = sample(all_values, size = length(y))
    return(median(perm_x) - median(perm_y))
  }))
  
  emp_p_g = (sum(perm_dist >= observed)+1)/(n_perm + 1)
  emp_p_l = (sum(perm_dist <= observed)+1)/(n_perm + 1)
  emp_p_both = (sum(abs(perm_dist) <= abs(observed))+1)/(n_perm + 1)
  emp_p_b = min(emp_p_g, emp_p_l)*2
  if(alternative == 'greater'){
    return(list(observe = observed, dist = perm_dist, p.value = emp_p_g, n_perm = n_perm, alternative = alternative))
  } else if(alternative == 'less') {
    return(list(observe = observed, dist = perm_dist, p.value = emp_p_l, n_perm = n_perm, alternative = alternative))
  } else if(alternative == 'one.sided'){
    return(list(observe = observed, dist = perm_dist, p.value = min(emp_p_g,emp_p_l), n_perm = n_perm, alternative = alternative))
  } else {
    return(list(observe = observed, dist = perm_dist, p.value = emp_p_both, n_perm = n_perm, alternative = alternative))
  }
}



#' Wrapper for batch testing
#' 
#' @param data_df The data frame to test
#' @param group_var The variable name for testing groups
#' @param test_var The variable name for testing values 
#' @param test_set A 2 x n combn matrix for pairs of condition to test
#' @param by_facet A string for the facet
#' @param method One of the c('permutation', <to be added>)
#' @param pairby The variable name for pairing, default NULL
#' @param p_cutoff Specify the cutoff for significant p values
#' @param ... Other parameters for test functions
#' 
#' 
#' @importFrom magrittr `%>%`
#' @return A data.frame
#' @export
batch_testing = function(data_df,
                         group_var,
                         test_var,
                         test_set,
                         by_facet = NULL,
                         method = 'permutation',
                         pairby = NULL,
                         p_cutoff = 0.1,
                         ...) {
  
  
  res_tbl = dplyr::tibble()
  args = list(...)
  args$alternative = ifelse(is.null(args$alternative), 'two.sided', args$alternative)
  args$verbose = ifelse(is.null(args$verbose), T, args$verbose)
  args$n_perm = ifelse(is.null(args$n_perm), 2000, args$n_perm)
  args$paired = ifelse(is.null(pairby), F, T)
  
  if (!is.null(by_facet)) {
    facets2test = unique(data_df[[by_facet]])
    facets2test = facets2test[!is.na(facets2test)]
  } else {
    facets2test = '.all'
  }
  for (i_facet in facets2test) {
    if(i_facet == '.all'){
      t_test_tbl = data_df
    } else {
      t_test_tbl = data_df[data_df[[by_facet]] == i_facet, ]
    }
    
    for (i_col in 1:ncol(test_set)) {
      # Prepare data
      x_cat = test_set[1, i_col]
      y_cat = test_set[2, i_col]
      
      if (args$paired) {
        if (any(!c(x_cat, y_cat) %in% t_test_tbl[[group_var]])) {
          x1 = NULL
          x2 = NULL
        } else{
          p_test_tbl = t_test_tbl %>%
            dplyr::filter((!!dplyr::sym(group_var)) %in% c(x_cat, y_cat)) %>%
            tidyr::pivot_wider(
              id_cols = dplyr::all_of(pairby),
              names_from = group_var,
              values_from = test_var
            ) %>% dplyr::filter(!is.na(!!(dplyr::sym(as.character(x_cat)))) &
                                  !is.na(!!(dplyr::sym(as.character(y_cat)))))
          x1 = p_test_tbl[[x_cat]]
          x2 = p_test_tbl[[y_cat]]
        }
      } else {
        x1 = t_test_tbl[t_test_tbl[[group_var]] == x_cat, test_var, drop = T]
        if (y_cat == 'others') {
          x2 = t_test_tbl[t_test_tbl[[group_var]] != x_cat, test_var, drop = T]
        } else {
          x2 = t_test_tbl[t_test_tbl[[group_var]] == y_cat, test_var, drop = T]
        }
      }
      
      x1 = x1[is.finite(x1)]
      x2 = x2[is.finite(x2)]
      
      if (length(x1) <2 || length(x2) < 2) {
        next
      }
      if (length(x1) == 2 || length(x2) ==2){
        warning('Values too few, using permutation test.\n')
        test_res = permu.test(x1, x2, ...)
      } else {
        # Test
        if (method == 'permutation') {
          test_res = permu.test(x1, x2, ...)
        } else if (method == 'wilcox') {
          test_res = wilcox.test(x1, x2, paired = args$paired, ...)
        } else if (method == 'ttest') {
          # Test for normality assumption
          if (args$paired) {
            if (length(x2 - x1) < 3) {
              shape_res = list(p.value = 0)
            } else if (length(x2 - x1) < 50) {
              shape_res = tryCatch({
                shapiro.test(x2 - x1)
              }, error = function(e) {
                print(e)
                return(list(p.value = 0))
              })
            } else {
              shape_res = ks.test(x2 - x1,
                                  pnorm,
                                  mean = mean(x2 - x1),
                                  sd = sd(x2 - x1))
            }
            
          } else {
            if (length(x1) < 3) {
              shape_res1 = list(p.value = 0)
            } else if (length(x1) < 50) {
              shape_res1 = shapiro.test(x1)
            } else {
              shape_res1 = ks.test(x1, pnorm, mean = mean(x1), sd = sd(x1))
            }
            
            if (length(x2) < 3) {
              shape_res2 = list(p.value = 0)
            } else if (length(x2) < 50) {
              shape_res2 = shapiro.test(x2)
            } else {
              shape_res2 = ks.test(x2, pnorm, mean = mean(x2), sd = sd(x2))
            }
            shape_res = list(p.value = min(shape_res1$p.value, shape_res2$p.value))
          }
          
          if (shape_res$p.value > p_cutoff) {
            test_res = t.test(x1, x2, paired = args$paired, ...)
          } else {
            # Not applicable
            test_res = list(p.value = NA)
          }
        } else {
          warning('Not supported yet. Falling back to permutation test.\n')
          test_res = permu.test(x1,
                                x2,
                                n_perm = 10000,
                                alternative = args$alternative)
        }
      }
      
      # Arrange position
      res_tbl = dplyr::bind_rows(
        res_tbl,
        data.frame(
          facets = i_facet,
          # y_position = max(t_test_tbl[[test_var]], na.rm = T) * (1 + i_col * 0.1),
          y_position = max(c(x1,x2), na.rm = T) * (1 + i_col * 0.1),
          xmin = x_cat,
          xmax = y_cat,
          p.value = test_res$p.value, 
          grp1_mean = mean(x1, na.rm = T),
          grp2_mean = mean(x2, na.rm = T),
          grp1_zscore = mean((x1-mean(c(x1,x2)))/sd(c(x1,x2))),
          grp2_zscore = mean((x2-mean(c(x1,x2)))/sd(c(x1,x2)))
        )
      )
    }
  }
  
  return(res_tbl)
}


# #' Dirichlet-multinomial regression test
# #' this function is adapted from https://github.com/cssmillie/ulcerative_colitis:analysis.r  
# #'
# #' @export
# #'
# dirichlet_regression = function(counts, covariates, formula){  
#   # Dirichlet multinomial regression to detect changes in cell frequencies
#   # formula is not quoted, example: counts ~ condition
#   # counts is a [samples x cell types] matrix
#   # covariates holds additional data to use in the regression
#   #
#   # Example:
#   # counts = do.call(cbind, tapply(seur@data.info$orig.ident, seur@ident, table))
#   # covariates = data.frame(condition=gsub('[12].*', '', rownames(counts)))
#   # res = dirichlet_regression(counts, covariates, counts ~ condition)
#   
#   #ep.pvals = dirichlet_regression(counts=ep.freq, covariates=ep.cov, formula=counts ~ condition)$pvals
#   
#   # Calculate regression
#   counts = as.data.frame(counts)
#   counts$counts = DR_data(counts)
#   data = cbind(counts, covariates)
#   fit = DirichReg(counts ~ condition, data)
#   
#   # Get p-values
#   u = summary(fit)
#   #compared with healthy condition, 15 vars. noninflame and inflame, 30pvalues
#   pvals = u$coef.mat[grep('Intercept', rownames(u$coef.mat), invert=T), 4] 
#   v = names(pvals)
#   pvals = matrix(pvals, ncol=length(u$varnames))
#   rownames(pvals) = gsub('condition', '', v[1:nrow(pvals)])
#   colnames(pvals) = u$varnames
#   fit$pvals = pvals
#   
#   fit
# }
#' Dirichlet-multinomial regression test
#' @param count_df sample x cell_fraction data.frame
#' @param predictor A named vector
#' 
#' @import DirichletReg reshape2 dplyr
#'
#' @export
#' 
dirichletTest = function(count_df, predictor){
  # require(DirichletReg)
  count_df$Y = DirichletReg::DR_data(count_df)
  count_df$predictor =  predictor[rownames(count_df$Y)]
  fit = DirichletReg::DirichReg(Y ~ predictor, count_df)
  u = summary(fit)
  #compared with healthy condition, 15 vars. noninflame and inflame, 30pvalues
  pvals = u$coef.mat[, 4]
  v = names(pvals)
  pvals = matrix(pvals, ncol = length(u$varnames))
  estimates = matrix(u$coef.mat[, 1], ncol = length(u$varnames))
  tmp_rownames = gsub('predictor', '', v[1:nrow(pvals)])
  tmp_rownames[tmp_rownames == '(Intercept)'] = setdiff(unique(count_df$predictor), tmp_rownames)
  rownames(pvals) = tmp_rownames
  rownames(estimates) = tmp_rownames
  colnames(pvals) = u$varnames
  colnames(estimates) = u$varnames
  fit$pvals = pvals
  fit$estimates = estimates
  
  pvals_df = reshape2::melt(pvals, varnames = c('status', 'celltypes'), value.name = 'p.value')
  estimates_df = reshape2::melt(estimates, varnames = c('status', 'celltypes'), value.name = 'estimates')
  
  res_df = left_join(pvals_df, estimates_df, by = c('status', 'celltypes'))
  res_df$isInterval = res_df$status == levels(predictor)[1]
  fit$res_df = res_df
  
  return(fit)
}

#' Batch fisher test
#' @param counts_bystatus A x B count matrix
#' @param p.adjust.method P adjust method for `p.adjust`, default = 'BH'
#' @param include_self Whether to include self counts. Default = TRUE 
#' @param ... other arguments for `fisher.test`
#' 
#' @export
#' @return a data.frame for p values and ORs from `fisher.test`
#' 
fisherTest = function(counts_bystatus, p.adjust.method = 'BH', include_self = TRUE,...){
  fisher_lst = list()
  
  if(length(setdiff(rownames(counts_bystatus), colnames(counts_bystatus))) == 0 & 
     length(setdiff(colnames(counts_bystatus), rownames(counts_bystatus))) == 0){
    if(!all(rownames(counts_bystatus) == colnames(counts_bystatus))){
      common_names = rownames(counts_bystatus)
      counts_bystatus = counts_bystatus[common_names, common_names]
    }
    if(!include_self){
      diag(counts_bystatus) = 0
    }
  }
  
  for(i in 1:nrow(counts_bystatus)){
    tmp_lst = lapply(1:ncol(counts_bystatus), function(j){
      tmp_mt = matrix(c(counts_bystatus[i, j], sum(counts_bystatus[-i, j]), 
        sum(counts_bystatus[i, -j]), sum(counts_bystatus[-i, -j])), nrow = 2
      )
      rownames(tmp_mt) = c(rownames(counts_bystatus)[i], 'others')
      colnames(tmp_mt) = c(colnames(counts_bystatus)[j], 'others')
      fish_obj = fisher.test(tmp_mt, ...)
      return(data.frame(i = rownames(counts_bystatus)[i], j = colnames(counts_bystatus)[j], 
                        fisher.p.val = fish_obj$p.value, fisher.OR = fish_obj$estimate))
    })
    fisher_lst[[i]] = do.call(rbind, tmp_lst)
  }
  fisher_df = do.call(rbind, fisher_lst)
  fisher_df$fisher.p.val[fisher_df$i == fisher_df$j] = NA
  fisher_df$fisher.OR[fisher_df$i == fisher_df$j] = NA
  pval_mt = reshape2::acast(data = fisher_df, i~j, value.var = 'fisher.p.val')
  padj_mt = pval_mt
    
  padj_mt[upper.tri(padj_mt)] = p.adjust(pval_mt[upper.tri(pval_mt)])
  padj_mt[lower.tri(padj_mt)] = t(padj_mt)[lower.tri(padj_mt)]
  
  fisher_df = dplyr::left_join(
    fisher_df,  
    reshape2::melt(padj_mt, varnames = c('i','j'), value.name = 'fisher.p.adj'), 
    by = c('i', 'j'))
    
  fisher_df$fisher.p.adj = p.adjust(fisher_df$fisher.p.val, method = p.adjust.method)
  rownames(fisher_df) = NULL
  return(fisher_df)
}
