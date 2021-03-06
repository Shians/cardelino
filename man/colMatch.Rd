% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/assessment.R
\name{colMatch}
\alias{colMatch}
\title{Column match between two matrices by the minimum mean abosolute difference}
\usage{
colMatch(A, B, force = FALSE)
}
\arguments{
\item{A}{The first matrix which will be matched}

\item{B}{The second matrix, the return index will be used on}

\item{force}{bool(1), If TRUE, force it to one-to-one match, which uses the
best match in all possible permutation of columns}
}
\value{
\code{idx}, the column index of B to be matched to A
}
\description{
Column match between two matrices by the minimum mean abosolute difference
}
