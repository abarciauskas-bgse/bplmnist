#' collect.digit.skeletons
#' Takes a list of MNIST digits, removes non-white pixels and
#' calls thin.points,the thinning algorithm for creating a pixel "skeleton"
#'
#' @param digits: list of MNIST digits to thin
#' @param limit: optional; in case entire list of MNIST digits is passed, can limit number passed to thinning algorithm
#'
#' @return thinned digits, pixel "skeletons"
#' @export
#'
#' @examples # coming soon
collect.digit.skeletons <- function(digits, limit = NA) {
  if (is.na(limit)) limit <- nrow(digits)
  digit.skeletons <- list()
  
  for (row.idx in 1:limit) {
    digit <- digits[row.idx,]
    label <- as.numeric(digit[1])

    features <- as.numeric(digit[2:ncol(digit)])
    pixels <- matrix(features, 16, 16, byrow = TRUE)
    pixels <- rotate(pixels)
    
    white.pixels <- which(pixels > (quantile(pixels, probs = c(0.73)) && 0), arr.ind = TRUE)
    
    if (!(length(white.pixels[,2]) == 0)) {
      white.pixels[,2] <- white.pixels[,2] - max(white.pixels[,2],0)
      # subtract greatest y value from all y values
      # so top is now x = 0 and we are in the 4th quadrant of xy
      colnames(white.pixels) <- c('x','y')
      
      iter <- 0
      max.iter <- 2
      while (iter < max.iter) {
        iter <- iter  + 1
        current.pt <- white.pixels[1,]
        white.pixels <- thin.points(current.pt, white.pixels)
      }
      digit.skeletons[[row.idx]] <- list(label=label, num.pixels=length(white.pixels), points = white.pixels)
    } else {
      digit.skeletons[[row.idx]] <- list(label=label, num.pixels=NA)
    }
  }
  return(digit.skeletons)
}
