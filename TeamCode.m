%% header
%Team Analysis Code
%Spring 2021 Enge1216
%% Initialization
close
clc
clear
%% Importing Data
templogname = input('What is the name of the file containing sensor data?: ', 's');

templog = readtable(templogname);    %Imports the full log of temperature data as a table
%% Manipulating Imported Data Into a Workable Format for Matlab
DatetimeStrings = (templog(:,1)); %Pull first column as datetimes
Dates = table2array(DatetimeStrings); %Convert this table to an array for posixtime
PosixTime_Calculated = posixtime(Dates); %Converts the datetime in UTC to a Unix timestamp
%% 
TimeEnd = max(PosixTime_Calculated);  %Calculates the Unix timestamp of the end date / time by adding the duration in seconds to the starting Unix timestamp
TimeStart = min(PosixTime_Calculated);    %specifies if the user input start time/date occurs outside the supplied data, either before or below
%!!!! Notice that both temps are converted to array here so that all data
%remains the same after this instruction
templogappended = ([PosixTime_Calculated,table2array(templog(:,2)),table2array(templog(:,3))]);     %Creates a new matrix containing a a column of the datetime timestamps replaced with Unix timestamps for MATLAB to interpret, as well as oven and ambient temperature data
TimeData = templogappended(:,1);    %Defines the time data as the vector making up the 5th column of the data matrix
OvenTempData = templogappended(:,2);    %Defines the oven temperature data as the vector making up the 2nd column of the data matrix
AmbientTempData = templogappended(:,3);    %Defines the ambient temperature data as the vector making up the 3rd column of the data matrix
diff = (OvenTempData - AmbientTempData);    %Defines the temperature difference as a vector calculated by subtracting the ambient temperatures from the oven temperatures
DateTimes = ((TimeData / 1e9) * 1000000000);    %MATLAB apparently has no idea how to use a value in scientific notation so I had to divide by the exponential piece, then multiply by it again
DateTimesConverted = datetime(DateTimes,'ConvertFrom','posixtime');   %Creates a vector of datetimes corresponding to the Unix timestamps. This can't be understood by MATLAB, but makes the data easier to interpret by a human in the exported table
%% Graphing
plot(TimeData,OvenTempData, 'r-x');   %plots the solar oven temperatures against time
hold on     %keeps the same graph so more data can be added instead of making a new graph
plot(TimeData,AmbientTempData,'b-*' );    %plots the ambient temperatures against time
hold on     %keeps the same graph so more data can be added instead of making a new graph
plot(TimeData,diff,'o--');     %plots the temperature difference against time
xlabel('Timestamp (seconds)'); %adds an x axis label
ylabel('Degrees (Celsius)'); %adds a y axis label
title('Oven Temperature, Ambient Temperature, and Temperature Difference vs Time'); %adds a graph title
legend('Oven Interior Temperature','Ambient Temperature','Temperature Difference'); %adds a legend
%% Calculate Max Difference and Time of Occurence
[Max,Index] = max(diff);    %Finds the position and value of the maximum value in the second (temperature) column of the matrix containing temperature differences
timeatmax = TimeData(Index);    %Finds the time at the position of the max delta T
timetomax = (timeatmax - TimeStart);
dateatmax = datetime(timeatmax, 'Format','MMMM dd, yyyy HH:mm:ss', 'TimeZone', 'America/New_York', 'ConvertFrom', 'posixtime');     %Converts the timestamp of the time of occurance of max delta T into a datetime string. This makes it more readable in the code output
disp(' ');   %Adds a line break in the output window to improve readability
fprintf('The maximum temperature difference during testing was: %d °F and occured on %s.  \n',Max,dateatmax);    %Displays the max delta T and time of occurance
fprintf("This means on %s the oven reached it's greatest temperature above the ambient temperature during testing, and took %d seconds to reach this temperature. \n",dateatmax,timetomax);
%% Calculating Efficiency
    %% Qab
    Tf = Max;    %Calculates the average temp difference from the data
    DeltaT = (((Tf-32)*(5/9))+273.15);  %Converts the temperature difference to kelvin
    heatCap = 1000;  %Specific heat of air
    VolM = 0.020816; %Volume of air
    Rho = 1.225;  %Density of air
    Qab = VolM*Rho*heatCap*DeltaT;    %Calculates Qab
    %% Qin  
    AreaM = 0.2877;  %Collection area
    irradiance = 3690;   %Average incidence in Blacksburg in March
    t = (timeatmax - TimeStart)/3600;  %duration to max diff in temp in hours
    Qin = (((irradiance*AreaM)/12)*t);   %Calculates Qin
n = Qab/Qin;    %Calculates efficiency
disp(' ');   %Adds a line break in the output window to improve readability
disp("The estimated efficiency of the solar oven is: " + n*100 + "%");  %displays the calculated efficiency
%% Calculate and display T max for given time of year or location
ijuly = 5500;    %average incidence in July in Blacksburg
tdiffjuly = ((Rho*VolM*heatCap*DeltaT)/((ijuly)*AreaM*n));    %Theoretical max temp difference in July in Blacksburg
tjulyinternal = tdiffjuly + 90;     %Calculates the theoretical max oven temp in July with an ambient temp of 90°F 
disp(' ');   %Adds a line break in the output window to improve readability
disp("The theoretical maximum achievable temperature gradient for July in Blacksburg is: " + tdiffjuly + "°F. Assuming an ambient temperature of 90°F, this means the oven is capable of reaching internal temperatures of " + tjulyinternal + "°F");  %Displays the theoretical max temp gradient in July in Blacksburg w/ an assumed ambient temp of 90°F
%% Exports dates, time, temperatures, and temp difference to excel file
vars={'Dates','Unix Timestamp (s)','Oven Temperature (°F)','Ambient Temperature (°F)','Temperature Difference (°F)'};
excel_export_data = table(DateTimesConverted,TimeData,OvenTempData,AmbientTempData,diff,'VariableNames',vars);   %Concats the specific vectors of values into a single matrix
writetable(excel_export_data,'ExportData.xlsx');
