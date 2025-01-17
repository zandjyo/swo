#' population at length
#'
#' @param lcomp length comp
#' @param cpue cpue data
#' @param lngs complete lengths by year
#'
#' @return
#' @export
#'
#' @examples
lpop <- function(lcomp, cpue, lngs) {
  lcomp %>%
    tidytable::summarise.(comp = sum(comp) / mean(nhauls), 
                          .by = c(year, species_code, stratum, sex, length)) -> .unk
  
  # id hauls without lengths
  cpue %>%
    tidytable::filter.(!is.na(catchjoin), 
                       !(hauljoin %in% lcomp$hauljoin)) -> .no_length
  
  cpue %>%
    tidytable::mutate.(st_num = mean(numcpue) * area,
                       tot = sum(numcpue), 
                       .by = c(year, species_code, stratum)) %>%
    tidytable::summarise.(abund = mean(numcpue) / tot * st_num,
                          .by = c(year, species_code, stratum, hauljoin)) -> .pop
  
  # if there are any samples w/o lengths rejoin them
  if(nrow(.no_length) == 0){
    lcomp %>%
      tidytable::left_join.(.pop) %>%
      tidytable::mutate.(sz_pop = round(comp * abund, 0)) -> .temp
  } else {
    .no_length %>%
      tidytable::left_join.(.unk) %>%
      tidytable::select.(year, species_code, stratum, hauljoin, sex, length, comp) %>%
      tidytable::bind_rows.(lcomp) %>%
      tidytable::left_join.(.pop) %>%
      tidytable::mutate.(sz_pop = round(comp * abund, 0)) -> .temp
  }
  
  .temp %>%
    dplyr::group_by(year, species_code) %>%
    dplyr::count(sex) %>%
    tidytable::filter.(sex == 3) %>%
    tidytable::select.(year, species_code, n) -> .sex_cnt_sz
  
  if(length(.sex_cnt_sz$n)>0){
    .temp %>%
      tidytable::summarise.(abund = sum(sz_pop, na.rm = T), 
                            .by = c(year, species_code, length, sex)) %>%
      tidytable::pivot_wider.(names_from = sex, values_from = abund) %>%
      tidytable::left_join.(lngs, .) %>%
      tidytable::mutate.(across.(.cols = c(`1`, `2`, `3`), ~tidytable::replace_na.(.x, 0))) %>%
      tidytable::select.(year, species_code, length, males = `1`, females = `2`, unsexed = `3`) 
  } else{
    .temp %>%
      tidytable::summarise.(abund = sum(sz_pop, na.rm = T), .by = c(year, species_code, length, sex)) %>%
      tidytable::pivot_wider.(names_from = sex, values_from = abund) %>%
      tidytable::left_join.(lngs, .) %>%
      tidytable::mutate.(across.(.cols = c(`1`, `2`), ~tidytable::replace_na.(.x, 0))) %>%
      tidytable::select.(year, species_code, length, males = `1`, females = `2`) %>%
      tidytable::mutate.(unsexed = 0) 
  }
  
}