# Azure AD Group Tracking
---

The purpose of this workbook is to enhance the visibiltity into group changes within Azure Active Directory.

# Requirements
This workbooks requires Azure Active Directory Audit Logs ingested into a Log Analytics Workspace 
<br>https://docs.microsoft.com/en-us/azure/sentinel/connect-azure-active-directory


![Overview](/Images/AADGroupTracking-Overview_Image.png)

## Features
- Drill down for the following activites
  - Add member to group
  - Remove member from group
  - Add group
  - Delete group
- Parameters for 
  - Subscriptions
  - Workspace
  - Time Range
  - AAD Group
  - Activity
- Tiles enabled for parameterization
- Time brushing enabled
- Results grouping by Group
- Links to AAD objects and more information

## Limitations
- Only supports up to 10,000 raw records to view
- No support for other activites at this time
