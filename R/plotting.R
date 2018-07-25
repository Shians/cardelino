# Plotting functions

# Functions for heatmap plots

#' Plot a heatmap for probability of clone assignment
#'
#' @param prob_mat A matrix (M x K), the probability of cell j to clone k
#' @param threshold A float value, the threshold for assignable cells
#' @param mode A string, the mothod for defining scores for filtering cells:
#' best and delta. best: highest probability of a cell to K clones, delta: the
#' difference between the best and second.
#'
#' @param cell_idx A vector the indices of the input cells. If NULL, order by
#' the probabilty of each clone
#'
#' @export
#'
#' @examples
#' data(example_donor)
#' assignments <- clone_id(A, D, C = tree$Z)
#' prob_heatmap(assignments$prob)
#'
prob_heatmap <- function(prob_mat, threshold=0.5, mode="delta", cell_idx=NULL){
    cell_label <- cardelino::get_prob_label(prob_mat)
    prob_value <- cardelino::get_prob_value(prob_mat, mode = mode)
    # add clone id
    colnames(prob_mat) <- paste0("C", seq_len(ncol(prob_mat)))
    for (i in seq_len(ncol(prob_mat))) {
        conf_frac <- mean(cell_label[prob_value >= threshold] == i)
        colnames(prob_mat)[i] <- paste0("C", i, ": ",
                                        round(conf_frac * 100, digits = 1), "%")
    }

    if (is.null(cell_idx)) {
        cell_idx <- order(cell_label - diag(prob_mat[, cell_label]))
    }
    nba.m <- reshape2::melt(prob_mat[cell_idx,])
    colnames(nba.m) <- c("Cell", "Clone", "Prob")

    fig_assign <- ggplot(nba.m, aes_string("Clone", "Cell", fill = "Prob")) +
        geom_tile(show.legend = TRUE) +
        scale_fill_gradient(low = "white", high = "firebrick4") +
        ylab(paste("Clonal assignment:", nrow(prob_mat), "cells")) +
        cardelino::heatmap.theme() # + cardelino::pub.theme()

    fig_assign
}


#' Plot a heatmap for number of mutation sites in each cell
#'
#' @param Config A matrix (N x K), clonal genotype configuration
#' @param prob_mat A matrix (M x K), the probability of cell j to clone k
#' @param A A matrix (N x M), the present of alternative reads. NA means missing
#' @param mode A string: present or absent
#'
#' @export
sites_heatmap <- function(Config, A, prob_mat, mode="present"){
    mut_label <- Config %*% (2**seq(ncol(Config),1))
    mut_label <- seq(length(unique(mut_label)),1)[as.factor(mut_label)]
    mut_uniq <- sort(unique(mut_label))

    A_cnt <- A
    if (mode == "absent") {
        A_cnt[is.na(A_cnt)] <- 1
        A_cnt[which(A_cnt > 0)] <- 1
        A_cnt <- 1 - A_cnt
    } else {
        A_cnt[is.na(A_cnt)] <- 0
        A_cnt[which(A_cnt > 0)] <- 1
    }

    mut_mat <- matrix(0, nrow = ncol(A_cnt), ncol = length(mut_uniq))
    for (i in seq_len(length(mut_uniq))) {
        idx.tmp <- mut_label == mut_uniq[i]
        mut_mat[,i] <- colSums(A_cnt[idx.tmp, ])
    }
    colnames(mut_mat) <- paste0("Mut", mut_uniq, ": ", table(mut_label))
    print(table(mut_label))

    #order by assignment probability
    cell_label <- cardelino::get_prob_label(prob_mat)
    idx <- order(cell_label - diag(prob_mat[, cell_label]))
    mut_mat <- mut_mat[idx,]

    nba.m <- reshape2::melt(mut_mat)
    colnames(nba.m) <- c("Cell", "Mut", "Sites")

    fig_sites <- ggplot(nba.m, aes_string("Mut", "Cell", fill = "Sites")) +
        geom_tile(show.legend = TRUE) +
        scale_fill_gradient(low = "white", high = "darkblue") +
        ylab(paste("Total sites: ", nrow(prob_mat), "cells")) +
        cardelino::heatmap.theme()# + cardelino::pub.theme()

    fig_sites
}


