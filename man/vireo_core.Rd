% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/donor_id.R
\name{vireo_core}
\alias{vireo_core}
\title{Variational inference with a single run}
\usage{
vireo_core(A, D, K = NULL, GT = NULL, GT_prior = NULL,
  theta_prior = NULL, learn_theta = TRUE, check_doublet = TRUE,
  doublet_prior = NULL, check_doublet_iterative = FALSE,
  binary_GT = FALSE, min_iter = 20, max_iter = 200,
  epsilon_conv = 0.01, verbose = FALSE)
}
\arguments{
\item{A}{A matrix of integers. Number of alteration reads in SNP i cell j}

\item{D}{A matrix of integers. Number of reads depth in SNP i cell j}

\item{K}{An integer. The number of donors to infer if not given GT.}

\item{GT}{A matrix of integers for genotypes. The donor-SNP configuration.}

\item{GT_prior}{A matix of float, with the same size of GT_prob output, i.e.,
N*K-by-3 if there are 3 genotypes.}

\item{theta_prior}{A matrix of float with size 3-by-2. The beta prior for 
binomial parameters. If NULL as default, 
theta_prior = matrix(c(0.3, 3, 29.7, 29.7,  3, 0.3), nrow = 3)}

\item{learn_theta}{logical(1), if TRUE, update theat, otherwise use default.}

\item{check_doublet}{logical(1), if TRUE, check doublet, otherwise ignore.}

\item{doublet_prior}{A float or string. The mode or fraction of doublet_prior:
NULL and uniform will give uniform weight to all singlet donor and doublet 
donors. Auto or other string will use doublet_prior = N_cell / 100000. Float
between 0 and 1 will give doublet_prior as doublet_prior.}

\item{check_doublet_iterative}{logical(1), if TRUE, check doublet iteratively, 
otherwise only check once VB algorithm finishes.}

\item{binary_GT}{logical(1), if TRUE, use categorical GT, otherwise use GT 
probability.}

\item{min_iter}{A integer. The minimum number of iterations in VB algorithm.}

\item{max_iter}{A integer. The maximum number of iterations in VB algorithm.
The real iteration may finish earlier.}

\item{epsilon_conv}{A float. The threshold of lower bound increase for
detecting convergence.}

\item{verbose}{logical(1), If TRUE, output verbose information when running.}
}
\value{
a list containing
\code{logLik}, the log likelihood.
\code{theta}, a vector denoting the binomial parameters for each genotype.
\code{prob}, a matrix of posterior probability of cell assignment to donors.
The summary may less than 1, as there are some probabilities go to doublets.
\code{prob_doublet}, a matrix of posterior probability of cell assignment to
each inter-donor doublet.
\code{GT}, the input GT or a point estimate of genotype of donors. Note,
this may be not very accurate, especially for lowly expressed SNPs.
\code{GT_doublet}, the pair-wise doublet genotype based on GT.
}
\description{
Variational inference with a single run
}
\details{
Users should typically use \code{\link{vireo}} rather than this
lower-level function.
}
