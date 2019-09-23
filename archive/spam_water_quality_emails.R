# https://cran.r-project.org/web/packages/gmailr/vignettes/sending_messages.html
library(gmailr)

# secret json file with client id and secret from
# google api console - gmail
gm_auth_configure(path = "~/Desktop/gmailR/secret.json")

# run `04_generate_ccrs.R` to bring in data, but don't format the 
# HD_email (i.e. don't run lines 69-94)
z <- psid_contact %>% 
  filter(PRIM_STA_C %in% psids) %>% 
  filter(!is.na(HD_EMAIL)) %>% 
  group_split(HD_EMAIL)

# targets to email
target <- sapply(z, function(x) unique(x$HD_EMAIL)) 

# number of psids in target
n <- sapply(z, nrow) 

# list of psids for each health district email
ids <- sapply(z, function(x) x$PRIM_STA_C)

# construct the urls to visit
urls <- vector("list", length = length(ids))
for(i in 1:length(urls)){
  urls[[i]] <- paste0("<a href = 'caccr.github.io/ccrs/", 
                      ids[[i]], "'>", ids[[i]], "</a>")
}

# send the email
for(i in 1:length(target)){
  gm_mime() %>%
    gm_to(target[i]) %>%
    gm_from("richpauloo@gmail.com") %>%
    gm_subject("Water quality reports (CCRs)") %>% 
    gm_html_body(paste0("Hello, <br><br> I'm writing to you because you're listed as the primary contact email for <b>", 
                 n[i], 
                 "</b> community water systems in the <a href='https://www.waterboards.ca.gov/water_issues/programs/hr2w/'>Human Right to Water Portal</a>. <br><br> My name is Rich Pauloo, and I'm a PhD Candidate in Hydrology at UC Daivs. <br><br> For the 2019 <a href = 'https://waterchallenge.data.ca.gov/'>California Water Data Challenge</a>, I built a 'weather app' for water quality. I focused on community water systems because data tends to availabile for these systems. <br><br> You can find the main website <a href = 'caccr.github.io'>here</a>. <br><br> Water quality reports (CCRs) for individual community water systems that list you as a primary email contact can be found at the following links: <br><br>", 
                 paste(urls[[i]], collapse="<br>"),  
                 "<br><br> I welcome constructive criticism and feedback on this project, specifically things that can be improved upon. Feel free to forward this, and share it with the populations you serve. Below is an example of what the interface looks like. <br><br> <a href = 'caccr.github.io'><img src = 'https://github.com/caccr/cawdc_2019/raw/master/example.gif'></a> <br><br> Thank you for your time, and please don't hesitate to get in contact with me about anything. <br><br>Best, <br> Rich <br> <a href='richpauloo.github.io'>richpauloo.github.io</a>")) %>% 
    gm_send_message()
  Sys.sleep(5)
}
