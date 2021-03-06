#' @name synLFQ2
#'
#' @title Synthetic length frequency data II
#'
#'
#' @description Synthetic length frequency data from Sparre & Venema (1998). Can be used
#'    for the estimation of the instantaneous total mortality rate (Z) by means
#'    of \code{\link{Z_BevertonHolt}}.
#'
#' @docType data
#'
#' @format A list consisting of:
#' \itemize{
#'   \item \code{midLengths}: a vector of the mid lengths of the length groups,
#'   \item \code{Linf}: infinite length for investigated species in cm [cm],
#'   \item \code{K}: growth coefficent for investigated species per year [1/year],
#'   \item \code{catch}: a matrix with the catches for different years.
#' }
#'
#' @source Sparre, P., Venema, S.C., 1998. Introduction to tropical fish stock assessment.
#'    Part 1. Manual. FAO Fisheries Technical Paper, (306.1, Rev. 2). 407 p.
#'
#' @usage data(synLFQ2)
#' @keywords data dataset length-frequency
#'
#' @examples
#' data(synLFQ2)
#' str(synLFQ2)
#' summary(synLFQ2)
#'
#'
NULL
