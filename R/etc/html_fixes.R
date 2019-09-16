# read in the HTML files, insert the navbar code, then re-write the files
#for(i in 1:length(psids)){
for(i in 1:length(psids)){
  index <- read_lines(paste0("/Users/richpauloo/Github/jmcglone.github.io/ccrs/", psids[i], ".html"))
  index <- c(index[1:9], navbar, index[44:length(index)])
  write_lines(index, paste0("/Users/richpauloo/Github/jmcglone.github.io/ccrs/", psids[i], ".html"))
}

for(i in 2:length(psids)){
  
  index <- read_lines(paste0("/Users/richpauloo/Github/jmcglone.github.io/ccrs/", psids[i], ".html"))
  
  # index <- stringr::str_replace_all(index, 
  #                                   '<strong><font color="green">IN COMPLIANCE', 
  #                                   'Status: <strong><font color="green">IN COMPLIANCE')
  # index <- stringr::str_replace_all(index, 
  #                                   '<strong><font color="orange">RETURNED TO COMPLIANCE', 
  #                                   'Status: <strong><font color="orange">RETURNED TO COMPLIANCE')
  # index <- stringr::str_replace_all(index, 
  #                                   '<strong><font color="red">OUT-OF-COMPLIANCE', 
  #                                   'Status: <strong><font color="red">OUT-OF-COMPLIANCE')
  # 
  # index <- stringr::str_replace_all(index, 
  #                                   'thus these chemicals are not included in the chart above.', 
  #                                   'thus these chemicals are not included in the chart above, but are reported in the <a href="#table">table below</a>.')
  # 
  # index <- stringr::str_replace_all(index, 
  #                                   ' (since 2017-01-01)', 
  #                                   '')
  
  ## active and hover color of floating table of contents
  # j <- stringr::str_which(index, '<h4 class="date">For the period from 2017-01-01')
  # index <- c(index[1:j+2], 
  #            c('<style>', 
  #            '.list-group-item.active, .list-group-item.active:focus, .list-group-item.active:hover {',
  #            'background-color: #414141;',
  #            '}',
  #            '</style>'),
  #            index[j+3:length(index)])
  
  #index <- c(index[1:7], navbar, index[46:length(index)])
  
  write_lines(index, paste0("/Users/richpauloo/Github/jmcglone.github.io/ccrs/", psids[i], ".html"))
  
}


