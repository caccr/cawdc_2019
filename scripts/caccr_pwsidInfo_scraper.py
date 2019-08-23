import requests
import csv
import string

from bs4 import BeautifulSoup

class PWSID_Scraper(object):
    def scrape(self):
        # Create CSV file

        f = csv.writer(open("PWS_Info.csv", "w"))
        f.writerow(["PWSID","PWSID_URL","ac_address","ac_addressURL","ac_phone1Type","ac_phone1","ac_phone2Type","ac_phone2","ac_email","ac2_address","ac2_addressURL","ac2_phone1Type","ac2_phone1","ac2_phone2Type","ac2_phone2","ac2_email","pl_address","pl_addressURL","pl_phone1Type","pl_phone1","pl_phone2Type","pl_phone2","pl_email","pl2_address","pl2_addressURL","pl2_phone1Type","pl2_phone1","pl2_phone2Type","pl2_phone2","pl2_email","healthDistrictName","healthDistrictPhone","healthDistrictEmail","healthDistrictAddress"]) #Write column headers as the first line
        r  = requests.get('https://sdwis.waterboards.ca.gov/PDWW/JSP/SearchDispatch?number=&name=&county=&WaterSystemType=All&WaterSystemStatus=All&SourceWaterType=All&action=Search+For+Water+Systems', "lxml") #Request list of all PWSIDs from SDWIS
        data = r.text
        All_PWSIDsoup = BeautifulSoup(data) #Parse html of page
        table = All_PWSIDsoup.find('table', id="AutoNumber7") #Find the main table on the page
        PWSID_URL_tags = table.find_all('a') #Find all links in the table
        for PWSID_URL_tag in PWSID_URL_tags:
                PWSID_URL = "https://sdwis.waterboards.ca.gov/PDWW/JSP/"+ PWSID_URL_tag['href'] #Create a URL to each PWSID
                print "Requesting: " + str(PWSID_URL)
                r  = requests.get(PWSID_URL) #Request the unique page for each PWSID
                data = r.text
                PWSsoup = BeautifulSoup(data) #Parse html of page

                system_table = PWSsoup.find_all('table')[4] #Select table with system information
                PWSID = system_table.find_all('tr')[0].find_all('td')[1].string #Find PWSID in table and store

                contact_table = PWSsoup.find_all('table')[5] #Select table with contact information
                type = contact_table.find_all('tr') #Select all rows in contact table
                type = type[2:len(type)] #Remove header rows

                ac_row = [] #Array for administrative contacts
                pl_row = [] #Array for physical location contacts

                #initialize variables
                ac_address = ac_addressURL = ac_phone1Type = ac_phone1 = ac_phone2Type = ac_phone2 = ac_email = ''
                ac2_address = ac2_addressURL = ac2_phone1Type = ac2_phone1 = ac2_phone2Type = ac2_phone2 = ac2_email = ''
                pl_address = pl_addressURL = pl_phone1Type = pl_phone1 = pl_phone2Type = pl_phone2 = pl_email = ''
                pl2_address = pl2_addressURL = pl2_phone1Type = pl2_phone1 = pl2_phone2Type = pl2_phone2= pl2_email = ''
                healthDistrictName = healthDistrictPhone = healthDistrictEmail = healthDistrictAddress = ''

                for row in type:
                    if row.find_all('td')[0].string == "Administrative Contact":
                        ac_row.append(row) #Append each row labeled with Administrative Contact in ac_row
                    elif row.find_all('td')[0].string == "Physical Location Contact":
                        pl_row.append(row) #Append each row labeled with Physical Location Contact in pl_row
                    else:
                        continue

                if ac_row: #Store contact information for first administrative contact
                    ac_address = ac_row[0].find_all('td')[1].find_all('a')[0].text.replace(u'\xa0', "").strip().encode('utf-8')
                    try:
                        ac_addressURL = ac_row[0].find_all('td')[1].find_all('a')[0]['href'] #This is a google maps link
                    except:
                        pass
                    try:
                        ac_phone1Type = ac_row[0].find_all('td')[2].find_all('table')[0].find_all('tr')[0].find_all('td')[0].text.replace(u'\xa0', "").encode('utf-8') #Phone numbers and their types are tables within tables.
                    except:
                        pass
                    try:
                        ac_phone1 = ac_row[0].find_all('td')[2].find_all('table')[0].find_all('tr')[0].find_all('td')[1].text.replace(u'\xa0', "").encode('utf-8')
                    except:
                        pass
                    try:
                        ac_phone2Type = ac_row[0].find_all('td')[2].find_all('table').find_all('tr')[1].find_all('td')[0].text.replace(u'\xa0', "").encode('utf-8')
                    except:
                        pass
                    try:
                        ac_phone2 = ac_row[0].find_all('td')[2].find_all('table')[0].find_all('tr')[1].find_all('td')[1].text.replace(u'\xa0', "").encode('utf-8')
                    except:
                        pass
                    get_email = ac_row[0].find_all('td') #since phone numbers are listed in tables, there are sometimes additional cells in this row (between phone and email). To consistently calculate email cell, we instead get the last cell in the row.
                    last_cell = len(get_email)-1 #calculate index of last cell in administrative contact, which contains email
                    try:
                        ac_email = get_email[last_cell].find_all('a')[0].text.replace(u'\xa0', "").encode('utf-8')
                    except:
                        pass
                    if len(ac_row) > 1: #if second administrative contact, store contact information for second administrative contact
                        ac2_address = ac_row[1].find_all('td')[1].find_all('a')[0].text.replace(u'\xa0', "").strip().encode('utf-8')
                        try:
                            ac2_addressURL = ac_row[1].find_all('td')[1].find_all('a')[0]['href'] #This is a google maps link
                        except:
                            pass
                        try:
                            ac2_phone1Type = ac_row[1].find_all('td')[2].find_all('table')[0].find_all('tr')[0].find_all('td')[0].text.replace(u'\xa0', "").encode('utf-8') #Phone numbers and their types are tables within tables.
                        except:
                            pass
                        try:
                            ac2_phone1 = ac_row[1].find_all('td')[2].find_all('table')[0].find_all('tr')[0].find_all('td')[1].text.replace(u'\xa0', "").encode('utf-8')
                        except:
                            pass
                        try:
                            ac2_phone2Type = ac_row[1].find_all('td')[2].find_all('table').find_all('tr')[1].find_all('td')[0].text.replace(u'\xa0', "").encode('utf-8')
                        except:
                            pass
                        try:
                            ac2_phone2 = ac_row[1].find_all('td')[2].find_all('table')[0].find_all('tr')[1].find_all('td')[1].text.replace(u'\xa0', "").encode('utf-8')
                        except:
                            pass
                        get_email = ac_row[1].find_all('td') #since phone numbers are listed in tables, there are sometimes additional cells in this row (between phone and email). To consistently calculate email cell, we instead get the last cell in the row.
                        last_cell = len(get_email)-1 #calculate index of last cell in administrative contact, which contains email
                        try:
                            ac2_email = get_email[last_cell].find_all('a')[0].text.replace(u'\xa0', "").encode('utf-8')
                        except:
                            pass

                if pl_row: #Store contact information for first physical Location contact
                    pl_address = pl_row[0].find_all('td')[1].text.replace(u'\xa0', "").strip().encode('utf-8')
                    try:
                        pl_phone1Type = pl_row[0].find_all('td')[2].find_all('table')[0].find_all('tr')[0].find_all('td')[0].text.replace(u'\xa0', "").encode('utf-8') #Phone numbers and their types are tables within tables.
                    except:
                        pass
                    try:
                        pl_phone1 = pl_row[0].find_all('td')[2].find_all('table')[0].find_all('tr')[0].find_all('td')[1].text.replace(u'\xa0', "").encode('utf-8')
                    except:
                        pass
                    try:
                        pl_phone2Type = pl_row[0].find_all('td')[2].find_all('table').find_all('tr')[1].find_all('td')[0].text.replace(u'\xa0', "").encode('utf-8')
                    except:
                        pass
                    try:
                        pl_phone2 = pl_row[0].find_all('td')[2].find_all('table')[0].find_all('tr')[1].find_all('td')[1].text.replace(u'\xa0', "").encode('utf-8')
                    except:
                        pass
                    get_email = pl_row[0].find_all('td') #since phone numbers are listed in tables, there are sometimes additional cells in this row (between phone and email). To consistently calculate email cell, we instead get the last cell in the row.
                    last_cell = len(get_email)-1 #calculate index of last cell in administrative contact, which contains email
                    try:
                        pl_email = get_email[last_cell].find_all('a')[0].text.replace(u'\xa0', "").encode('utf-8')
                    except:
                        pass
                    if len(pl_row) > 1: #if second physical location contact, store contact information for second physical Location contact
                        pl2_address = pl_row[1].find_all('td')[1].text.replace(u'\xa0', "").strip().encode('utf-8')
                        try:
                            pl2_phone1Type = pl_row[1].find_all('td')[2].find_all('table')[0].find_all('tr')[0].find_all('td')[0].text.replace(u'\xa0', "").encode('utf-8') #Phone numbers and their types are tables within tables.
                        except:
                            pass
                        try:
                            pl2_phone1 = pl_row[1].find_all('td')[2].find_all('table')[0].find_all('tr')[0].find_all('td')[1].text.replace(u'\xa0', "").encode('utf-8')
                        except:
                            pass
                        try:
                            pl2_phone2Type = pl_row[1].find_all('td')[2].find_all('table').find_all('tr')[1].find_all('td')[0].text.replace(u'\xa0', "").encode('utf-8')
                        except:
                            pass
                        try:
                            pl2_phone2 = pl_row[1].find_all('td')[2].find_all('table')[0].find_all('tr')[1].find_all('td')[1].text.replace(u'\xa0', "").encode('utf-8')
                        except:
                            pass
                        get_email = pl_row[1].find_all('td') #since phone numbers are listed in tables, there are sometimes additional cells in this row (between phone and email). To consistently calculate email cell, we instead get the last cell in the row.
                        last_cell = len(get_email)-1 #calculate index of last cell in administrative contact, which contains email
                        try:
                            pl2_email = get_email[last_cell].find_all('a')[0].text.replace(u'\xa0', "").encode('utf-8')
                        except:
                            pass



                health_table = PWSsoup.find('table', id="District") #Select table with District Contact Information
                healthDistrict = health_table.find_all('tr') #Find all rows in table
                if len(healthDistrict) > 1: #Some pages do not have health district information listed but have header rows here.
                    healthDistrictName = healthDistrict[1].find_all('td')[0].text.replace(u'\xa0', "").encode('utf-8')
                    healthDistrictPhone = healthDistrict[1].find_all('td')[1].text.replace(u'\xa0', "").encode('utf-8')
                    try:
                        healthDistrictEmail = healthDistrict[1].find_all('td')[2].find_all('a')[0].text.replace(u'\xa0', "").encode('utf-8')
                    except:
                        pass
                    healthDistrictAddress = healthDistrict[1].find_all('td')[3].text.replace(u'\xa0', "").strip().encode('utf-8')

                f.writerow([PWSID,PWSID_URL,ac_address,ac_addressURL,ac_phone1Type,ac_phone1,ac_phone2Type,ac_phone2,ac_email,ac2_address,ac2_addressURL,ac2_phone1Type,ac2_phone1,ac2_phone2Type,ac2_phone2,ac2_email,pl_address,pl_addressURL,pl_phone1Type,pl_phone1,pl_phone2Type,pl_phone2,pl_email,pl2_address,pl2_addressURL,pl2_phone1Type,pl2_phone1,pl2_phone2Type,pl2_phone2,pl2_email,healthDistrictName,healthDistrictPhone,healthDistrictEmail,healthDistrictAddress])


if __name__ == '__main__':
    scraper = PWSID_Scraper()
    scraper.scrape()
