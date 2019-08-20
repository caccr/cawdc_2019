# CCR Application datathon ideas  

_UC Davis (2019-08-22 to 2019-8-23)_  

## Low hanging fruit (within a few hours or day)

* scrape phone numbers and addresses for all PSIDs from [old site](https://sdwis.waterboards.ca.gov/PDWW/JSP/WaterSystemDetail.jsp?tinwsys_is_number=4424&tinwsys_st_code=CA&wsnumber=CA4510005)  
* violations section: how to translate HRW or other relevant data into information?  
* Time and place of regularly scheduled board meetings for public participation per PSID   
* address missing spatial point data `data/psids_not_in_hrw_gis_data.csv` from Human Right to Water. Why important? This is how we determine violation status.  
* get complete [psid polygons](http://www.arcgis.com/home/webmap/viewer.html?url=https%3A%2F%2Fgispublic.waterboards.ca.gov%2Farcgis%2Frest%2Fservices%2FHR2W%2FCA_Service_Area_Boundaries_07302018%2FMapServer&source=sd). currently, we use points. Some of these points overlap, so we need to jitter them so they're all clickable. This results in some points that are in the ocean. Ideally, on each individual CCR, we'll have a polygon geometry with the fields from the exisiting points. This helps users see if their address falls within a water system boundary.  
    * are there missing polygons? If yes, then we should augment missing polygons with points.  
* Visualzing the population served by water systems: 
    * [circular packing with D3](https://www.d3-graph-gallery.com/graph/circularpacking_template.html) of water system by population served] to illustrate state smalls.  
    * [morphing catrogram in R](https://www.r-graph-gallery.com/cartogram.html)  
* determine the best way to integrate [non-English languages into CCRs](https://www.waterboards.ca.gov/drinking_water/certlic/drinkingwater/documents/ccr/1ccr_reference_manual_apph_translations_for_2018_ccr_20190214.docx)  


***  


## Mid-level goals do-able during a datathon (<= 2 days)  

### Data Science  

* Distinguish if a system is non-compliant due to monitoring or reporting violations vs. actual contaminant detection  
* Incorporate TCR violations (these are not reported in the data behind the Human Right to Water portal, if that is the 
weird spatial dataset with incomplete violations data you were talking about)  
* Incorporate info on Cryptospordium and Radon testing specifically in their own sections as required by CCR regs
Basically try to incorporate all required CCR reporting elements that are not really covered by MCL table. Items 5,6 in the CCR manual  

### Data Engineering

* clean chemical data API  
* violations API  


***  
 

## Shoot the moon (> 2 days)  

* full blown interactive app interface v searchable directory of static pages (trade-offs) or a combination of the two  
    * existing solution: all static HTML. landing page with map and table interfaces that link to static HTML CCRs  
    * potential solution: interactive app that hits a database or API (from mid-level goals) to populate a report on the fly  
    	* problem with this is that reports don't change much, so an interactive solution is probably overkill  




