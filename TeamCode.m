%% header
%Ben Koniers
%Spring 2021 Enge1216
%% Initialization
close
clc
clear
%% Importing Data
templog = readmatrix('templog.csv');    %Imports the full log of temperature data
disp('Please enter the time and date of testing in the following format: MMMM dd, yyyy HH:mm:ss Seconds should always be 00 and the program will find the nearest data entry.');    %Displays the required syntax for the start date
disp('For example, August 5th, 2021 at 4:35 PM would be August 5, 2021 16:35:00');  %Displays an example start date in the required format
Date_Input = input('What is the time and date of testing?: ','s');  %Requests the user input the start date they would like to evaluate data from
Duration = input('What is the duration of testing in minutes?: ');  %Requests the user input a duration that they would like to evaluate from the start date
Duration = abs((Duration * 60));    %Convers the duration from minutes to seconds
Date = datetime(Date_Input,'Format','MMMM dd, yyyy HH:mm:ss','TimeZone','local');   %Converts the input start date from a string to a datetime array
Date.TimeZone = 'Z';    %Converts the datetime array to UTC since Unix has no timezone
PosixTime_Calculated = posixtime(Date); %Converts the datetime in UTC to a Unix timestamp
TimeStart = PosixTime_Calculated;     %Specifies the Unix timestamp of the start date / time
TimeEnd = PosixTime_Calculated + Duration;  %Calculates the Unix timestamp of the end date / time by adding the duration in seconds to the starting Unix timestamp
if TimeStart < min(templog(:,5)) || TimeStart > max(templog(:,5))    %specifies if the user input start time/date occurs outside the supplied data, either before or below
    error('An error has occured. The specified start time / date is not within the bounds of the logged data. Please choose a new date and try again.');    %Throws an error that the input date is invalid and stops running the code
elseif TimeEnd > max(templog(:,5))  %specifies if the user input duration exceeds the bounds of the supplied data
    error('An error has occured. The specified duration is not within the bounds of the logged data. Please choose a new duration and try again.');    %Throws an error that the input duration is invalid and stops running the code
elseif TimeEnd == 0  %specifies if the user has input 0 as the duration
    error('An error has occured. The specified duration cannot be zero. Please choose a new, nonzero duration, and try again.');    %Throws an error that the input duration is null and stops running the code
else    %if neither of the above conditions are met, the rest of the code runs as expected
    nearest_start= interp1(templog(:,5), templog(:,5),TimeStart, 'nearest', 'extrap');    %Finds the nearest value to the specified start time, since the individual logs occur at unpredictable times. This also helps with error handling if the exact time is not present in the data
    nearest_end= interp1(templog(:,5), templog(:,5),TimeEnd, 'nearest', 'extrap');     %Finds the nearest value to the specified end time, since the individual logs occur at unpredictable times. This also helps with error handling if the exact time is not present in the data
    Index1 = find(templog(:,5)==nearest_start);   %Finds the index of the closest datapoint to the start time / date defined above by "nearest_start"
    Index2 = find(templog(:,5)==nearest_end);     %Finds the index of the closest datapoint to the end time / date defined above by "nearest_end"
    templogshort = templog(Index1:Index2,:);     %Creates a new matrix containing entries only between the index of the start and end time / date. This lets MATLAB perform calculations on only the desired subset of the original data
    TimeData = templogshort(:,5);    %Defines the time data as the vector making up the 5th column of the data matrix
    OvenTempData = templogshort(:,2);    %Defines the oven temperature data as the vector making up the 2nd column of the data matrix
    AmbientTempData = templogshort(:,3);    %Defines the ambient temperature data as the vector making up the 3rd column of the data matrix
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
    ylabel('Degrees (Fahrenheit)'); %adds a y axis label
    title('Oven Temperature, Ambient Temperature, and Temperature Difference vs Time'); %adds a graph title
    legend('Oven Interior Temperature','Ambient Temperature','Temperature Difference'); %adds a legend
    %% Calculate Max Difference and Time of Occurence
    [Max,Index] = max(diff);    %Finds the position and value of the maximum value in the second (temperature) column of the matrix containing temperature differences
    timeatmax = TimeData(Index);    %Finds the time at the position of the max delta T
    timetomax = (timeatmax - nearest_start);
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
        t = timeatmax - min(TimeData);  %duration to max diff in temp
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
end