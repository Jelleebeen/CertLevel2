*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.HTTP
Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Ask for User Name
    Display User Name Input Dialog

Order robots
    Order robots from RobotSpareBin Industries Inc
    [Teardown]    Close the browser


*** Keywords ***
Display User Name Input Dialog
    Add heading    What is your name?
    Add text    Please enter your name below:
    Add text input    name    label=Name:
    Add text input    note    label=Notes:
    ${name_result}=    Run dialog
    Log    ${name_result.name} ${name_result.note}

Get Orders Credential
    ${orders_file}=    Get Secret    OrdersFile
    RETURN    ${orders_file}[orders]

Download orders
    ${orders_file}=    Get Orders Credential
    Download    ${orders_file}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    RETURN    ${orders}

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Order robots from RobotSpareBin Industries Inc
    ${orders}=    Download orders
    Open the robot order website
    FOR    ${order}    IN    @{orders}
        Click Button    OK
        Fill in one order form    ${order}
        Preview the robot
        Retry Submit the form    5x    0.5s
        ${receipt_html}=    Get receipt HTML
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]    ${receipt_html}
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file
        ...    ${OUTPUT_DIR}${/}${order}[Order number]${/}${order}[Order number].png
        ...    ${OUTPUT_DIR}${/}${order}[Order number]${/}${order}[Order number].pdf
        Zip the receipts    ${order}[Order number]
        Order another robot
    END

Fill in one order form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Radio Button Should Be Set To    body    ${order}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    Preview
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(3)

Retry Submit the form
    [Arguments]    ${retries}    ${interval}
    Wait Until Keyword Succeeds    ${retries}    ${interval}    Submit the form

Submit the form
    Wait Until Element Is Visible    id:order
    Click Button    id:order
    Wait Until Element Is Visible    id:order-completion

Order another robot
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another
    Wait Until Element Is Visible    css:.form-group

Get receipt HTML
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    RETURN    ${receipt_html}

Store the receipt as a PDF file
    [Arguments]    ${order_number}    ${receipt_html}
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}${order_number}${/}${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${order_number}${/}${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${list}=    Create List    ${screenshot}
    Add Files To Pdf    ${list}    ${pdf}    append=True

Zip the receipts
    [Arguments]    ${order_number}
    Set Local Variable    ${output_path}    ${OUTPUT_DIR}${/}${order_number}
    Archive Folder With Zip    ${output_path}    ${order_number}.zip
    Move File    ${order_number}.zip    ${OUTPUT_DIR}${/}${order_number}.zip    overwrite=True
    Remove File    ${OUTPUT_DIR}${/}${order_number}${/}${order_number}.pdf
    Remove File    ${OUTPUT_DIR}${/}${order_number}${/}${order_number}.png
    Remove Directory    ${OUTPUT_DIR}${/}${order_number}

Close the browser
    Close Browser
