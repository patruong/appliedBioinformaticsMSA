library(reshape2)
library(dplyr)
library(ggplot2)
# read_distance(distance_file)
# INPUT: distance_file, List of paths to tsv with distance measurements
# OUTPUT: distance_df, dataframe with with MSA-file per row. Columns are methods used
## BRIEF: Merge all distance tsv files to one dataframe.
read_distances <- function(distance_files){
  for (filename in distance_files){
    if (!grepl("(REPORT|plots)", filename, perl = T)){
      print(filename)
      method_name <- gsub("_distance.tsv", "", tail(strsplit(filename, "/")[[1]], n=1))
      distance_table <- read.csv(filename, stringsAsFactors = FALSE, check.names = FALSE, sep ="\t")
      distance_table[method_name] <- distance_table$distance
      distance_table$distance   <- NULL
      distance_table$tree_label <- sapply(distance_table$tree_label,
                                          function(x) strsplit(x, "_")[[1]][1])
      if (exists("full_distance_table")){
        full_distance_table = merge(full_distance_table, distance_table, by="tree_label")
      } else {
        full_distance_table = distance_table
      }
    }
  }
  return(full_distance_table)
}

group_distance_data <- function(distance_df) {
  experiment_names <- names(distance_df)
  for (exp_name_path in experiment_names) {
    print(exp_name_path)
    exp_data <- distance_df[exp_name_path][[1]]
    exp_name <- sub("results/","", exp_name_path)
    entropy_cols <- grep("filter_entropy_", colnames(exp_data), value = T)
    entropy_data <- exp_data[, append(entropy_cols, "tree_label")]
    colnames(entropy_data) <- sub("filter_entropy_", "", colnames(entropy_data))
    entropy_data <- melt(entropy_data, id="tree_label", value.name="Distance") 
    entropy_data$Threshold <- as.numeric(as.character(entropy_data$variable))
    entropy_data$variable <- NULL
    entropy_data$Experiment <- rep(exp_name, nrow(entropy_data))
    if (exists("full_entropy_table")) {full_entropy_table <- bind_rows(full_entropy_table, entropy_data)}
    else {full_entropy_table <- entropy_data}
    
    exp_data$Experiment <- rep(exp_name, nrow(exp_data))
    
    unfilterd_cols <- c("tree_label", "unfiltered", "Experiment")
    if (exists("full_unfiltered_table")) {
      full_unfiltered_table <- bind_rows(full_unfiltered_table, exp_data[, unfilterd_cols])}
    else {full_unfiltered_table <- exp_data[, unfilterd_cols]}
    
    trimAl_cols <- c("tree_label", "trimAl", "Experiment")
    if (exists("full_trimAl_table")) {
      full_trimAl_table <- bind_rows(full_trimAl_table, exp_data[, trimAl_cols])}
    else {full_trimAl_table <- exp_data[, trimAl_cols]}
  }
  full_unfiltered_table$Distance <- full_unfiltered_table$unfiltered
  full_unfiltered_table$unfiltered <- NULL
  full_unfiltered_table$Method <- rep("Unfiltered", nrow(full_unfiltered_table))
  full_trimAl_table$Distance <- full_trimAl_table$trimAl
  full_trimAl_table$trimAl <- NULL
  full_trimAl_table$Method <- rep("TrimAl", nrow(full_trimAl_table))
  full_entropy_table$Method <- rep("Entropy Filter", nrow(full_entropy_table))

  merged_data = list(
    full_unfiltered_table,
    full_trimAl_table,
    full_entropy_table
  )
  names(merged_data) <- c("unfiltered", "trimAl", "entropy")
  return(merged_data)
}


#### RUN
input_dirs <- list.files("results", full.names = T)
input_files <- sapply(input_dirs, function(x) list.files(x, full.names = TRUE)) 
input_files <- input_files[!grepl("plots", names(input_files))]
distance_df <- sapply(input_files, read_distances)
#names(distance_df) <- input_dirs # To satisfy Rscript
print(input_dirs)
grouped_data <- group_distance_data(distance_df)

mean_sd_entropy <- group_by(grouped_data["entropy"][[1]], Threshold, Experiment)
mean_sd_entropy <- summarise(mean_sd_entropy, mean_dist = mean(Distance), sd_dist = sd(Distance))
mean_unfilterd <- group_by(grouped_data["unfiltered"][[1]], Experiment)
mean_unfilterd <- summarise(mean_unfilterd, mean_dist = mean(Distance), sd_dist=sd(Distance))
mean_unfilterd$my_text <- rep("Unfiltered Mean", nrow(mean_unfilterd))

# Distance diff
g <- ggplot(mean_sd_entropy, aes(x=Threshold, y=mean_dist, color=Experiment)) +
  geom_point() +
  geom_line() +
  geom_errorbar(aes(ymin = mean_dist-sd_dist, ymax = mean_dist+sd_dist),width=0.02) +
  geom_hline(data = mean_unfilterd, aes(yintercept=mean_dist, color=Experiment), linetype="dashed") +
  geom_hline(data = mean_unfilterd, aes(yintercept=mean_dist-sd_dist, color=Experiment), linetype="dashed") +
  geom_hline(data = mean_unfilterd, aes(yintercept=mean_dist+sd_dist, color=Experiment), linetype="dashed") +
  geom_text(data = mean_unfilterd, aes(x = 0.1, y=mean_dist -0.5, label=my_text), size = 3) +
  facet_grid(.~Experiment) +
  theme_bw() +
  geom_hline(aes(yintercept=0), linetype="dashed") +
  ggtitle(paste0("\u0394 Distance to true tree given entropy threshold")) +
  xlab("Entropy filter threshold") +
  ylab("\u0394 Robinson-Foulds distance") +
  theme(legend.position = "none")

ggsave("results/plots/mean_with_error_bars.png", g, width = 10, height = 5)

# Density
data <- bind_rows(grouped_data["unfiltered"][[1]], grouped_data["trimAl"][[1]])
gl <- ggplot(data, aes(x=Method, y=Distance, fill=Method)) +
  geom_violin() +
  facet_grid(.~Experiment) +
  theme_bw() +
  geom_hline(aes(yintercept=0), linetype="dashed") +
  ggtitle(paste0("\u0394 Distance to true tree given filter used")) +
  xlab("Method used") +
  ylab("\u0394 Robinson-Foulds distance") +
  theme(legend.position = "none")

ggsave("results/plots/distribution_of_distances_trimal.png", gl, width = 10, height = 5)
