# Download SIPP data for 1996, 2001, 2004, 2008 from NBER.
# Just adjust the 'data_dir' variable below to where you want
# to store the data, and run the program.
# 
# The code draws in large part on Florian Oswald's ssh  
# scripts: https://github.com/floswald/SippData 
# 
# Now only works with Python 2 it seems, because 
# more recent versions cause trouble with 'zipfile' 
# module.

import os
import zipfile
import requests

# Data directory will be created if doesn't exist
data_dir = "~/data/sipp"                  

# Base url
base_url = "http://www.nber.org/sipp/"



## Definitions ----------------------------------

# check if folder exists, and create it if not
def create_folder_check(folder_path): 
    if not os.path.isdir(folder_path):
        os.makedirs(folder_path)

# download file if does not exist
def wget_check(url, file_name):	
    if os.path.exists(file_name):
        print(file_name+" already exists")
    elif os.path.exists(file_name.split('.')[-2]+'.dat'): # for dat once created
        print("dat for "+file_name+" already exists")
    else:
        print("downloading "+file_name)
        resp = requests.get(url)
        with open(file_name, 'wb') as f:
            f.write(resp.content)

# unzip archive and remove zip-file
def unzip_remove(file_name): 
    if os.path.exists(file_name):
        with zipfile.ZipFile(file_name,'r') as zip_ref:
                zip_ref.extractall(os.path.dirname(file_name))
        os.remove(file_name)
        print("unzipped and removed "+file_name)

# create folder structure to store data
def create_folder_structure(year): 
    create_folder_check(year)
    for folder in ["dct", "dta", "dat"]:
        create_folder_check(year+"/"+folder)


## Actual download ---------------------------

create_folder_check(data_dir)
os.chdir(data_dir)


## 1996 data

year = "1996"
create_folder_structure(year)
url = base_url+year+"/"

# core and topical modules
for module in ["w", "t"]:
    for wave in range(1,13):
        wget_check(url+"sip96"+module+str(wave)+".dct", year+"/dct/"+"sip96"+module+str(wave)+".dct")
        wget_check(url+"sipp96"+module+str(wave)+".zip", year+"/dat/"+"sipp96"+module+str(wave)+".zip")
        unzip_remove(year+"/dat/"+"sipp96"+module+str(wave)+".zip")

# longitudinal weights
wget_check(url+"sip96lw"+".dct", year+"/dct/"+"sip96lw"+".dct")
wget_check(url+"sipp96lw"+".zip", year+"/dat/"+"sipp96lw"+".zip")
unzip_remove(year+"/dat/"+"sipp96lw"+".zip")


## 2001 data

year = "2001"
create_folder_structure(year)
url = base_url+year+"/"

# core and topical modules
for module in ["w", "t"]:
    for wave in range(1,10):
        wget_check(url+"sip01"+module+str(wave)+".dct", year+"/dct/"+"sip01"+module+str(wave)+".dct")
        wget_check(url+"sipp01"+module+str(wave)+".zip", year+"/dat/"+"sipp01"+module+str(wave)+".zip")
        unzip_remove(year+"/dat/"+"sipp01"+module+str(wave)+".zip")

# longitudinal weights
wget_check(url+"sip01lw9"+".dct", year+"/dct/"+"sip01lw9"+".dct")
wget_check(url+"sipp01lw9"+".zip", year+"/dat/"+"sipp01lw9"+".zip")
unzip_remove(year+"/dat/"+"sipp01lw9"+".zip")


## 2004 data

year = "2004"
create_folder_structure(year)
url = base_url+year+"/"

# core modules
for wave in range(1,13):
    wget_check(url+"sip04w"+str(wave)+".dct", year+"/dct/"+"sip04w"+str(wave)+".dct")
    wget_check(url+"sipp04w"+str(wave)+".zip", year+"/dat/"+"sipp04w"+str(wave)+".zip")
    unzip_remove(year+"/dat/"+"sipp04w"+str(wave)+".zip")

# topical modules
for wave in range(1,9):
    wget_check(url+"sip04t"+str(wave)+".dct", year+"/dct/"+"sip04t"+str(wave)+".dct")
    wget_check(url+"sipp04t"+str(wave)+".zip", year+"/dat/"+"sipp04t"+str(wave)+".zip")
    unzip_remove(year+"/dat/"+"sipp04t"+str(wave)+".zip")

# longitudinal weights
wget_check(url+"sip04lw4"+".dct", year+"/dct/"+"sip04lw4"+".dct")
wget_check(url+"lgtwgt2004w12"+".zip", year+"/dat/"+"lgtwgt2004w12"+".zip")
unzip_remove(year+"/dat/"+"lgtwgt2004w12"+".zip")


## 2008 data

year = "2008"
create_folder_structure(year)
url = base_url+year+"/"

# core modules
for wave in range(1,17):
    wget_check(url+"sippl08puw"+str(wave)+".dct", year+"/dct/"+"sippl08puw"+str(wave)+".dct")
    wget_check(url+"l08puw"+str(wave)+".zip", year+"/dat/"+"l08puw"+str(wave)+".zip")
    unzip_remove(year+"/dat/"+"l08puw"+str(wave)+".zip")

# topical modules (last module skipped)
for wave in range(1,12):
    wget_check(url+"sippp08putm"+str(wave)+".dct", year+"/dct/"+"sippp08putm"+str(wave)+".dct")
    wget_check(url+"p08putm"+str(wave)+".zip", year+"/dat/"+"p08putm"+str(wave)+".zip")
    unzip_remove(year+"/dat/"+"p08putm"+str(wave)+".zip")

# longitudinal weights (not sure which one to use for 2008)
wget_check(url+"sipplgtwgt2008w16"+".dct", year+"/dct/"+"sipplgtwgt2008w16"+".dct")
wget_check(url+"lgtwgt2008w16"+".zip", year+"/dat/"+"lgtwgt2008w16"+".zip")
unzip_remove(year+"/dat/"+"lgtwgt2008w16"+".zip")
