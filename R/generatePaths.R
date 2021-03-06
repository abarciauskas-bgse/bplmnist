#' generatePaths
#' Accepts a list of thinned ints (digit skeletons) and returns a list of thinned ints' characteristics (see value)
#'
#' @param thinned.ints 
#' @param animation optional, whether path generation algorithm
#' @param sleep.time 
#'
#' @return List of each thinned int's characteristics as determined by the algorithm:
#'   number of strokes, path of points followed, direction steps (vector of 1-8 representing 8 directions possible from any one cell),
#'   changes in direction, and loops
#'   Used to make prediction on test sets.
#' @export
#'
#' @examples # coming soon
generatePaths <- function(thinned.ints, animation = FALSE, sleep.time = 0.5) {
  for (idx in 1:length(thinned.ints)) {
    new.int <- thinned.ints[[idx]]
    points <- new.int$points
    label <- new.int$label
    relativity = 'nearest'
    start <- points[nearorfar.from.origin(points, relativity),]
    unvisited <<- points
    current.pt <- start
    current.directions <- neighbors.directions(current.pt, unvisited)
    current.direction <- max(current.directions$directions)
    loops <- 0
    strokes <- 1
    thinned.ints[[idx]][['changes.in.direction']] <- 0
    thinned.ints[[idx]][['direction.steps']] <- list()
    thinned.ints[[idx]][['direction.steps']][[strokes]] <- c(current.direction)
    path <- matrix(current.pt, nrow = 1, ncol = 2, byrow = TRUE)
    if (animation) {
      plot(points, pch = 19, ylim = c(-16,0), xlim = c(0,16))
      Sys.sleep(sleep.time)
    }
    
    while (!is.null(nrow(unvisited))) {
      if (animation) {
        plot.point(current.pt, color = 'orange')
        Sys.sleep(sleep.time)
      }
      (pt.in.graph <- relative.pt(path, current.pt, current.direction))
      new.pt <- NA

      if (all(is.na(pt.in.graph))) {
        # step in the same direction
        new.pt <- relative.pt(unvisited, current.pt, current.direction)
        if (!all(is.na(new.pt))) {
          thinned.ints[[idx]][['direction.steps']][[strokes]] <- append(
            thinned.ints[[idx]][['direction.steps']][[strokes]], current.direction)
        }
      } else {
        if (loops > 3) break
        loops <- loops + 1
        # check if we should be doing this at all
        new.pt <- nearest.point(current.pt, unvisited)
        current.directions <- neighbors.directions(new.pt, unvisited)
        current.direction <- max(current.directions$directions)
      }
      
      # if still nothing, find new direction
      if (all(is.na(new.pt))) {
        current.directions <- neighbors.directions(current.pt, unvisited)
        current.direction <- current.directions$directions[which.min(abs(current.directions$directions - current.direction))]
        new.pt <- relative.pt(unvisited, current.pt, current.direction)
        if (!all(is.na(new.pt))) {
          # started new direction, but still in current stroke
          thinned.ints[[idx]][['direction.steps']][[strokes]] <- append(
            thinned.ints[[idx]][['direction.steps']][[strokes]], current.direction)
        }
        thinned.ints[[idx]][['changes.in.direction']] <- thinned.ints[[idx]][['changes.in.direction']] + 1
      } else {
        if (!is.null(nrow(current.directions$neighbors))) {
          apply(current.directions$neighbors, 1, function(r) {
            if (!is.null(nrow(unvisited))) {
              r <- row.match(r, unvisited)
              if (!is.na(r)) unvisited <<- unvisited[-r,]
            }
          })
        } else {
          r <- row.match(current.directions$neighbors, unvisited)
          if (!is.na(r)) unvisited <<- unvisited[-r,]
        }
      }
      if (all(is.na(new.pt))) {
        #if (strokes > 4) break
        strokes <- strokes + 1
        # toggle
        #relativity <- ifelse(relativity == 'nearest', 'furthest', 'nearest')
        # FIXME: we do this in 2-3 places to start / restart
        new.pt <- unvisited[nearorfar.from.origin(unvisited, relativity),]
        current.directions <- neighbors.directions(new.pt, unvisited)
        current.direction <- max(current.directions$directions)
        if (!all(is.na(new.pt))) {
          # new stroke, new direction
          thinned.ints[[idx]][['direction.steps']][[strokes]] <- c(current.direction)
        }
      } 
      
      if (!is.null(nrow(unvisited))) {
        r <- row.match(current.pt, unvisited)
        if (!is.na(r)) unvisited <<- unvisited[-r,]
      }
      
      # update
      if (all(is.na(new.pt))) {
        break
      } else {
        path <- rbind(path, new.pt)
        current.pt <- new.pt
      }
    }
    
    thinned.ints[[idx]]['loops'] <- loops
    thinned.ints[[idx]]['strokes'] <- strokes
    thinned.ints[[idx]]['path'] <- list(path)
  }
  return(thinned.ints)
}