#' Plot confusion heatmap for assessing simulation accuracy
#'
#' @param prob_mat A matrix (M x K), the estimated probability of cell j to
#' clone k
#' @param sim_mat A matrix (M x K), the true assignment of cell to clone
#' @param threshold A float value, the threshold for assignable cells
#' @param mode A string, the mothod for defining scores for filtering cells:
#' best and delta. best: highest probability of a cell to K clones, delta: the
#' difference between the best and second.
#' @param pre_title character, a prefix to be used for the plot's title.
#'
#' @export
confusion_heatmap <- function(prob_mat, sim_mat, threshold=0.5, mode="delta",
                              pre_title=""){
    assign_0 <- cardelino::get_prob_label(sim_mat)
    assign_1 <- cardelino::get_prob_label(prob_mat)
    prob_val <- cardelino::get_prob_value(prob_mat, mode = mode)
    idx <- prob_val >= threshold

    # print(paste("assignable:", mean(idx)))
    # print(paste("accuracy:", mean((assign_0 == assign_1)[idx])))
    # print(paste("overall acc:", mean(assign_0 == assign_1)))

    acc <- mean((assign_0 == assign_1)[idx])
    confusion_matrix <- as.data.frame(table(assign_0[idx], assign_1[idx]))
    colnames(confusion_matrix) <- c("Var1", "Var2", "Freq")
    confusion_matrix[["Freq_tidy"]] <- sprintf("%1.0f",
                                               confusion_matrix[["Freq"]])

    confusion.plot <- ggplot(data = confusion_matrix,
                             mapping = aes_string(x = "Var1", y = "Var2")) +
        geom_tile(aes_string(fill = "Freq"), colour = "grey") +
        xlab("True clone") + ylab("Estimated clone") +
        geom_text(aes_string(label = "Freq_tidy"), vjust = 0.5) +
        ggtitle(paste0(pre_title, sprintf("Acc=%.1f%%", acc * 100))) +
        scale_fill_gradient(low = "white", high = "steelblue") +
        theme_grey(base_size = 12) + pub.theme() +
        theme(legend.position = "none",
              panel.grid.major = element_blank(),
              panel.border = element_blank(),
              panel.background = element_blank(),
              axis.ticks.x = ggplot2::element_blank(),
              axis.ticks.y = ggplot2::element_blank())
    confusion.plot
}


#' The theme of heatmaps for prob_heatmap and sites_heatmap
#'
#' @param legend.position character, describes where to place legend on plot
#' (passed to \code{\link[ggplot2]{theme_gray}})
#' @param size numeric, base font size for plot (passed to
#' \code{\link[ggplot2]{theme_gray}})
#'
#' @export
heatmap.theme <- function(legend.position="bottom", size=12) {
    ggplot2::theme_gray(base_size = size) + ggplot2::theme(
        axis.text = ggplot2::element_text(size = size),
        axis.title = ggplot2::element_text(face = "bold", size = size),
        axis.title.x = ggplot2::element_blank(),
        axis.ticks.x = ggplot2::element_blank(),
        axis.ticks.y = ggplot2::element_blank(),
        axis.text.y = ggplot2::element_blank(),
        plot.title = ggplot2::element_text(face = "bold", size = size*1.3,
                                           hjust = 0.5),
        panel.grid.major = ggplot2::element_blank(),
        panel.border = ggplot2::element_blank(),
        panel.background = ggplot2::element_blank(),
        legend.position = legend.position,
        legend.title = ggplot2::element_text(size = size*1.1))
}


#' Plot a variant-cell heatmap for cell clonal assignment
#'
#' @param mat A matrix for heatmap: N variants x M cells. row and column will be
#' sorted automatically.
#' @param prob A matrix of probability of clonal assignment: M cells x K clones
#' @param Config A binary matrix of clonal Configuration: N variants x K clones
#' @param show_legend A bool value: if TRUE, show the legend
#'
#' @return a pheatmap object
#'
#' @import pheatmap
#' @import ggplot2
#'
#' @export
#'
#' @references
#' This function makes use of the \code{\link{pheatmap}} packages
#'
#' @examples
vc_heatmap <- function(mat, prob, Config, show_legend=FALSE){
    # sort variants
    mut_label <- Config %*% (2**seq(ncol(Config),1))
    mut_label <- seq(length(unique(mut_label)),1)[as.factor(mut_label)]
    idx_row <- order(mut_label - rowMeans(mat, na.rm = TRUE)*0.9 + 0.05)
    anno_row <- data.frame(Mut = as.factor(mut_label))
    row.names(anno_row) <- row.names(Config)

    # sort cells
    cell_label <- cardelino::get_prob_label(prob)
    idx_col <- order(cell_label - diag(prob[, cell_label]))
    anno_col <- data.frame(Clone = as.factor(cell_label),
                           Prob = diag(prob[, cell_label]))
    row.names(anno_col) <- row.names(prob)

    # order the variant-cell matrix
    mat <- mat[idx_row, ][, idx_col]
    anno_row <- anno_row[idx_row, , drop = FALSE]
    anno_col <- anno_col[idx_col, , drop = FALSE]
    gaps_col <- cumsum(table(anno_col[[1]]))
    gaps_row <- cumsum(table(anno_row[[1]]))

    # pheatmap
    fig <- pheatmap::pheatmap(mat, legend = show_legend,
                              cluster_rows = FALSE, cluster_cols = FALSE,
                              gaps_row = gaps_row, gaps_col = gaps_col,
                              annotation_row = anno_row, annotation_col = anno_col,
                              show_rownames = FALSE, show_colnames = FALSE)
    fig
}


