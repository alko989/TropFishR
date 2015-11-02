#' @title Virtual Population Analysis (VPA)
#'
#' @description Virtual Population Analysis
#'
#' @param classes Midpoints of the length class as vector (length frequency data) or ages as vector (age composition data).
#' @param catch Catch as vector, or a matrix with catches of subsequent years if the catch curve with constat time intervals should be applied.
#' @param datatype Type of data which is used for analysis, either 'length' or 'age', for length frequency or age composition data, respectively
#' @param analysis.type Determines which type of assessment should be done, options: "VPA" for classical age-based VPA, "CA" for age- or length-based Cohort analysis
#' @param Linf Infinite length for investigated species in cm [cm].
#' @param K Growth coefficent for investigated species per year [1/year].
#' @param t0 Theoretical time zero, at which individuals of this species hatch.
#' @param catchCorFac optional: Correction factor for catch, in case provided catch does spatially or temporarily not reflect catch for fishing ground of a whole year.
#' @param M Natural mortality [1/year]
#' @param terminalF terminal fishing mortality
#' @param a length-weight relationship coefficent (W = a * L^b)
#' @param b length-weight relationship coefficent (W = a * L^b)
#'
#' @examples
#' #Jones' length-based Cohort analysis
#' data("ex.CohortAnalysis")
#' output <- with(ex.CohortAnalysis, VPA(classes = midLengths, catch = catch,
#'    Linf = 130, K = 0.1, M = 0.28,terminalF = 0.28,
#'    a = 0.00001, b = 3, datatype = 'length', analysis.type = "CA"))
#' output
#' #Virtual Popuation Analysis
#' data("ex.CatchCurve")
#' output <- with(ex.CatchCurve, VPA(classes = age, catch = ex.CatchCurve[,2:8],
#'    datatype = 'age', analysis.type = "VPA", terminalF = 0.5,
#'    M = 0.2, a = 0.00984, b = 2.926))
#' output
#' #Popes Cohort Analysis based on age-composition data
#' data("ex.CatchCurve")
#' output <- with(ex.CatchCurve, VPA(classes = age, catch = ex.CatchCurve[,2:8],
#'    datatype = 'age', analysis.type = "CA", terminalF = 0.5,
#'    M = 0.2, a = 0.00984, b = 2.926))
#' output
#' @details Cohort analysis
#'
#' @references
#' Jones ???  Sparre?
#' external reference for a and b in case of age composition data, because not provided by book:
#' Dorel, D., 1986. Poissons de l'Atlantique nord-est relations taille-poids. Institut Francais de Recherche pour l'Exploitation de la Mer. Nantes, France. 165 p.
#'
#' @export


