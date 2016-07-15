library(readr)
library(dplyr)
library(tidyr)
library(purrr)
library(feather)
library(foreach)
library(doParallel)

Sys.setenv(PYTHONHOME="/Users/emd/anaconda")
library(inventrry)
registerDoParallel(cores=4)

REGEN_SPECS <- F
REGEN_NMPAIRS <- F
REGEN_NIMBALANCE <- F

# Read inventories
inventories_all <- read_feather("inventories.feather") %>%
  nest(-segment_type, -inventory_type, -language, .key=features) %>%
  mutate(features=purrr::map(features, ~ feature_matrix(.)))

# Feature names
feature_names <- colnames(inventories_all$features[[1]])

# Inventories -> specs
if (file.exists("specs.feather") & !REGEN_SPECS) {
  specs_all <- read_feather("specs.feather") %>%
    group_by(segment_type, inventory_type, language) %>%
    nest(.key=specs) %>%
    mutate(specs=purrr::map(
      specs,
      ~ data_frame(spec_id=.$spec_id,
                   spec=spec_list((select(., -spec_id)), feature_names)
        )
    )) %>%
    ungroup()
} else {
  specs_all <- inventories_all %>%
    mutate(specs=foreach(f=features) %dopar% specs(f, 30000, abs(sum(f)))) %>%
    select(-features) %>%
    filter(!is_empty(specs)) %>%
    mutate(specs=purrr::map(
      specs,
      ~ data_frame(spec_id=paste0("Spec", 1:length(.)), spec=.)
      )
    )
  specs_all %>% 
    mutate(specs=purrr::map(
      specs,
      function(s) spec_matrix(s$spec, feature_names) %>%
                  as_data_frame %>%
                  mutate(spec_id=s$spec_id)
      )
    ) %>%
    unnest(specs) %>%
    write_feather("specs.feather")
}

# Specs, inventories -> specifiable inventories (with specification)
inventories_spec <- inner_join(
  inventories_all,
  specs_all
)

# Inventories -> size
inventories_spec <- inventories_spec %>%
  mutate(size=purrr::map_int(features, ~ nrow(.)))

# Sizes -> sizes, inventories, specs with corrected distribution
natural_distribution <- inventories_spec %>%
  filter(inventory_type == "Natural") %>%
  group_by(segment_type, size) %>%
  summarize(n=n()) %>%
  ungroup()
target_distribution <- inventories_spec %>%
  filter(inventory_type != "Natural") %>%
  group_by(inventory_type, segment_type, size) %>%
  summarize() %>%
  inner_join(natural_distribution) %>%
  ungroup()
set.seed(1)
inventories <- target_distribution %>%
  mutate(subsample=purrr::pmap(
    list(as.list(inventory_type),
         as.list(segment_type),
         as.list(size),
         as.list(n)),
    function(inventory_type_, segment_type_, size_, n)
    sample_n(
      filter(inventories_spec,
             inventory_type == inventory_type_,
             segment_type == segment_type_,
             size == size_),
      n
    )
  )) %>%
  select(-size, -n, -inventory_type, -segment_type) %>%
  unnest(subsample) %>%
  bind_rows(inventories_spec %>% filter(inventory_type == "Natural"))
set.seed(NULL)

# Take some things out of memory
rm(inventories_spec, inventories_all, specs_all)
gc()

# Specs -> Nfeat
inventories <- inventories %>%
  mutate(specs=purrr::map(
      specs,
      ~ mutate(., nfeat=purrr::map_int(spec, ~ length(.)))
    )
  )

# Specs, inventories -> Nmpairs
if (file.exists("nmpairs.feather") & !REGEN_NMPAIRS) {
  inventories <- inventories %>%
    unnest(specs) %>%
    inner_join(read_feather("nmpairs.feather")) %>%
    group_by(segment_type, inventory_type, language, size) %>%
    nest(.key=specs) %>% # This (correctly) drops features because it's a list
    ungroup() %>%
    inner_join(inventories %>% select(-specs)) # Put features back
} else {
  inventories <- inventories %>%
    mutate(specs=purrr::map2(
      specs,
      features,
      ~ mutate(.x, nmpairs=foreach(s=spec, .combine=c) %dopar% nmpairs(.y, s))
    ))
  inventories %>%
    select(-features, -size) %>%
    mutate(specs=(specs %>% select(-spec, -nfeat))) %>%
    unnest(specs) %>%
    write_feather("nmpairs.feather")
}

# Specs, inventories -> Nimbalance
if (file.exists("nimbalance.feather") & !REGEN_NIMBALANCE) {
  inventories <- inventories %>%
    unnest(specs) %>%
    inner_join(read_feather("nimbalance.feather")) %>%
    group_by(segment_type, inventory_type, language, size) %>%
    nest(.key=specs) %>%
    ungroup() %>%
    inner_join(inventories %>% select(-specs))
} else {
  inventories <- inventories %>%
    mutate(specs=purrr::map2(
      specs,
      features,
      ~ mutate(.x,
               nimbalance=foreach(s=spec, .combine=c) %dopar% nimbalance(.y, s))
    ))
  inventories %>%
    select(-features, -size) %>%
    mutate(specs=(specs %>% specs(-spec, -nfeat))) %>%
    unnest(specs) %>%
    write_feather("nimbalance.feather")
}

# Geoms
if (file.exists("geoms.feather")) {
  geoms <- read_feather("geoms.feather")
} else {
  geoms <- inventories %>%
    select(-segment_type, -inventory_type, -language) %>%
    unnest(specs) %>%
    select(-spec_id, -spec) %>%
    unique
}

# Geoms -> Econ, Loc, Glob
geoms <- geoms %>%
  mutate(econ=econ(size, nfeat)) %>%
  group_by(size, nfeat) %>%
  mutate(loc=norm_rank(nmpairs)) %>%
  group_by(size, nfeat, nmpairs) %>%
  mutate(glob=norm_rank(nimbalance, rev=T)) %>%
  ungroup()

# Combine with inventories and summarize
inventories_summ <- inventories %>%
  select(-features) %>%
  unnest(specs) %>%
  select(-spec) %>%
  inner_join(geoms) %>%
  group_by(segment_type, inventory_type, language) %>%
  summarize(econ=median(econ),
         loc=median(loc, na.rm=T),
         glob=median(glob, na.rm=T)) %>%
  ungroup
write_feather(inventories_summ, "summary.feather")

