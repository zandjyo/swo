#' calculate effective sample size for age comps
#'
#' @param sim_data list of abundance by age data
#' @param og_data original abundance by age data (single list)
#' @param strata switch to perform analysis at regional or strata level (default = NULL)
#'
#' @return
#' @export
#'
#' @examples
ess_age <- function(sim_data, og_data, strata = NULL){
  
  if ("stratum" %in% names(og_data) & is.null(strata) |
      "stratum" %in% names(sim_data) & is.null(strata)) {
    stop("check your strata")
  }
  
  if (!is.null(strata)) {
  og_data %>%
    tidytable::mutate.(og_m = males / sum(males),
            og_f = females / sum(females),
            og_t = (males + females + unsexed) / 
              (sum(males) + sum(females) + sum(unsexed)),
            .by = c(year, species_code, stratum)) %>%
    tidytable::select.(year, species_code, stratum, age, og_m, og_f, og_t) -> og_prop
  
  sim_data %>%
    tidytable::mutate.(prop_m = males / sum(males),
            prop_f = females / sum(females),
            prop_t = (males + females + unsexed) / 
              (sum(males) + sum(females) + sum(unsexed)),
            .by = c(year, species_code, stratum)) %>%
    tidytable::left_join.(og_prop) %>%
    tidytable::mutate.(ess_f = sum(prop_f * (1 - prop_f)) / sum((prop_f - og_f)^2),
            ess_m = sum(prop_m * (1 - prop_m)) / sum((prop_m - og_m)^2),
            ess_t = sum(prop_t * (1 - prop_t)) / sum((prop_t - og_t)^2),
            .by = c(year, species_code, stratum)) %>%
    tidytable::pivot_longer.(cols = c(ess_f, ess_m, ess_t), names_to = "ess") %>%
    dplyr::group_by(year, species_code, stratum, ess, value) %>%
    dplyr::distinct(value)
  } else {
    og_data %>%
      tidytable::mutate.(og_m = males / sum(males),
                         og_f = females / sum(females),
                         og_t = (males + females + unsexed)/
                           (sum(males) + sum(females) + sum(unsexed)),
                         .by = c(year, species_code)) %>%
      tidytable::select.(year, species_code, age, og_m, og_f, og_t) -> og_prop
    
    sim_data %>%
      tidytable::mutate.(prop_m = males / sum(males),
                         prop_f = females / sum(females),
                         prop_t = (males + females + unsexed)/
                           (sum(males) + sum(females) + sum(unsexed)),
                         .by = c(year, species_code)) %>%
      tidytable::left_join.(og_prop) %>%
      tidytable::mutate.(ess_f = sum(prop_f * (1 - prop_f)) / sum((prop_f - og_f)^2),
                         ess_m = sum(prop_m * (1 - prop_m)) / sum((prop_m - og_m)^2),
                         ess_t = sum(prop_t * (1 - prop_t)) / sum((prop_t - og_t)^2),
                         .by = c(year, species_code)) %>%
      tidytable::pivot_longer.(cols = c(ess_f, ess_m, ess_t), names_to = "ess") %>%
      dplyr::group_by(year, species_code, ess, value) %>%
      dplyr::distinct(value)
  }
  
}