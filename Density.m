% Add necessary paths 

%Put Vessel segment folder here
segmented_folder = 'C:\Users\first\OneDrive\Documents\MATLAB 3\MATLAB\retina\newestdata_usefor_fillsheet\RFMiD_all_pic\resized_OD_Vessel_Original_Seg_91'; 

%Put Original segment (Resized region image)
original_folder = 'C:\Users\first\OneDrive\Documents\MATLAB 3\MATLAB\retina\newestdata_usefor_fillsheet\RFMiD_all_pic\resized_OD_Original_Seg_91'; 

%{
segmented_folder = '/Users/mister1st/Downloads/New_internetdataset/ODE_resized/Nasal_ODE_Vessel'; %Vessel segment
original_folder = '/Users/mister1st/Downloads/New_internetdataset/ODE_resized/Nasal_ODE_Segment'; %Original seg
%}


filePattern1 = fullfile(segmented_folder, '*.jpg');
theFiles1 = dir(filePattern1);
segmented_files = sortNumerically(theFiles1);

filePattern2 = fullfile(original_folder, '*.jpg');
theFiles2 = dir(filePattern2);
original_files = sortNumerically(theFiles2);

% variables to store results
vessel_densities = zeros(length(segmented_files), 1);
file_names = cell(length(segmented_files), 1);

% Process each image
for i = 1:length(segmented_files)
   
    segmented_image = imread(fullfile(segmented_folder, segmented_files(i).name));
    original_image = imread(fullfile(original_folder, original_files(i).name));
    
    if size(segmented_image, 3) == 3
        segmented_image = rgb2gray(segmented_image);
    end
    
    threshold = graythresh(segmented_image);
    binary_binarized = imbinarize(segmented_image, threshold);
    
    %binarize original image
    gray_original = rgb2gray(original_image);
    optic_disc_threshold = graythresh(gray_original);
    optic_disc_mask = imbinarize(gray_original, optic_disc_threshold);

    % Label image
    [labeled_image, num_features] = bwlabel(binary_binarized);
    % Calculate region properties for the vessels
    regions = regionprops(labeled_image, 'Area', 'Perimeter', 'BoundingBox', 'Centroid');
    
    % Calculate vessel density
    total_vessel_area = sum([regions.Area]);
    optic_disc_area = sum(optic_disc_mask(:)); % Count the number of pixels
    vessel_density_optic_disc = total_vessel_area / optic_disc_area;
    
    % Store the results
    vessel_densities(i) = vessel_density_optic_disc;
    file_names{i} = segmented_files(i).name;
end

average_density = mean(vessel_densities);
std_density = std(vessel_densities);

% Create a table to store the individual results
individualResults = table(file_names, vessel_densities, 'VariableNames', {'FileName', 'VesselDensity'});

% Create a table to store the combined results
combinedResults = table({'Combined'}, average_density, std_density, ...
    'VariableNames', {'Group', 'AverageDensity', 'StandardDeviation'});


writetable(individualResults, 'Vessel_Density_Results.xlsx', 'Sheet', 1);

%writetable(combinedResults, 'Vessel_Density_Results.xlsx', 'Sheet', 2, 'WriteVariableNames', true);

% Display the tables
disp(individualResults);
disp(combinedResults);


% To ensure it process in correct order
function sortedFiles = sortNumerically(files)
    fileNames = {files.name};
    fileNumbers = regexp(fileNames, '\d+', 'match');
    fileNumbers = cellfun(@(x) str2double(x{1}), fileNumbers);
    [~, sortedIndices] = sort(fileNumbers);
    sortedFiles = files(sortedIndices);
end