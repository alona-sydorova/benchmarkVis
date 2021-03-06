#' @title Insert mlr benchmark object into benchmarkVis application
#'
#' @description
#' Create a dataframe useable within the benchmarkVis application out of an mlr benchmark object.
#' All important imformation will be exluded from the input object and transformed into a appropriate dataframe
#'
#' @param bmr a mlr benchmark result object
#' @return a dataframe with the benchmarkVis specific structure
#' @export
#' @examples
#' library(mlr)
#' lrns = list(makeLearner("classif.lda"), makeLearner("classif.rpart"))
#' rdesc = makeResampleDesc("Holdout")
#' bmr = benchmark(lrns, sonar.task, rdesc)
#' df = useMlrBenchmarkWrapper(bmr)
useMlrBenchmarkWrapper = function(bmr) {
  # General variables
  learner.count = length(bmr$learners)
  tasks.count = length(bmr$result)
  # Check details for each task
  problem.parameter = list()
  replication.parameter = list()
  for (i in 1:tasks.count) {
    # Add problem parameters
    problem.parameter[[i]] = list()
    problem.parameter[[i]]$target = bmr$results[[i]][[1]]$task.desc$target
    problem.parameter[[i]]$size = bmr$results[[i]][[1]]$task.desc$size
    # Add replication parameters
    replication.parameter[[i]] = list()
    replication.parameter[[i]]$iters = bmr$results[[i]][[1]]$pred$instance$desc$iters
  }
  # Add algorithm parameters
  algorithm.parameter = sapply(c(1:learner.count), function(i) {
    bmr$learners[[i]]$par.vals
  })
  # Create replication
  replication = sapply(c(1:tasks.count), function(i) {
    bmr$results[[i]][[1]]$pred$instance$desc$id
  })
  # Create dataframe
  df = data.frame(
    problem = rep(names(bmr$result), rep(learner.count, tasks.count)),
    algorithm = rep(names(bmr$learners), tasks.count),
    replication = rep(replication, rep(learner.count, tasks.count))
  )
  # Add lists
  df$problem.parameter = rep(problem.parameter, rep(learner.count, tasks.count))
  df$algorithm.parameter = rep(algorithm.parameter, tasks.count)
  df$replication.parameter = rep(replication.parameter, rep(learner.count, tasks.count))
  # Change order
  df = df[, c(1, 4, 2, 5, 3, 6)]
  # Add measures and replication results to dataframe
  replication.results = list()
  for (measure.nr in seq(bmr$measures)) {
    measure.list = list()
    replication.list = list()
    # Go through all tasks and learners
    for (i in 1:tasks.count) {
      for (j in 1:learner.count) {
        measure.list[[(i - 1) * learner.count + j]] = bmr$results[[i]][[j]]$aggr[[measure.nr]]
        replication.list[[(i - 1) * learner.count + j]] = bmr$results[[i]][[j]]$measures.test[[measure.nr +
            1]]
      }
    }
    # Save measures and replication results in dataframe
    df[[names(bmr$results[[1]][[1]]$aggr)[[measure.nr]]]] = sapply(measure.list, as.numeric)
    replication.results[[measure.nr]] = replication.list
  }
  # Add replication results here to get correct order in dataframe
  for (i in seq(replication.results)) {
    df[[paste("replication", names(bmr$results[[1]][[1]]$measures.test)[[i +
        1]], sep = ".")]] = replication.results[[i]]
  }
  # Return dataframe
  return(df)
}

#' @title Insert mlr benchmark RDS file into benchmarkVis application
#'
#' @description
#' Load the specified file and pass it on the the useMlrBenchmarkWrapper function.
#' Create a dataframe useable within the benchmarkVis application out of an mlr benchmark object.
#' All important imformation will be exluded from the input object and transformed into a appropriate dataframe
#'
#' @param input.file Path to the input mlr benchmark RDS file
#' @return a dataframe with the benchmarkVis specific structure
#' @export
useMlrBenchmarkFileWrapper = function(input.file) {
  bmr = readRDS(input.file)
  return(useMlrBenchmarkWrapper(bmr))
}
