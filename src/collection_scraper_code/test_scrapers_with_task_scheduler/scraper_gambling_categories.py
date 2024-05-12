#!/usr/bin/env python
# coding: utf-8

# In[14]:


# Import all the necessary packages
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
import undetected_chromedriver as uc
import datetime
import time
import pytz
import json
import os.path

# Scraping the gambling page
# Gambling categories
def get_gambling_categories():
        gambling_categories = []
        # Open the gambling page with selenium
        options = uc.ChromeOptions()
        options.headless = False  # Set headless to False to run in non-headless mode

        driver = uc.Chrome(use_subprocess=True, options=options)
        driver.get("https://www.kick.com/categories/gambling")

        time.sleep(3)
        for button in driver.find_elements(By.CLASS_NAME, "inner-label"):
            if button.text=='Accept':
                button.click()
                break
        time.sleep(3)
        for button in driver.find_elements(By.CLASS_NAME, "inner-label"):
            if button.text=='Recommended For You':
                button.click()
                break         
        time.sleep(2)
        for button in driver.find_elements(By.CLASS_NAME, "button-content"):
            if button.text=='Viewers (High to Low)':
                button.click()
                break         
        time.sleep(2)
        for button in driver.find_elements(By.CLASS_NAME, "category-tag-component"):
            if button.text=='Gambling':
                button.click()
                break

        soup = BeautifulSoup(driver.page_source)

        #start actual scrapping
        for x in soup.find_all(class_="subcategory-card"):
            divs = x.find_all('div')

            if len(divs) > 0:
                Subcategory = divs[2].get_text()
                Viewercount = divs[4].get_text()
                Timestamp = datetime.datetime.utcfromtimestamp(int(time.time())).replace(tzinfo=pytz.utc).astimezone(pytz.timezone('Europe/Amsterdam')).strftime('%Y-%m-%d %H:%M:%S')
                
                gambling_categories.append({'Subcategory': Subcategory,
                                            'Viewercount': Viewercount,
                                            'timestamp_of_extraction': Timestamp})
            
        # Quiting the driver
        driver.quit()
        
        return(gambling_categories)


# Saving the json.file  
# Check if the JSON file exists
file_name = 'gambling_categories.json'
existing_data = []

if os.path.exists(file_name):
    # If the file exists, load its content
    with open(file_name, 'r', encoding = 'utf-8') as json_file:
        existing_data = json.load(json_file)

# Append new data to the existing list
gambling = get_gambling_categories()
existing_data.extend(gambling)

# Write the updated list to the JSON file
with open(file_name, 'w', encoding = 'utf-8') as json_file:
    json.dump(existing_data, json_file, indent = 4)

print("Data saved successfully to:", file_name)

