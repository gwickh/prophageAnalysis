library(tidyverse)

project_path = "/Volumes/TraDIS_WhitchurchLab/PRO_Foodborne_Pseudomonas_Prophages/validation/"
setwd(project_path)

phage_predictions = read_csv(
  paste0(
    project_path,
    "similarity_matrix.csv"
    )
  )

phage_predictions$`..2` <- paste(
  phage_predictions$`predicted_prophage`,
  phage_predictions$...2
  )
phage_predictions$`species` <- phage_predictions$`..2`

phage_predictions <- phage_predictions[, -2]

metric <- list("predicted_size", "similarity")
for (k in metric) {
  assign(
    paste0("phage_predictions_", k),
    phage_predictions %>%
      pivot_longer(
        c(paste0(k, "_genomad"), 
          paste0(k, "_vibrant"), 
          paste0(k, "_phageboost"), 
          paste0(k, "_phastest"), 
          paste0(k, "_virsorter")
          ),
        names_to = "prediction_tool",
        values_to = paste0(k)
      ) %>%
      select(-c(3:7))
  )
}

phage_predictions_predicted_size$prediction_tool <- str_remove(
  phage_predictions_predicted_size$prediction_tool, 
  "predicted_size_"
  )
phage_predictions_similarity$prediction_tool <- str_remove(
  phage_predictions_predicted_size$prediction_tool,
  "similarity_"
  )

phage_predictions_long <- merge(
  phage_predictions_predicted_size, 
  phage_predictions_similarity, 
  by = c("predicted_prophage", "prediction_tool", "size")
)

ggplot(phage_predictions_long)+
geom_tile(
  aes(
    y = forcats::fct_rev(predicted_prophage),
    x = prediction_tool,
    fill = similarity
  )
)