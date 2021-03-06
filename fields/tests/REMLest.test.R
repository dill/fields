 # fields is a package for analysis of spatial data written for
  # the R software environment .
  # Copyright (C) 2018
  # University Corporation for Atmospheric Research (UCAR)
  # Contact: Douglas Nychka, nychka@ucar.edu,
  # National Center for Atmospheric Research,
  # PO Box 3000, Boulder, CO 80307-3000
  #
  # This program is free software; you can redistribute it and/or modify
  # it under the terms of the GNU General Public License as published by
  # the Free Software Foundation; either version 2 of the License, or
  # (at your option) any later version.
  # This program is distributed in the hope that it will be useful,
  # but WITHOUT ANY WARRANTY; without even the implied warranty of
  # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  # GNU General Public License for more details.



############################################################################
#      Begin tests of Matern covaraince parameter estimate
# Note that in all tests the smoothness (nu) is fixed
# and only theta (range), sill ( rho) and nugget (sigma2) are considered. 
##########################################################################
suppressMessages(library(fields))

options( echo=FALSE)
test.for.zero.flag<-1

# ozone data as a test case
data( ozone2)
x<- ozone2$lon.lat
y<- ozone2$y[16,]
is.good <- !is.na( y)
x<- x[is.good,]
y<- y[is.good]
nu<- 1.5

# reduce  data set to speed calculations
x<-x[1:75,]
y<- y[1:75]

# testing REML formula as used in gcv.Krig

 loglmvn <- function(pars, nu, x, y) {
        N <- length(y)
        Tmatrix <- fields.mkpoly(x, 2)
        qr.T <- qr(Tmatrix)
        Q2 <- qr.yq2(qr.T, diag(1, N))
        ys <- t(Q2) %*% y
        N2 <- length(ys)
        lrho = pars[1]
        ltheta = pars[2]
        lsig2 = pars[3]
        d <- rdist(x, x)
        A <- exp(lrho)*(Matern(d, range = exp(ltheta), 
            smoothness = nu) + exp(lsig2)/exp(lrho) * diag(N))
        A <- t(Q2) %*% A %*% Q2
        A <- chol(A)
        w = backsolve(A, ys, transpose = TRUE)
        ycept <- (N2/2) * log(2 * pi) + sum(log(diag(A))) + (1/2) * 
            t(w) %*% w  
        
            return( ycept)
 }
 
 logProfilemvn <- function(lambda, theta, nu, x, y) {
   N <- length(y)
   Tmatrix <- fields.mkpoly(x, 2)
   qr.T <- qr(Tmatrix)
   Q2 <- qr.yq2(qr.T, diag(1, N))
   ys <- t(Q2) %*% y
   N2 <- length(ys)
      d <- rdist(x, x)
      print( dim ( d))
      print( dim (diag( 1, N) ))
   A <- (Matern(d, range = theta, 
              smoothness = nu) +  diag( 1, N)*lambda )
   A <- t(Q2) %*% A %*% Q2
   A <- chol(A)
   lnDetCov<-  sum( log(diag(A)))*2
   w = backsolve(A, ys, transpose = TRUE)
   rho.MLE<- sum( w^2)/N2
   REMLLike<- -1 * (-N2/2 - log(2 * pi) * (N2/2) - (N2/2) * log(rho.MLE) - 
                   (1/2) * lnDetCov)
   return( REMLLike)
 }   
 
out<- Krig( x,y, Covariance="Matern", smoothness= nu, theta= 2.0, method="REML"  )
pars<- c(log( out$rho.MLE), log( 2.0), log( out$shat.MLE^2) )
 REML0<- out$lambda.est[6,5]
 REML1<- loglmvn( pars,nu, x,y)
 REML2<- logProfilemvn( out$lambda, 2.0, nu, x,y)
test.for.zero( REML0, REML1, tol=2e-4, tag="sanity check 1 for REML from Krig")
test.for.zero( REML0, REML2,  tag= "sanity check 2 for REML from Krig")

##D hold1<- MaternGLS.test( x,y, nu)
##D hold2<- MaternGLSProfile.test( x,y,nu)
##D test.for.zero( hold1$pars[1], hold2$pars[1], tol=2e-5, tag="check REML rho")
##D test.for.zero( hold1$pars[2], hold2$pars[2], tol=2e-5, tag="check REML theta")
##D test.for.zero( hold1$pars[3], hold2$pars[3], tol=5e-6, tag=" check REML sigma2")

hold3<- MaternQR.test( x,y,nu)
hold4<- MaternQRProfile.test( x,y,nu)
test.for.zero( hold3$pars[1], hold4$pars[1], tol=1e-3, tag="check REML rho")
test.for.zero( hold3$pars[2], hold4$pars[2], tol=1e-3, tag="check REML theta")
test.for.zero( hold3$pars[3], hold4$pars[3], tol=.0002, tag=" check REML sigma2")

nu<- hold3$smoothness 
out1<- Krig( x,y, Covariance="Matern", theta=  hold3$pars[2],
                      smoothness=nu, method="REML")

# evaluate Profile at full REML MLE 
lam<- hold3$pars[3]/hold3$pars[1]
l1<-Krig.flplike( lam, out1)

# evaluate Profile at full REML MLE 
out2<-  Krig( x,y, Covariance="Matern", theta= hold4$pars[2],
                  smoothness=nu, method="REML")
lam<- hold4$pars[3]/hold4$pars[1]
l2<-Krig.flplike( lam, out2)

test.for.zero( l1,l2, tag="Profile likelihoods from Krig and optim")

hold5<- MLE.Matern( x,y,nu)
test.for.zero( hold5$llike,l2, tag="Profile likelihoods from Krig and golden search")

#hold6<- spatialProcess( x,y, smoothness=nu, theta= hold5$theta.MLE, REML=TRUE)

cat("done with Matern REML estimator tests where smoothness is fixed", fill=TRUE)
options( echo=TRUE)
