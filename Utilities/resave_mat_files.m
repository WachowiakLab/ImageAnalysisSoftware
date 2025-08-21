% Clear the workspace and command window
clc;
clear;

% Select multiple files using uigetfile
[fileNames, filePath] = uigetfile('*.mat', 'Select MAT Files', 'MultiSelect', 'on');

% Check if the user clicked Cancel
if isequal(fileNames,0) || isequal(filePath,0)
    disp('Operation cancelled.');
    return;
end

% Loop through each selected file
for i = 1:length(fileNames)
    % Construct the full file path
    fullFilePath = fullfile(filePath, fileNames{i});
    
    % Load the MAT file
    try
        data = load(fullFilePath);
    catch ME
        disp(['Error loading file ', fullFilePath]);
        disp(ME.message);
        continue; % Skip to the next file
    end
    
    % Perform any operations on the loaded data if needed
    % For example, you can modify 'data' here
    
    % Save the modified data back to the same file
    try
        save(fullFilePath, '-struct', 'data');
    catch ME
        disp(['Error saving file ', fullFilePath]);
        disp(ME.message);
        continue; % Skip to the next file
    end
    
    disp(['File ', fullFilePath, ' successfully processed and saved.']);
end

disp('All selected files processed successfully.');