VPA <- function(classes, catch, datatype, analysis.type, M, terminalF,
                           a, b, catchCorFac = NA, Linf = NA, K = NA, t0 = 0){

  # Error message if catch and age do not have same length
  if(class(catch) == 'matrix' | class(catch) == 'data.frame'){
    if(length(classes) != length(catch[,1])) stop("Ages and catch do not have the same length!")
  }else if(class(catch) == 'numeric'){
    if(length(classes) != length(catch)) stop("Ages and catch do not have the same length!")
  }

  df.VPA <- cbind(classes,catch)
  df.VPA <- as.data.frame(df.VPA)
  df.VPA$classes <- as.character(df.VPA$classes)

  # create column without plus group (sign) if present
  classes.num <- do.call(rbind,strsplit(df.VPA$classes, split="\\+"))
  df.VPA$classes.num <- as.numeric(classes.num[,1])


  if(datatype == 'age'){
    #HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH#
    #                       Original VPA                       #
    #HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH#
    if(analysis.type == 'VPA'){

      if(class(catch) == 'matrix' | class(catch) == 'data.frame'){
        #find cohort to analyse
        real.cohort <- diag(as.matrix(catch))      ##CHECK!!! TAKES ALWAYS THE FIRST OBSERVATION IN FIRST COLUMN TO START FINDING REAL COHORT
        df.VPA$catch.cohort <- c(real.cohort,
                                 rep(NA,length(df.VPA$classes.num) - length(real.cohort)))
      }
      if(class(catch) == 'numeric'){
        df.VPA$catch.cohort <- catch
      }

      #Correct catch  if not representative for one year
      if(!is.na(catchCorFac)) df.VPA$catchCor.VPA <- df.VPA$catch.cohort * catchCorFac
      if(is.na(catchCorFac)) df.VPA$catchCor.VPA <- df.VPA$catch.cohort

      #Survivors    #N(L1)=(N(L2)*H(L1,L2)+C(L1,L2)) *H(L1,L2)
      df.VPA$survivors <- NA

      # survivors last size class
      lastLengthClass <- max(which(!is.na(df.VPA$catchCor.VPA)),na.rm=T)  ### CHECK!!!!: EXCLUDES THE LAST CLASSES WHICH ARE NA IN CATCH DUE TO TOO LESS YEARS SAMPLED!
      df.VPA$survivors[lastLengthClass] <-
        df.VPA$catchCor.VPA[lastLengthClass] / ((terminalF/(terminalF + M)) * (1 - exp(-(terminalF + M))))

      #other survivors and fishing mortality
      ###IMPROVABLE BY MAKING THE STEP CHOOSABLE, MEANING THE USER CAN CHOOSE THE RESOLUTION
      df.VPA$F <- NA
      df.VPA$F[lastLengthClass] <- terminalF

      for(num_class in (lastLengthClass-1):1){

        sur.C <- df.VPA$catchCor.VPA[num_class]
        sur.Ntplus1 <- df.VPA$survivors[(num_class+1)]
        sur.M <- M
        LHS <-  sur.C / sur.Ntplus1
        sur.F <- 0
        seqi <- c(1e-1,1e-2,1e-3,1e-4,1e-5,1e-6,1e-7)

        #trail and error
        for(y in seqi){
          stepi <- y
          for(x in seq(sur.F,10,stepi)){
            sur.F <- x
            RHS <- (sur.F/(sur.F + sur.M)) * (exp(sur.F+sur.M) - 1)
            if(LHS-RHS < 0) break
          }
          sur.F = x-stepi
        }

        #fill F
        df.VPA$F[num_class] <- sur.F

        #fill survivors
        df.VPA$survivors[num_class] <- df.VPA$survivors[(num_class+1)] *
          exp(sur.F + sur.M)
      }

      # Z
      df.VPA$Z <- NA
      for(x6 in 1:(length(df.VPA$Z))){
        df.VPA$Z[x6] <- M  +  df.VPA$F[x6]
      }

      #Annual mean Nr
      df.VPA$annualMeanNr <- NA
      for(x7 in 1:(length(df.VPA$annualMeanNr-1))){
        df.VPA$annualMeanNr[x7] <- (df.VPA$survivors[x7] -
                                      df.VPA$survivors[x7+1]) / df.VPA$Z[x7]
      }

      #Mean body weight
      df.VPA$meanBodyWeight <- a * df.VPA$classes.num ^ b

      #Mean biomass
      df.VPA$meanBiomass <- df.VPA$annualMeanNr * df.VPA$meanBodyWeight
      df.VPA$meanBiomassTon <- df.VPA$meanBiomass/1000

      #Yield
      df.VPA$yield <- df.VPA$catchCor.VPA * df.VPA$meanBodyWeight
      df.VPA$yieldTon <- df.VPA$yield/1000

      #FOR PLOT
      #Survivors rearranged
      df.VPA$survivors_rea <- NA
      for(x8 in 1:(length(df.VPA$survivors_rea)-1)){
        df.VPA$survivors_rea[x8] <- df.VPA$survivors[x8+1]
      }
      df.VPA$survivors_rea[length(df.VPA$survivors_rea)] <- 0

      #Calculate natural losses
      df.VPA$natLoss <- NA
      for(x9 in 1:length(df.VPA$natLoss)){
        df.VPA$natLoss[x9] <- df.VPA$survivors[x9] - df.VPA$survivors_rea[x9] -
          df.VPA$catchCor.VPA[x9]
      }

      #put together in dataframe
      df.VPAnew <- data.frame(survivors = df.VPA$survivors_rea,
                              nat.losses = df.VPA$natLoss,
                              catch = df.VPA$catchCor.VPA)

      #transpose matrix for barplot function
      df.VPAnew <- t(as.matrix(df.VPAnew))
      colnames(df.VPAnew) <- df.VPA$classes.num

      #save x axis positions
      par(new = F)
      mids <- barplot(df.VPAnew, xlab="",
                      ylim=c(0,(max(df.VPA$survivors,na.rm=T)+
                                  max(df.VPA$survivors,na.rm=T)/14)))

      #create CA plot
      par(mar = c(5, 4, 4, 4) + 0.3)
      barplot(df.VPAnew,col=c('darkgreen','purple','yellow'),
              ylim=c(0,(max(df.VPA$survivors,na.rm=T) + max(df.VPA$survivors,na.rm=T)/14)),
              axisnames = F,axis.lty = F,
              xlab = "Midlength [cm]", ylab = "Population" )                   #,names.arg = as.character(data$Midlength))#legend = rownames(data.new),
      legend(x=(length(mids)-1),y=max(df.VPA$survivors,na.rm=T),
             legend = c(rownames(df.VPAnew),"Fishing mortality"),
             fill = c('darkgreen','purple','yellow',NA),col='red',bty='n',
             cex=0.8, xpd = T, #text.width = 30,
             x.intersp = c(0.3,0.3,0.3,0.3),y.intersp = 0.5,xjust=0, yjust = 0.8,
             lty = c(NA,NA,NA,1),lwd=3,merge=T,border = c(T,T,T,F), pt.cex = 10,
             seg.len = 0.6)
      axis(1,at=mids[seq(1,length(mids),3)],
           labels=df.VPA$classes.num[seq(1,length(df.VPA$classes.num),3)],
           tick = F)
      par(new = TRUE)
      plot(df.VPA$classes.num, df.VPA$F, type = "l", col='red',lwd=4,
           axes = FALSE, bty = "n", xlab = "", ylab = "")
      axis(side=4, at = pretty(range(df.VPA$F)))
      mtext("Fishing mortatlity", side=4, line=3)
      plot1 <- recordPlot()

      #save all in list
      results.VPA <- list()
      results.VPA[[1]] <- df.VPA
      results.VPA[[2]] <- df.VPAnew
      results.VPA[[3]] <- plot1
      names(results.VPA) <- c("Dataframe","Plotting_dataframe","Plot")

      return(results.VPA)
    }

    #HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH#
    #   Age-based Cohort Analysis (Pope's cohort analysis)     #
    #HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH#
    if(analysis.type == 'CA'){

      if(class(catch) == 'matrix' | class(catch) == 'data.frame'){
        #find cohort to analyse
        real.cohort <- diag(as.matrix(catch))      ##CHECK!!! TAKES ALWAYS THE FIRST OBSERVATION IN FIRST COLUMN TO START FINDING REAL COHORT
        df.VPA$catch.cohort <- c(real.cohort,
                                 rep(NA,length(df.VPA$classes.num) - length(real.cohort)))
      }
      if(class(catch) == 'numeric'){
        df.VPA$catch.cohort <- catch
      }

      #Correct catch  if not representative for one year
      if(!is.na(catchCorFac)) df.VPA$catchCor.VPA <- df.VPA$catch.cohort * catchCorFac
      if(is.na(catchCorFac)) df.VPA$catchCor.VPA <- df.VPA$catch.cohort

      #Survivors    #N(L1)=(N(L2)*H(L1,L2)+C(L1,L2)) *H(L1,L2)
      df.VPA$survivors <- NA

      # survivors last size class
      lastLengthClass <- max(which(!is.na(df.VPA$catchCor.VPA)),na.rm=T)  ### CHECK!!!!: EXCLUDES THE LAST CLASSES WHICH ARE NA IN CATCH DUE TO TOO LESS YEARS SAMPLED!
      df.VPA$survivors[lastLengthClass] <-
        df.VPA$catchCor.VPA[lastLengthClass] / ((terminalF/(terminalF + M)) * (1 - exp(-(terminalF + M))))
      # other survivors
      for(x3 in (lastLengthClass-1):1){
        df.VPA$survivors[x3] <- (df.VPA$survivors[x3+1] * exp((M/2)) +
                                   df.VPA$catchCor.VPA[x3] ) * exp((M/2))
      }

      #F
      df.VPA$F <- NA
      df.VPA$F[lastLengthClass] <- terminalF
      for(x5 in 1:(lastLengthClass-1)){
        df.VPA$F[x5] <- log(df.VPA$survivors[x5]/df.VPA$survivors[x5+1]) - M
      }

      # Z
      df.VPA$Z <- NA
      for(x6 in 1:(length(df.VPA$Z))){
        df.VPA$Z[x6] <- M  +  df.VPA$F[x6]
      }

      #Annual mean Nr
      df.VPA$annualMeanNr <- NA
      for(x7 in 1:(length(df.VPA$annualMeanNr-1))){
        df.VPA$annualMeanNr[x7] <- (df.VPA$survivors[x7] -
                                      df.VPA$survivors[x7+1]) / df.VPA$Z[x7]
      }

      #Mean body weight
      df.VPA$meanBodyWeight <- a * df.VPA$classes.num ^ b

      #Mean biomass
      df.VPA$meanBiomass <- df.VPA$annualMeanNr * df.VPA$meanBodyWeight
      df.VPA$meanBiomassTon <- df.VPA$meanBiomass/1000

      #Yield
      df.VPA$yield <- df.VPA$catchCor.VPA * df.VPA$meanBodyWeight
      df.VPA$yieldTon <- df.VPA$yield/1000

      #FOR PLOT
      #Survivors rearranged
      df.VPA$survivors_rea <- NA
      for(x8 in 1:(length(df.VPA$survivors_rea)-1)){
        df.VPA$survivors_rea[x8] <- df.VPA$survivors[x8+1]
      }
      df.VPA$survivors_rea[length(df.VPA$survivors_rea)] <- 0

      #Calculate natural losses
      df.VPA$natLoss <- NA
      for(x9 in 1:length(df.VPA$natLoss)){
        df.VPA$natLoss[x9] <- df.VPA$survivors[x9] - df.VPA$survivors_rea[x9] -
          df.VPA$catchCor.VPA[x9]
      }

      #put together in dataframe
      df.VPAnew <- data.frame(survivors = df.VPA$survivors_rea,
                              nat.losses = df.VPA$natLoss,
                              catch = df.VPA$catchCor.VPA)

      #transpose matrix for barplot function
      df.VPAnew <- t(as.matrix(df.VPAnew))
      colnames(df.VPAnew) <- df.VPA$classes.num

      #save x axis positions
      par(new = F)
      mids <- barplot(df.VPAnew, xlab="",
                      ylim=c(0,(max(df.VPA$survivors,na.rm=T)+
                                  max(df.VPA$survivors,na.rm=T)/14)))

      #create VPA plot
      par(mar = c(5, 4, 4, 4) + 0.3)
      barplot(df.VPAnew,col=c('darkgreen','purple','yellow'),
              ylim=c(0,(max(df.VPA$survivors,na.rm=T) + max(df.VPA$survivors,na.rm=T)/14)),
              axisnames = F,axis.lty = F,
              xlab = "Midlength [cm]", ylab = "Population" )                   #,names.arg = as.character(data$Midlength))#legend = rownames(data.new),
      legend(x=(length(mids)-1),y=max(df.VPA$survivors,na.rm=T),
             legend = c(rownames(df.VPAnew),"Fishing mortality"),
             fill = c('darkgreen','purple','yellow',NA),col='red',bty='n',
             cex=0.8, xpd = T, #text.width = 30,
             x.intersp = c(0.3,0.3,0.3,0.3),y.intersp = 0.5,xjust=0, yjust = 0.8,
             lty = c(NA,NA,NA,1),lwd=3,merge=T,border = c(T,T,T,F), pt.cex = 10,
             seg.len = 0.6)
      axis(1,at=mids[seq(1,length(mids),3)],
           labels=df.VPA$classes.num[seq(1,length(df.VPA$classes.num),3)],
           tick = F)
      par(new = TRUE)
      plot(df.VPA$classes.num, df.VPA$F, type = "l", col='red',lwd=4,
           axes = FALSE, bty = "n", xlab = "", ylab = "")
      axis(side=4, at = pretty(range(df.VPA$F)))
      mtext("Fishing mortatlity", side=4, line=3)
      plot1 <- recordPlot()

      #save all in list
      results.VPA <- list()
      results.VPA[[1]] <- df.VPA
      results.VPA[[2]] <- df.VPAnew
      results.VPA[[3]] <- plot1
      names(results.VPA) <- c("Dataframe","Plotting_dataframe","Plot")

      return(results.VPA)
    }
  }


  #HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH#
  #           Jones' Length-based Cohort Analysis            #
  #HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH#
  if(datatype == 'length' &
     (class(catch) == 'matrix' |
      class(catch) == 'data.frame')) stop("The length-based Cohort analysis
                                          is not applicable to length frequency data.
                                          Please provide catch as vector.")

  if(datatype == 'length' & analysis.type == "VPA") stop("Please choose
                                                         analysis.type = 'CA' for
                                                         length composition data!")

  if(class(catch) == 'numeric' & datatype == 'length' & analysis.type == "CA"){
    #calculate size class interval
    interval.VPA <- df.VPA$classes.num[2] - df.VPA$classes.num[1]

    # t of lower length classes
    df.VPA$lowerLength.VPA <- df.VPA$classes.num - (interval.VPA / 2)
    if(!is.na(catchCorFac)) df.VPA$catchCor.VPA <- df.VPA$catch * catchCorFac
    if(is.na(catchCorFac)) df.VPA$catchCor.VPA <- df.VPA$catch
    df.VPA$t_L1 <- (t0 - (1/K)) * log(1 - (df.VPA$lowerLength.VPA / Linf))

    # delta t
    df.VPA$dt <- NA
    for(x1 in 1:(length(df.VPA$dt)-1)){
      df.VPA$dt[x1] <- df.VPA$t_L1[x1+1] - df.VPA$t_L1[x1]
    }

    # t of midlengths
    df.VPA$t_midL <- (t0 - (1/K)) * log(1 - (df.VPA$classes.num / Linf))

    # H (L1,L2)   #H(L1,L2)=((Linf-L1)/Linf-L2)^(M/2K)
    df.VPA$H <- NA
    for(x2 in 1:(length(df.VPA$H)-1)){
      df.VPA$H[x2] <- ((Linf - df.VPA$lowerLength.VPA[x2]) /
                         (Linf - df.VPA$lowerLength.VPA[x2+1])) ^
        (M / (2*K))
    }

    #Survivors    #N(L1)=(N(L2)*H(L1,L2)+C(L1,L2)) *H(L1,L2)
    df.VPA$survivors <- NA

    # survivors last size class
    df.VPA$survivors[length(df.VPA$survivors)] <-
      df.VPA$catchCor.VPA[length(df.VPA$survivors)] / (terminalF/(terminalF + M))
    # other survivors
    for(x3 in (length(df.VPA$survivors)-1):1){
      df.VPA$survivors[x3] <- (df.VPA$survivors[x3+1] *
                                 df.VPA$H[x3] + df.VPA$catchCor.VPA[x3] ) *
        df.VPA$H[x3]
    }

    # F/Z  #F(L1,L2)/Z(L1,L2)=C(L1,L2)/(N(L1)-N(L2))
    df.VPA$F_Z <- NA
    for(x4 in 1:(length(df.VPA$F_Z)-1)){
      df.VPA$F_Z[x4] <- df.VPA$catchCor.VPA[x4] /
        (df.VPA$survivors[x4] - df.VPA$survivors[x4+1])
    }
    df.VPA$F_Z[length(df.VPA$F_Z)] <- terminalF / (terminalF + M)

    #F  # F = M * (F_Z / 1-F_Z)
    df.VPA$F <- NA
    for(x5 in 1:(length(df.VPA$F))){
      df.VPA$F[x5] <- M  *  (df.VPA$F_Z[x5] / (1 - df.VPA$F_Z[x5]))
    }

    # Z
    df.VPA$Z <- NA
    for(x6 in 1:(length(df.VPA$Z))){
      df.VPA$Z[x6] <- M  +  df.VPA$F[x6]
    }

    #Annual mean Nr
    df.VPA$annualMeanNr <- NA
    for(x7 in 1:(length(df.VPA$annualMeanNr-1))){
      df.VPA$annualMeanNr[x7] <- (df.VPA$survivors[x7] -
                                    df.VPA$survivors[x7+1]) / df.VPA$Z[x7]
    }

    #Mean body weight
    df.VPA$meanBodyWeight <- a * df.VPA$classes.num ^ b

    #Mean biomass
    df.VPA$meanBiomass <- df.VPA$annualMeanNr * df.VPA$meanBodyWeight
    df.VPA$meanBiomassTon <- df.VPA$meanBiomass/1000

    #Yield
    df.VPA$yield <- df.VPA$catchCor.VPA * df.VPA$meanBodyWeight
    df.VPA$yieldTon <- df.VPA$yield/1000

    #FOR PLOT
    #Survivors rearranged
    df.VPA$survivors_rea <- NA
    for(x8 in 1:(length(df.VPA$survivors_rea)-1)){
      df.VPA$survivors_rea[x8] <- df.VPA$survivors[x8+1]
    }
    df.VPA$survivors_rea[length(df.VPA$survivors_rea)] <- 0

    #Calculate natural losses
    df.VPA$natLoss <- NA
    for(x9 in 1:length(df.VPA$natLoss)){
      df.VPA$natLoss[x9] <- df.VPA$survivors[x9] - df.VPA$survivors_rea[x9] -
        df.VPA$catchCor.VPA[x9]
    }

    #put together in dataframe
    df.VPAnew <- data.frame(survivors = df.VPA$survivors_rea,
                            nat.losses = df.VPA$natLoss,
                            catch = df.VPA$catchCor.VPA)

    #transpose matrix for barplot function
    df.VPAnew <- t(as.matrix(df.VPAnew))
    colnames(df.VPAnew) <- df.VPA$classes.num

    #save x axis positions
    par(new = F)
    mids <- barplot(df.VPAnew, xlab="",
                    ylim=c(0,(max(df.VPA$survivors,na.rm=T)+
                                max(df.VPA$survivors,na.rm=T)/14)))

    #create CA plot
    par(mar = c(5, 4, 4, 4) + 0.3)
    barplot(df.VPAnew,col=c('darkgreen','purple','yellow'),
            ylim=c(0,(max(df.VPA$survivors) + max(df.VPA$survivors)/14)),
            axisnames = F,axis.lty = F,
            xlab = "Midlength [cm]", ylab = "Population" )                   #,names.arg = as.character(data$Midlength))#legend = rownames(data.new),
    legend('topright',legend = c(rownames(df.VPAnew),"Fishing mortality"),
           fill = c('darkgreen','purple','yellow',NA),col='red',
           cex=0.9, xpd = T, text.width = 10,
           x.intersp = c(0.5,0.5,0.5,0.6),y.intersp = 1.4,
           lty = c(NA,NA,NA,1),lwd=3,merge=T,border = c(T,T,T,F),
           seg.len = 0.8)
    axis(1,at=mids[seq(1,length(mids),3)],
         labels=df.VPA$classes.num[seq(1,length(df.VPA$classes.num),3)],
         tick = F)
    par(new = TRUE)
    plot(df.VPA$classes.num, df.VPA$F, type = "l", col='red',lwd=4,
         axes = FALSE, bty = "n", xlab = "", ylab = "")
    axis(side=4, at = pretty(range(df.VPA$F)))
    mtext("Fishing mortatlity", side=4, line=3)
    plot1 <- recordPlot()

    #save all in list
    results.VPA <- list()
    results.VPA[[1]] <- df.VPA
    results.VPA[[2]] <- df.VPAnew
    results.VPA[[3]] <- plot1
    names(results.VPA) <- c("Dataframe","Plotting_dataframe","Plot")

    return(results.VPA)
  }
}




