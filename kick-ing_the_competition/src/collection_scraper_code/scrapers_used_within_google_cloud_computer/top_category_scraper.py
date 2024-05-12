#!/usr/bin/env python
# coding: utf-8

# In[1]:


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

# Scraping the homepage
# Top live categories
def get_top_categories():
        # Open the homepage with selenium
        options = uc.ChromeOptions()
        options.headless = False  # Set headless to False to run in non-headless mode

        driver = uc.Chrome(use_subprocess=True, options=options)
        driver.get("https://www.kick.com/")
        time.sleep(2)
    
        for button in driver.find_elements(By.CLASS_NAME, "inner-label"):
            if button.text=='Accept':
                button.click()
                break
        
        soup = BeautifulSoup(driver.page_source)
        
        # Start the scraping
        top_categories = []
        for x in soup.find_all(class_="subcategory-card"):
            divs = x.find_all('div')

            if len(divs) > 0:
                Category = divs[6].get_text()
                Subcategory = divs[3].get_text()
                Viewercount = divs[5].get_text()
                Timestamp = datetime.datetime.utcfromtimestamp(int(time.time())).replace(tzinfo=pytz.utc).astimezone(pytz.timezone('Europe/Amsterdam')).strftime('%Y-%m-%d %H:%M:%S')
                
                top_categories.append({"Category": Category,
                                    "Subcategory": Subcategory,
                                    "Viewercount": Viewercount,
                                    "Timestamp of extraction": Timestamp})
        
        # Quiting the driver
        driver.quit()
        
        return(top_categories)
    
# Setting the duration of the loop
duration = 201600
end_time = time.time() + duration    
    
while time.time() < end_time:
    # Save the time the loop starts
    start_loop_time = time.time()
    
    # Saving the data
    # Check if the JSON file exists
    file_name = 'top_categories.json'
    existing_data = []

    if os.path.exists(file_name):
        # If the file exists, load its content
        with open(file_name, 'r', encoding = 'utf-8') as json_file:
            existing_data = json.load(json_file)

    # Append new data to the existing list
    categories = get_top_categories()
    existing_data.extend(categories)

    # Write the updated list to the JSON file
    with open(file_name, 'w', encoding = 'utf-8') as json_file:
        json.dump(existing_data, json_file, indent = 4)
        
    # Duration of the loop time
    loop_time = time.time() - start_loop_time
    
    remaining_time = 300 - loop_time
    if remaining_time > 0:
        time.sleep(remaining_time)

print("Data saved successfully to:", file_name)

