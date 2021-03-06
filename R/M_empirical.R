#' @title Empirical formulas for the estimation of natural mortality
#
#' @description Functions to calculate the instantaneous natural mortality rate (M)
#'      according to 10 different empirical formulas.
#'
#' @param Linf infinite total length (TL) from a von Bertalanffy
#'    growth curve in cm.
#' @param Winf infinite weight form a von Bertalanffy growth curve
#'    in wet weight-grams.
#' @param K_l is the growth coefficient (per year) from a von Bertalanffy growth
#'    curve for length.
#' @param K_w is the growth coefficient (per year) from a von Bertalanffy growth
#'    curve for weight.
#' @param temp average annual temperature at the surface in degrees centigrade.
#' @param tmax the oldest age observed for the species.
#' @param tm50 age when 50\% of the population is mature [year]
#'      ("age of massive maturation").
#' @param GSI gonadosomatic index (wet ovary weight over wet body weight).
#' @param Wdry total dry weight in grams.
#' @param Wwet total wet weight at mean length in grams.
#' @param Bl body length in cm.
#' @param schooling logical; if TRUE it is accounted for the schooling behaviour of
#'      the species. Default is FALSE.
#' @param method vector of method names. Any combination of following methods can
#'    be employed: "AlversonCarney", "Gislason", "GundersonDygert", "Hoenig",
#'    "Lorenzen", "Pauly_Linf", "Pauly_Winf", "PetersonWroblewski",
#'    "RikhterEfanov", "Roff". Please refer to Details to see which input parameters
#'    are required by each method.
#'
#' @keywords function mortality M
#'
#' @examples
#' M_empirical(Linf = 80, K_l = 0.5, temp = 25, tmax = 30,
#'      method = c("Pauly_Linf","Hoenig"))
#'
#' @source https://cran.r-project.org/web/packages/fishmethods/index.html
#'
#' @details Function adapted from the mortality function of the fishmethods package
#'     by Gary A. Nelson
#'     (https://cran.r-project.org/web/packages/fishmethods/index.html).
#'
#' Depending on the method different input parameters are required:
#' \itemize{
#'    \item \code{"AlversonCarney"} requires \code{K_l} and \code{tmax},
#'    \item \code{"Gislason"} requires \code{Linf}, \code{K_l} and \code{Bl},
#'    \item \code{"GundersonDygert"} requires \code{GSI},
#'    \item \code{"Hoenig"} requires \code{tmax},
#'    \item \code{"Lorenzen"} requires \code{Wwet},
#'    \item \code{"Pauly_Linf"} requires \code{Linf}, \code{K_l} and \code{temp},
#'    \item \code{"Pauly_Winf"} requires \code{Winf}, \code{K_w} and \code{temp},
#'    \item \code{"PetersonWroblewski"} requires \code{Wdry},
#'    \item \code{"RikhterEfanov"} requires \code{tm50},
#'    \item \code{"Roff"} requires \code{K_l} and \code{tm50}.
#' }
#' If accounting for schooling behaviour M is multiplied by 0.8 according to
#'    Pauly (1983).
#'
#' @return A matrix of M estimates.
#'
#' @references
#' Alverson, D. L. and M. J. Carney. 1975. A graphic review of the growth and decay
#' of population cohorts. J. Cons. Int. Explor. Mer 36: 133-143.
#'
#' Gislason, H., N. Daan, J. C. Rice, and J. G. Pope. 2010. Size, growth,
#' temperature and the natural mortality of marine fish. Fish and Fisheries 11: 149-158.
#'
#' Gunderson, D. R. and P. H. Dygert. 1988. Reproductive effort as a predictor
#' of natural mortality rate. J. Cons. Int. Explor. Mer 44: 200-209.
#'
#' Hoenig, J. M. 1983. Empirical use of longevity data to estimate mortality rates.
#' Fish. Bull. 82: 898-903.
#'
#' Lorenzen, K. 1996. The relationship between body weight and natural mortality in
#' juvenile and adult fish: a comparison of natural ecosystems and aquaculture.
#' J. Fish. Biol. 49: 627-647.
#'
#' Pauly, D. 1980. On the interrelationships between natural mortality,
#' growth parameters, and mean environmental temperature in 175 fish stocks.
#' J. Cons. Int. Explor. Mer: 175-192.
#'
#' Pauly, D., 1983. Some simple methods for the assessment of tropical fish stocks.
#' \emph{FAO Fish.Tech.Pap.}, (234): 52p. Issued also in French and Spanish
#'
#' Peterson, I. and J. S. Wroblewski. 1984. Mortality rate of fishes in the
#' pelagic ecosystem. Can. J. Fish. Aquat. Sci. 41: 1117-1120.
#'
#' Rikhter, V.A., and V.N. Efanov, 1976. On one of the approaches to estimation of natural
#' mortality of fish populations. \emph{ICNAF Res.Doc.}, 76/VI/8: 12p.
#'
#' Roff, D. A. 1984. The evolution of life history parameters in teleosts.
#' Can. J. Fish. Aquat. Sci. 41: 989-1000.
#'
#' Sparre, P., Venema, S.C., 1998. Introduction to tropical fish stock assessment.
#' Part 1. Manual. \emph{FAO Fisheries Technical Paper}, (306.1, Rev. 2). 407 p.
#'
#' @export

