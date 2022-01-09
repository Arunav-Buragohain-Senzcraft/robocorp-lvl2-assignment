*** Settings ***
Documentation     Order robots from robotsparebin industries
...               Save the receipt HTML in a pdf file
...               Take screenshot of robot and attach in pdf file
...               Zip the all reciepts
Library           OperatingSystem
Library           RPA.FileSystem
Library           RPA.HTTP
Library           Dialogs
Library           RPA.Tables
Library           RPA.Browser.Selenium
Library           RPA.Robocorp.Vault
Library           RPA.PDF
Library           RPA.Archive

*** Tasks ***
Order of the Tasks
    Initialize Steps
    Download CSV file
    ${data}=    Read CSV file
    Open Website
    Process Orders    ${data}
    Convert the reciept to Zip
    [Teardown]    Close Browser

*** Keywords ***
Initialize Steps
    Remove File    ${CURDIR}${/}orders.csv
    ${reciept_folder}=    Does Directory Exist    ${CURDIR}${/}reciepts
    ${robots_folder}=    Does Directory Exist    ${CURDIR}${/}robots
    Run Keyword If    '${reciept_folder}'=='True'    Delete and create empty directory    ${CURDIR}${/}reciepts    ELSE    Create Directory    ${CURDIR}${/}reciepts
    Run Keyword If    '${robots_folder}'=='True'    Delete and create empty directory    ${CURDIR}${/}robots    ELSE    Create Directory    ${CURDIR}${/}robots

*** Keywords ***
Delete and create empty directory
    [Arguments]    ${folder}
    Remove Directory    ${folder}    True
    Create Directory    ${folder}

*** Keywords ***
Download CSV file
    ${csv_url}=    Get Value From User    Please enter the csv file url    https://robotsparebinindustries.com/orders.csv
    Download    ${csv_url}    orders.csv
    Sleep    3 seconds

*** Keywords ***
Read CSV file
    ${data}=    Read table from CSV    ${CURDIR}${/}orders.csv    header=True
    Return From Keyword    ${data}

*** Keywords ***
Open Website
    ${website}=    Get Secret    websitedata
    Open Available Browser    ${website}[url]
    Maximize Browser Window

Process orders
    [Arguments]    ${data}
    FOR    ${row}    IN    @{data}
        Data Entry for each elements    ${row}
        Check If Error arised
        Save and Order another    ${row}
    END

Data Entry for each elements
    [Arguments]    ${row}
    Wait Until Page Contains Element    //button[@class="btn btn-dark"]
    Click Button    //button[@class="btn btn-dark"]
    Select From List By Value    //select[@name="head"]    ${row}[Head]
    Click Element    //input[@value="${row}[Body]"]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    //input[@placeholder="Shipping address"]    ${row}[Address]
    Click Button    //button[@id="preview"]
    Wait Until Page Contains Element    //div[@id="robot-preview-image"]
    Sleep    5 seconds
    Click Button    //button[@id="order"]
    Sleep    5 seconds

Check If Error arised
    FOR    ${i}    IN RANGE    ${100}
        ${alert}=    Is Element Visible    //div[@class="alert alert-danger"]
        Run Keyword If    '${alert}'=='True'    Click Button    //button[@id="order"]
        Exit For Loop If    '${alert}'=='False'
    END

Save and order another
    [Arguments]    ${row}
    Sleep    3 seconds
    ${reciept}=    Get Element Attribute    //div[@id="receipt"]    outerHTML
    Html To Pdf    ${reciept}    ${CURDIR}${/}reciepts${/}${row}[Order number].pdf
    Screenshot    //div[@id="robot-preview-image"]    ${CURDIR}${/}robots${/}${row}[Order number].png
    Add Watermark Image To Pdf    ${CURDIR}${/}robots${/}${row}[Order number].png    ${CURDIR}${/}reciepts${/}${row}[Order number].pdf    ${CURDIR}${/}reciepts${/}${row}[Order number].pdf
    Click Button    //button[@id="order-another"]

*** Keywords ***
Convert the reciept to Zip
    Archive Folder With Zip    ${CURDIR}${/}reciepts    ${OUTPUT_DIR}${/}reciepts.zip
