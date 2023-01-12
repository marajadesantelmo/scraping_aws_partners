library(rvest)
library(xml2)
library(tidyverse)
library(stringi)
library(openxlsx)

# Tabs por empresa ####

path <- "C:/Users/facun/OneDrive/Documentos/GitHub/scraping_amazon/partner_tabs/"
files <- list.files(path)
df_partner <- data.frame()
df_qualification <- data.frame()
df_city <- data.frame()
df_product <- data.frame() 

i <- 1

length <- length(files)
files <- files[i:length]

### Reloj
t0<-proc.time()

for (file in files) {
  
page <- read_html(paste0(path, file) , encoding="UTF-8")

partner <- page %>% 
  html_elements(".partner__name") %>% 
  html_text() %>% 
  as.vector() 

partner_description <- page %>%
  html_elements(".split-panel__blurb") %>%
  html_text() %>%
  as.vector()

df2 <- bind_cols(i, partner[1], partner_description[1])
colnames(df2) <- c("tab_id", "partner", "partner_description")

df_partner <- bind_rows(df_partner, df2)

qualification <- page %>%
  html_elements(".qualification-card__item") %>%
  html_text() %>%
  as.vector()

df3 <- bind_cols(i, partner[1], qualification)
colnames(df3) <- c("tab_id", "partner", "qualification")

df_qualification <- bind_rows(df_qualification, df3)

cities <- page %>% 
  html_elements(".location-header__city") %>% 
  html_text() %>% 
  as.vector()

df4 <- bind_cols(i, partner[1], cities)
colnames(df4) <- c("tab_id", "partner", "city")

df_city <- bind_rows(df_city, df4)

solution <- page %>%
  html_nodes(xpath = "//div[@id='solutions--tech-product']") %>%
  html_nodes("div.card-title") %>%
  html_text() %>%
  as.vector()

solution_description <- page %>%
  html_nodes(xpath = "//div[@id='solutions--tech-product']") %>%
  html_nodes("div.expandable-card__overlay") %>%
  html_text() %>%
  as.vector()

practice <- page %>%
  html_nodes(xpath = "//div[@id='solutions--customer-service']") %>%
  html_nodes("div.card-title") %>%
  html_text() %>%
  as.vector()

practice_description <- page %>%
  html_nodes(xpath = "//div[@id='solutions--customer-service']") %>%
  html_nodes("div.expandable-card__overlay") %>%
  html_text() %>%
  as.vector()

df5_solutions <- bind_cols(i, partner[1], solution, solution_description) %>% 
  mutate(product_type="Solutions")

colnames(df5_solutions) <- c("tab_id", "partner", "product", "product_description", "product_type")

df5_practices <- bind_cols(i, partner[1], practice, practice_description) %>% 
  mutate(product_type="Practices")

colnames(df5_practices) <- c("tab_id", "partner", "product", "product_description", "product_type")

df5 <- bind_rows(df5_solutions, df5_practices)

df_product <- bind_rows(df_product, df5)

cat("Pagina ", i, "de ", length)

i <- i+1

}

reloj <- proc.time() - t0
print(paste0("Tardó ", round(reloj[3]/60, 0) , " minutos en correr"))  # "Tardó 159 minutos en correr"

save(df_city, df_partner, df_product, df_qualification, 
     file="outputs/scraping_data_frames.Rdata")

df_partner <- df_partner[!duplicated(df_partner[,c('partner')]),] %>% 
  select(-tab_id)

df_partner$id_partner <- seq.int(nrow(df_partner))

rownames(df_partner) <- NULL

df_partner <- df_partner %>% select("id_partner", everything())

id_partner_join <- df_partner %>% select(id_partner, partner)

df_qualification <- df_qualification %>% left_join(id_partner_join, by="partner") %>% 
  select(id_partner, partner, qualification) %>% 
  unique()

df_city <- df_city %>% left_join(id_partner_join, by="partner") %>% 
  select(id_partner, partner, city) %>% 
  unique()

df_product <- df_product %>% left_join(id_partner_join, by="partner") %>% 
  select(id_partner, partner, product, product_type, product_description) %>% 
  unique()

# Guardo outputs ####

write.xlsx(df_partner, "outputs/partners.xlsx")
write.xlsx(df_qualification, "outputs/qualifications.xlsx")
write.xlsx(df_city, "outputs/cities.xlsx")
write.xlsx(df_product, "outputs/products.xlsx")