## Functions for plotting phylogenetic trees

#' Plot a phylogenetic tree
#'
#' @param tree A phylgenetic tee object of class "phylo"
#' @param orient A string for the orientation of the tree: "v" (vertical) or "h"
#' (horizontal)
#'
#' @details This function plots a phylogenetic tree from an object of class "phylo", as
#' produced, for example, by the Canopy package.
#'
#' @return a ggtree object
#'
#' @import ggtree
#' @import ggplot2
#'
#' @author Davis McCarthy and Yuanhua Huang
#'
#' @export
#'
#' @references
#' This function makes use of the \code{\link{ggtree}} packages:
#'
#' Guangchuang Yu, David Smith, Huachen Zhu, Yi Guan, Tommy Tsan-Yuk Lam.
#' ggtree: an R package for visualization and annotation of phylogenetic trees with their covariates and other associated data. Methods in Ecology and Evolution 2017, 8(1):28-36, doi:10.1111/2041-210X.12628
#'
#' @examples
plot_tree <- function(tree, orient="h") {
    node_total <- max(tree$edge)
    node_shown <- ncol(tree$Z)
    node_hidden <- node_total - node_shown
    if (!is.null(tree$P)) {
        tree$tip.label[1:node_shown] = paste0("C", seq_len(node_shown), ": ",
                                              round(tree$P[, 1]*100, digits = 0), "%")
    }

    mut_ids <- 0
    mut_id_all <- tree$Z %*% (2**seq(ncol(tree$Z),1))
    mut_id_all <- seq(length(unique(mut_id_all)),1)[as.factor(mut_id_all)]

    branch_ids <- NULL
    for (i in seq_len(node_total)) {
        mut_num = sum(tree$sna[,3] == i)
        if (mut_num == 0) {
            if (i == node_shown + 1) {
                branch_ids = c(branch_ids, "Root")
            } else {
                branch_ids = c(branch_ids, "")
            }
        } else {
            mut_ids <- mut_ids + 1
            branch_ids = c(branch_ids,
                           paste0("M", mut_ids, ": ", mut_num, " SNVs"))
        }
    }
    pt <- ggtree::ggtree(tree)
    pt <- pt + ggplot2::geom_label(ggplot2::aes_string(x = "branch"),
                                   label = branch_ids, color = "firebrick")
    pt <- pt + ggplot2::xlim(-0, node_hidden + 0.5) +
        ggplot2::ylim(0.8, node_shown + 0.5) #the degree may not be 3
    if (orient == "v") {
        pt <- pt + ggtree::geom_tiplab(hjust = 0.39, vjust = 1.0) +
            ggplot2::scale_x_reverse() + ggplot2::coord_flip()
    } else {
        pt <- pt + ggtree::geom_tiplab(hjust = 0.0, vjust = 0.5)
    }
    pt
}


mut.label <- function(tree){
    SNA.label <- tree$sna[, 3]
    mut_ids <- 0
    branch_ids <- NULL
    for (i in seq_len(max(tree$edge))) {
        mut_num = sum(tree$sna[,3] == i)
        if (mut_num == 0) {
            branch_ids = c(branch_ids, "") #NA
        }
        else{
            mut_ids <- mut_ids + 1
            branch_ids = c(branch_ids, paste0("M", mut_ids, ": ", mut_num, " SNVs"))
            SNA.label[tree$sna[,3] == i] = branch_ids[length(branch_ids)]
        }
    }
    SNA.label
}


#' Define a publication-style plot theme
#'
#' @param size numeric, base font size for adapted ggplot2 theme
#'
#' @details This theme modifies the \code{\link[ggplot2]{theme_classic}} theme
#' in ggplot2.
#'
#' @export
pub.theme <- function(size = 12) {
    theme_classic(base_size = size) +
        ggplot2::theme(axis.text = ggplot2::element_text(size = size),
                       axis.title = ggplot2::element_text(
                           face = "bold", size = size),
                       plot.title = ggplot2::element_text(
                           face = "bold", size = size * 1.3, hjust = 0.5),
                       legend.title = ggplot2::element_text(size = size*1.1),
                       legend.text = ggplot2::element_text(size = size),
                       panel.grid.major = ggplot2::element_line(
                           size = 0.1, colour = "#d3d3d3")
        )
}