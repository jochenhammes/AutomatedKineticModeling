function outputArg1 = performAutoKinMod(pathInputFolder,keepTempfiles,pathNormalDB)

%% Step 0: Create Workdir

%Append filesep to path, if missing
if ~strcmp(pathInputFolder(end), filesep)
    pathInputFolder = [pathInputFolder filesep];
end

mkdir([pathInputFolder 'workdir']);

%% Step 1: DICOM Import

addpath('BatchDICOM_Import/');

clear foldersForInput
foldersForInput = dir([pathInputFolder]);

% remove linux folder-dots .. . and workidr
foldersForInput(strcmp({foldersForInput.name}, '..')) = [];
foldersForInput(strcmp({foldersForInput.name}, '.')) = [];
foldersForInput(strcmp({foldersForInput.name}, 'workdir')) = [];
% only folders
foldersForInput = foldersForInput([foldersForInput(:).isdir]);

for i=1:length(foldersForInput)
    fcnDICOMImportBatch([pathInputFolder foldersForInput(i).name], [pathInputFolder foldersForInput(i).name], '');
end

rmpath('BatchDICOM_Import/');

% Move created nifti files to workdir

for i=1:length(foldersForInput)
    clear filesInFolder
    filesInFolder = dir([pathInputFolder foldersForInput(i).name filesep '*.nii']);
    for j=1:length(filesInFolder)
        movefile([filesInFolder(j).folder filesep filesInFolder(j).name], [pathInputFolder 'workdir']);
    end
    clear filesInFolder foldersForInput i j
end


%% Step 2: Movement Correction

addpath('MovementCorrection/');
fcnMovementCorrection([pathInputFolder 'workdir/']);

rmpath('MovementCorrection/');

end

