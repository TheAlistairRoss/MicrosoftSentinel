## LAB 02 - Investigate Activities Visually

As an analyst, your primary goal will be responding to and investigating incidents created within Microsoft Sentinel. In this lab we will be utilising Workbooks to interact with the logs and hunt for evidence related to our incident.

## Task 1: Investigate the Azure AD Sign-in Logs

1. From within the Microsoft Sentinel blade, under Threat management, select **Workbooks**.
<br><br>![alt text](screenshots/MicrosoftSentinel-MenuWorkbook.png)


2. Under the *My Workbooks* tab, search for **Demo Azure AD Sign-in logs**. Click the workbook once found to open it.
<br><br>![alt text](screenshots/WorkbooksGallery-SelectAzureADSigninLogs.png)
> **Note:** This is an adapted workbook of the built in *Azure AD sign-in Logs* workbook. It has been adapted to read the data from the SigninLogs table as well as the custom table *SigninLogs_cl" which has simulated data for the purpose of this lab.

4. Click the drop down parameters to understand what options are presented. Change the parameters to see how your data changes
<br><br>![alt text](screenshots/AADSigninLogs-SelectParameters.png)
> **Note:** Notice that the chart *Sign-in Trend over Time* changes when you change the parameters based on your selection. As you select parameters and objects enabled for interactivity, the data will most likely change.

5. The *Sign-in Trend over Time* chart has been enabled for time brushing. Click and hold on the chart and drag to the left or right to select a point in time on the chart. Observe that the data below the chart has updated.

6. Reset the Time brushing selection. Click the **undo** icon in the upper right hand corner of the chart.
<br><br>![alt text](screenshots/AADSigninLogs-TimeBrush.png)

7. Click on the activity tiles. Observe that once again the data has changed below, based on your selection. Once done click the *undo* icon in the upper right hand corner.
<br><br>![alt text](screenshots/AADSigninLogs-SelectActivityTile.png)
> **Note:** This icon may appear on the far right of the screen. This is because the tiles object has been sized to the full width of the window.

8. In the Sign-in by location grid view, select one of the rows, note the Grid to the right updates. 

9. Within the same grid, expand the location by pressing the arrow to the left of the value in the Name column. Now select a location in the expanded results. Observe that the Location Sign-in details do not return any results. 
<br><br>![alt text](screenshots/AADSigninLogs-ExpandGrid.png)
> **Note:** The interactivity of the workbooks may not work as you would expect. Take the time when using a workbook to understand how to interact with it and what data it presents. You are empowered to make the changes to a workbook and submit these changes <a href="https://github.com/Azure/Azure-Sentinel/tree/master/Workbooks" target="_blank">here</a>.

10. Now drill deeper into the logs by clicking the **Log Analytics icon** on one of the grid views. Here you can see the query and results generated for the selected workbook object.
<br><br>![alt text](screenshots/AADSigninLogs-LogsIcon.png)
> **Note:** This may not always be present, it depends on the data source and if the workbook author made it visible.

> **Reminder:** Do not forget to update your tasks! 😀

### Continue with the next lab

<a href="../LAB03/README.MD" target="_blank">LAB 03 - Explore Logs using KQL</a>
