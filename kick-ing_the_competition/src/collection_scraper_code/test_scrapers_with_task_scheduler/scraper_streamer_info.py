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
import hashlib
import random
import string
import os.path

# Anonymise streamer names
streamer_mapping = {}

def generate_hash(input_string):
    # Generate a hash of the input string (streamer name)
    hash_object = hashlib.sha256(input_string.encode())
    # Generate the hexadecimal representation of the digest
    hash_hex = hash_object.hexdigest()
    # Return the hashed streamer name
    return hash_hex

# Scraping the gambling page
# Streamer info
def get_streamer_info():
        streamer_info = []
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

        # Scrolling to the bottom of the page to actually load in all the streams
        html = driver.find_element(By.TAG_NAME, 'html')
        for _ in range(150):
                html.send_keys(Keys.DOWN)
                time.sleep(0.1)

        soup = BeautifulSoup(driver.page_source)
        
        # Anonymise the streamer name
        salt = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))

        # Start actual scraping
        counter = 0 
        for x in soup.find_all(class_="card-content"):
            divs = x.find_all('div')
            spans = x.find_all('span')
            title = x.find_all(class_='card-session-name')
            category = x.find_all(class_='card-category-name')
            streamer = x.find_all(class_='card-user-name')

            if len(divs) > 0:
                Streamer = streamer[0].get_text()
                Subcategory = category[0].get_text()
                Title = title[0].get_text()
                Viewercount = spans[1].get_text()
                Language = divs[8].get_text()
                Timestamp = datetime.datetime.utcfromtimestamp(int(time.time())).replace(tzinfo=pytz.utc).astimezone(pytz.timezone('Europe/Amsterdam')).strftime('%Y-%m-%d %H:%M:%S')
                
                if Streamer in streamer_mapping:
                    streamer_secret = streamer_mapping[Streamer]
                else:
                    # Generate anonymized streamer name if not already mapped
                    streamer_secret = generate_hash(Streamer)
                    # Store the mapping
                    streamer_mapping[Streamer] = streamer_secret
 
                # Making sure to only scrape the first 50 streamers
                counter = counter + 1
                if counter > 50:
                    break

                streamer_info.append({'Streamer_Secret': streamer_secret,
                                    'Subcategory': Subcategory,
                                    'Title': Title,
                                    'Viewercount': Viewercount,
                                    'Language': Language,
                                    'timestamp_of_extraction': Timestamp})
        
        # Quiting the driver
        driver.quit()

        return(streamer_info)

# Saving the json.file  
# Check if the JSON file exists
file_name = 'streamer_info.json'
existing_data = []

if os.path.exists(file_name):
    # If the file exists, load its content
    with open(file_name, 'r', encoding = 'utf-8') as json_file:
        existing_data = json.load(json_file)

# Append new data to the existing list
streamer = get_streamer_info()
existing_data.extend(streamer)

# Write the updated list to the JSON file
with open(file_name, 'w', encoding = 'utf-8') as json_file:
    json.dump(existing_data, json_file, indent = 4)

print("Data saved successfully to:", file_name)

