% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tools.R
\name{permu.test}
\alias{permu.test}
\title{Function for permutation test}
\usage{
permu.test(
  x,
  y,
  n_perm = 2000,
  alternative = "two.sided",
  seed = 1,
  verbose = T
)
}
\arguments{
\item{x, y}{numeric vector of data values. Non-finite values will be ommitted}

\item{n_perm}{permutation times}

\item{alternative}{a character string specifying the alternative hypothesis, must be one of "two.sided" (default), "greater" or "less". You can specify just the initial letter.}

\item{seed}{Set permutation seed. Default = 1}

\item{verbose}{logical value specify whether to print logs. Default = TRUE}
}
\value{
A named list
}
\description{
Function for permutation test
}
