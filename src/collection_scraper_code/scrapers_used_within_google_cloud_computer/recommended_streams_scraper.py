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
# Recommended streams
def get_recommended_streams():
        global streamer_mapping
        recommended_streams = []
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
        
        # Anonymise the streamer name
        salt = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))

        #start actual scrapping
        for x in soup.find_all(class_="sidebar-item"):
            divs = x.find_all('div')
            
            if len(divs) > 0:
                Streamer = divs[2].get_text()
                Category = divs[3].get_text()
                Viewercount = divs[4].get_text()
                Timestamp = datetime.datetime.utcfromtimestamp(int(time.time())).replace(tzinfo=pytz.utc).astimezone(pytz.timezone('Europe/Amsterdam')).strftime('%Y-%m-%d %H:%M:%S')
                
                if Streamer in streamer_mapping:
                    streamer_secret = streamer_mapping[Streamer]
                else:
                    # Generate anonymized streamer name if not already mapped
                    streamer_secret = generate_hash(Streamer)
                    # Store the mapping
                    streamer_mapping[Streamer] = streamer_secret

                recommended_streams.append({'Streamer_Secret': streamer_secret,
                                            'Category': Category,
                                            'Viewercount': Viewercount,
                                            'timestamp_of_extraction': Timestamp})
                
        # Quiting the driver
        driver.quit()
        
        return(recommended_streams)

# Setting the duration of the loop
duration = 201600
end_time = time.time() + duration    
    
while time.time() < end_time:
    # Save the time the loop starts
    start_loop_time = time.time()
    
    # Saving the json.file  
    # Check if the JSON file exists
    file_name = 'recommended_streams.json'
    existing_data = []

    if os.path.exists(file_name):
        # If the file exists, load its content
        with open(file_name, 'r', encoding = 'utf-8') as json_file:
            existing_data = json.load(json_file)

    # Append new data to the existing list
    recommended = get_recommended_streams()
    existing_data.extend(recommended)

    # Write the updated list to the JSON file
    with open(file_name, 'w', encoding = 'utf-8') as json_file:
        json.dump(existing_data, json_file, indent = 4)
        
    # Duration of the loop time
    loop_time = time.time() - start_loop_time
    
    remaining_time = 300 - loop_time
    if remaining_time > 0:
        time.sleep(remaining_time)

print("Data saved successfully to:", file_name)