M_empirical <- function(Linf = NULL, Winf = NULL, K_l = NULL, K_w = NULL,
                        temp = NULL, tmax = NULL, tm50 = NULL, GSI = NULL,
                        Wdry = NULL, Wwet = NULL, Bl = NULL,
                        schooling = FALSE, method){

  if (any(method == "AlversonCarney") & any(is.null(tmax), is.null(K_l)))
    stop("AlversonCarney requires K_l and tmax")
  if (any(method == "Gislason") & any(is.null(Linf), is.null(K_l), is.null(Bl)))
    stop("Gislason requires Linf, K_l, and Bl")
  if (any(method == "GundersonDygert") & is.null(GSI))
    stop("GundersonDygert requires GSI")
  if (any(method == "Hoenig") & is.null(tmax))
    stop("Hoenig requires tmax")
  if (any(method == "Lorenzen") & is.null(Wwet))
    stop("Lorenzen requires Wwet")
  if (any(method == "Pauly_Linf") & any(is.null(Linf), is.null(K_l), is.null(temp)))
    stop("Pauly_Linf requires Linf, K_l, and temp")
  if (any(method == "Pauly_Winf") & any(is.null(Winf), is.null(K_w), is.null(temp)))
    stop("Pauly_Winf requires Winf, K_w, and temp")
  if (any(method == "PetersonWroblewski") & is.null(Wdry))
    stop("PetersonWroblewski requires Wdry")
  if (any(method == "RikhterEfanov") & any(is.null(tm50)))
    stop("RikhterEfanov requires K_l and tm50")
  if (any(method == "Roff") & any(is.null(tm50), is.null(K_l)))
    stop("Roff requires K_l and tm50")

  n <- length(method)
  if (any(method == "Hoenig"))
    n <- n + 1
  M_mat <- matrix(NA, n, 1L)
  dimnames(M_mat) <- list(rep(NA, n), c("M"))
  ind <- 0

  if(any(method == "AlversonCarney")){
    ind <- ind + 1
    # Alverson and Carney (1975)
    M_mat[ind, 1]  <- round((3 * K_l)/(exp(K_l * (0.38 * tmax)) - 1), 3)
    dimnames(M_mat)[[1]][ind] <- list("Alverson and Carney (1975)")
  }
  if(any(method == "Gislason")){
    ind <- ind + 1
    # Gislason et al. (2010)
    M_mat[ind, 1]  <- round(exp(0.55 - 1.61 * log(Bl) + 1.44 * log(Linf) + log(K_l)), 3)
    dimnames(M_mat)[[1]][ind] <- list("Gislason et al. (2010)")
  }
  if(any(method == "GundersonDygert")){
    ind <- ind + 1
    # Gunderson and Dygert (1988)
    M <- round(0.03 + 1.68 * GSI, 3)
    dimnames(M_mat)[[1]][ind] <- list("Gunderson and Dygert (1988)")
  }
  if(any(method == "Hoenig")){
    ind <- ind + 1
    # Hoenig (1983) - Joint Equation
    M_mat[ind, 1]  <- round(4.22/(tmax^0.982), 3)
    dimnames(M_mat)[[1]][ind] <- list("Hoenig (1983) - Joint Equation")

    ind <- ind + 1
    # Hoenig (1983) - Fish Equation
    M_mat[ind, 1]  <- round(exp(1.46 - 1.01 * log(tmax)), 3)
    dimnames(M_mat)[[1]][ind] <- list("Hoenig (1983) - Fish Equation")
  }
  if(any(method == "Lorenzen")){
    ind <- ind + 1
    # Lorenzen (1996)
    M_mat[ind, 1]  <- round(3 * (Wwet^-0.288), 3)
    dimnames(M_mat)[[1]][ind] <- list("Lorenzen (1996)")
  }
  if(any(method == "Pauly_Linf")){
    ind <- ind + 1
    M_mat[ind, 1]  <- round(10^(-0.0066 - 0.279 * log10(Linf) + 0.6543 * log10(K_l) + 0.4634 * log10(temp)), 3)  #exp( -0.0152 - 0.279 * log(Linf) + 0.6543 * log(K) + 0.463 * log(temp))
    dimnames(M_mat)[[1]][ind] <- list("Pauly (1980) - Length Equation")
    if(schooling == TRUE){
      M <- 0.8 * M
    }
  }
  if(any(method == "Pauly_Winf")){
    ind <- ind + 1
    M_mat[ind, 1]  <- round(10^(-0.2107 - 0.0824 * log10(Winf) + 0.6757 * log10(K_w) + 0.4627 * log10(temp)), 3)  #exp( -0.2107 - 0.0824 * log(Winf) + 0.6757 * log(K) + 0.4627 * log(temp))
    dimnames(M_mat)[[1]][ind] <- list("Pauly (1980) - Weight Equation")
    if(schooling == TRUE){
      M <- 0.8 * M
    }
  }
  if(any(method == "PetersonWroblewski")){
    ind <- ind + 1
    # Peterson and Wroblewski (1984)
    M_mat[ind, 1]  <- round(1.92 * (Wdry^-0.25), 3)
    dimnames(M_mat)[[1]][ind] <- list("Peterson and Wroblewski (1984)")
  }
  if(any(method == "RikhterEfanov")){
    ind <- ind + 1
    M_mat[ind, 1]  <- round(1.521 / ( tm50 ^ 0.720) - 0.155, 3)
    dimnames(M_mat)[[1]][ind] <- list("Pauly (1980) - Length Equation")
  }
  if(any(method == "Roff")){
    ind <- ind + 1
    # Roff (1984)
    M_mat[ind, 1]  <- round((3 * K_l)/(exp(K_l * tm50) - 1), 3)
    dimnames(M_mat)[[1]][ind] <- list("Roff (1984)")
  }

  return(M_mat)
}
