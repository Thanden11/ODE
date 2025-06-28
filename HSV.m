clearvars; close all; clc;


% Put Original image here
imageDir = 'C:\Users\first\Documents\MATLAB 3\MATLAB\retina\newestdata_usefor_fillsheet\Outside_interAndRF\resized_91RFMiD_ODE_ColorVessel_Outside';

filePattern = fullfile(imageDir, '*.jpg');
theFiles = dir(filePattern);
imageFiles = sortNumerically(theFiles);

% arrays to store HSV values for all image
allAvgHues = [];
allAvgSaturations = [];
allAvgBrightnesses = [];
allAvgIntensities = [];

%  cell arrays to store image statistics
individualStats = cell(length(imageFiles), 5);

for i = 1:length(imageFiles)
    image = imread(fullfile(imageDir, imageFiles(i).name));
    % Convert the image to HSV color space
    hsvImage = rgb2hsv(image);

    % Separate the HSV channels
    hue = hsvImage(:,:,1);
    saturation = hsvImage(:,:,2);
    brightness = hsvImage(:,:,3);

    image_double = im2double(image);
    % Calculate the intensity as the mean of the RGB channels
    intensity = mean(image_double, 3);
 
    % Calculate statistic
    avg_hue = mean(hue(:));
    avg_saturation = mean(saturation(:));
    avg_brightness = mean(brightness(:));
    avg_intensity = mean(intensity(:));
    
    % Store image statistics
    individualStats{i, 1} = imageFiles(i).name;
    individualStats{i, 2} = avg_hue;
    individualStats{i, 3} = avg_saturation;
    individualStats{i, 4} = avg_brightness;
    individualStats{i, 5} = avg_intensity;
    
    allAvgHues = [allAvgHues; avg_hue];
    allAvgSaturations = [allAvgSaturations; avg_saturation];
    allAvgBrightnesses = [allAvgBrightnesses; avg_brightness];
    allAvgIntensities = [allAvgIntensities; avg_intensity];
end

%{
% Calculate statistics for the entire dataset
avg_hue_all = round(mean(allAvgHues), 6);
avg_saturation_all = round(mean(allAvgSaturations), 6);
avg_brightness_all = round(mean(allAvgBrightnesses), 6);
avg_intensity_all = round(mean(allAvgIntensities), 6);
%}

% Create a table to store the individual results
individualResults = cell2table(individualStats, ...
    'VariableNames', {'Image', 'Avg_Hue','Avg_Saturation','Avg_Brightness','Avg_Intensity'});

%{
combinedResults = table({'Combined'}, ...
    avg_hue_all, avg_saturation_all, avg_brightness_all, avg_intensity_all, ...
    'VariableNames', {'Group', 'Avg_Hue','Avg_Saturation','Avg_Brightness','Avg_Intensity'});
%}

% Write the individual and combined results to an Excel file
writetable(individualResults, 'HSV_Intensity_Results.xlsx', 'Sheet', 1);
%writetable(combinedResults, 'HSV_Intensity_Results.xlsx', 'Sheet', 2, 'WriteVariableNames', true);

% Display the tables
disp(individualResults);
%disp(combinedResults);

% To ensure it process in correct order
function sortedFiles = sortNumerically(files)
    fileNames = {files.name};
    fileNumbers = regexp(fileNames, '\d+', 'match');
    fileNumbers = cellfun(@(x) str2double(x{1}), fileNumbers);
    [~, sortedIndices] = sort(fileNumbers);
    sortedFiles = files(sortedIndices);
end
