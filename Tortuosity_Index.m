% vessel region
folderA = 'C:\Users\first\Documents\MATLAB 3\MATLAB\retina\retina_data\New_internetdataset\ODE_resized\ODE_rvr'; 
% vessel segment
folderB = 'C:\Users\first\Documents\MATLAB 3\MATLAB\retina\retina_data\New_internetdataset\ODE_resized\ODE_rvs';

 %for 4 quadrant
folderC = 'C:\Users\first\Documents\MATLAB 3\MATLAB\retina\retina_data\New_internetdataset\ODE_resized\Temporal_ODE_Vessel'; % dont forget to uncomment any code relavent to folderC if gona use


imageFilesA = dir(fullfile(folderA, '*.jpg'));
imageFilesB = dir(fullfile(folderB, '*.jpg'));
imageFilesC = dir(fullfile(folderC, '*.jpg'));

% Sort filenames numerically
imageFilesA = sortFilesNumerically(imageFilesA);
imageFilesB = sortFilesNumerically(imageFilesB);
imageFilesC = sortFilesNumerically(imageFilesC);

% store results
resultsTable = table('Size', [length(imageFilesA), 3], ...
    'VariableTypes', {'string', 'double', 'double'}, ...
    'VariableNames', {'ImageName', 'SegmentCount', 'AverageTortuosity'});


for i = 1:length(imageFilesA)
    a = fullfile(folderA, imageFilesA(i).name);
    b = fullfile(folderB, imageFilesB(i).name);
    c = fullfile(folderC, imageFilesC(i).name);

    %fprintf('Processing image pair %d/%d: %s and %s\n', i, length(imageFilesA), imageFilesA(i).name, imageFilesB(i).name);
    
    % Load and preprocess images
    vesselRegion = imread(a);
    vesselRegion = imbinarize(im2gray(vesselRegion));
    opticDiscRegion = imread(b);
    opticDiscRegion = imbinarize(im2gray(opticDiscRegion));
    vesselquadrant = imread(c);
    vesselquadrant = imbinarize(im2gray(vesselquadrant));

    % if want to find TI without optic disc uncomment this
    %selected = vesselRegion & ~opticDiscRegion;


    % if want to find TI only optic disc uncomment this
    %selected = opticDiscRegion;

     % if want to find TI only for 4 quadrant
     selected = vesselquadrant;


    % image processing borrow from bifurication code
    cleanedImage = imopen(selected, strel('disk', 2));
    verticalProfile = sum(cleanedImage, 2);
    row1 = find(verticalProfile, 1, 'first');
    row2 = find(verticalProfile, 1, 'last');
    horizontalProfile = sum(cleanedImage, 1);
    column1 = find(horizontalProfile, 1, 'first');
    column2 = find(horizontalProfile, 1, 'last');
    croppedImage = cleanedImage(row1:row2, column1:column2);


        % Check for empty cropped region
    if ~any(croppedImage(:))
        fprintf('Image %s: Empty cropped region.\n', imageFilesC(i).name);
        resultsTable.ImageName(i) = string(imageFilesA(i).name);
        resultsTable.SegmentCount(i) = 0;
        resultsTable.AverageTortuosity(i) = NaN;
        continue;
    end

    %% Resize Image to Reduce Noise
    [r, c] = size(croppedImage);
    if r > c
        resizedImage = imresize(croppedImage, 200 / r);
    else
        resizedImage = imresize(croppedImage, 200 / c);
    end

    %% Noise Removal and Filling Holes
    minClusterSize = 5;
    maskCleaned = bwareaopen(resizedImage, minClusterSize);
    filledMask = imfill(maskCleaned, 'holes');

    %% Skeletonization
    skelImage = bwskel(filledMask);
    skelImage = bwmorph(skelImage, 'spur', 7);
    skelImage = bwareaopen(skelImage, minClusterSize);

    %% Detect and Remove Bifurcation Points
    branchPoints = bwmorph(skelImage, 'branchpoints');
    deletionMask = imdilate(branchPoints, strel('disk', 2));
    skelImage(deletionMask) = 0;

    %% Label Segments
    [labeledSkeleton, numSegments] = bwlabel(skelImage, 8);

% Tortuosity Calculation
tortuosityValues = zeros(numSegments, 1);
for j = 1:numSegments
        segmentMask = (labeledSkeleton == j);
        endPoints = bwmorph(segmentMask, 'endpoints');
        [yEnd, xEnd] = find(endPoints);
        
        if length(xEnd) == 2
            startPoint = [yEnd(1), xEnd(1)];
            endPoint = [yEnd(2), xEnd(2)];
        else
            tortuosityValues(j) = NaN;
            continue;
        end

        boundary = bwtraceboundary(segmentMask, startPoint, 'E');
        if isempty(boundary)
            tortuosityValues(j) = NaN;
            continue;
        end

        [~, uniqueIdx] = unique(boundary, 'rows', 'stable');
        boundary = boundary(uniqueIdx, :);
        y = boundary(:, 1);
        x = boundary(:, 2);
        pathLength = sum(sqrt(sum(diff([x, y]).^2, 2)));
        straightLineDistance = sqrt((startPoint(1) - endPoint(1))^2 + ...
                                    (startPoint(2) - endPoint(2))^2);
        if straightLineDistance > 0
            tortuosityValues(j) = pathLength / straightLineDistance;
        else
            tortuosityValues(j) = NaN;
        end
    end

    validIndices = ~isnan(tortuosityValues);
    tortuosityValues = tortuosityValues(validIndices);

    % Compute average tortuosity
    if ~isempty(tortuosityValues)
        averageTortuosity = mean(tortuosityValues);
    else
        averageTortuosity = NaN;
    end

    % Store results in the table
    resultsTable.ImageName(i) = string(imageFilesA(i).name);
    resultsTable.SegmentCount(i) = numSegments;
    resultsTable.AverageTortuosity(i) = averageTortuosity;
end

% Write results to an Excel file
outputFile = fullfile(pwd, 'ODEinternetTortuosityResultsVer3.xlsx');
writetable(resultsTable, outputFile);
fprintf('Results saved to %s\n', outputFile);

%Sort Files Numerically
function sortedFiles = sortFilesNumerically(files)
    [~, fileNames, ~] = cellfun(@fileparts, {files.name}, 'UniformOutput', false);
    numericNames = cellfun(@str2double, regexp(fileNames, '\d+', 'match', 'once'));
    [~, sortOrder] = sort(numericNames);
    sortedFiles = files(sortOrder);
end