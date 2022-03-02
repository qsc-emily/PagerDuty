# PagerDuty Q-SYS Integration

## Overview
### Description:
This repo contains a PagerDuty Incidents Manager Integration. The goal is to allow for custom incidents to be created within Q-SYS and sent to PagerDuty. The controls can be placed on an UCI to allow for users to submit incidents based on their experience. 

## Screenshots and Videos

https://user-images.githubusercontent.com/99763087/154532333-0d9f17bf-f1dc-465e-b62e-8fa0d090b8b2.mp4


![Screenshot 2022-02-15 130812](https://user-images.githubusercontent.com/99763087/154532596-0327e2ef-70bc-4043-b22f-ad2941b84a2d.png)


## Instructions

### How to Contribute:
To view the underlying code, go to pager_duty.lua. To contribute to this project, keep in mind that changing the LUA file will not change the Q-SYS Design code, so please open and make changes within the .qsys file. The LUA file is here for viewing only.

### API Setup:
Click here for instructions on setting up your integration within PagerDuty: https://support.pagerduty.com/docs/services-and-integrations

### Setup:
1. In pager_duty.qsys locate the "Setup" container. 
2. Enter a room name for the incidents. Can be anything you'd like. The room name will be added to the beginning of all incidents. 
3. Enter the email address associated with your PagerDuty integration.
4. Enter the Service ID that you received from PagerDuty when you setup the integration. (https://support.pagerduty.com/docs/services-and-integrations)
5. Enter the API key for your integration. 

- Room Name Example: 
  - > Conference Room

- Service ID Example:
  - > PQGF9N

- API Key Example: 
  - > Token token=u+asbsdfu293529352




## Additional Information
### Solution Type: 
Integration Concept
### Product Manufacturer:
[PagerDuty](https://www.pagerduty.com/)
### Product Category:
Information Technology
### API Version:
[PagerDuty Rest API ](https://developer.pagerduty.com/docs/ZG9jOjQ2NDA2-introduction)
### Tested On:
Q-SYS Designer 9.3.1
### License:
MIT
### Support:
THIS IS AN ALPHA RELEASE! IT IS NOT OFFICIALLY SUPPORTED BY QSC!
IT COULD BE PULLED OFF THE REPO AT ANYTIME IF THE SOLUTION GOES INTO BETA STATUS!
If you have questions or comments, please address them in the QSC Communities for Developers Code Exchange. 




