function outputArg1 = performAutoKinMod(pathInputFolder, app, keepTempfiles,FolderNameSetOfNormals, numberOfFramesToModel)


addpath('setup');


try
    app.ProtocolTextArea.Value = [{[datestr(datetime('now')) ' processing started']}, app.ProtocolTextArea.Value(:)'];
end


%% Step 0: Create Workdir


try
    app.ProtocolTextArea.Value = [{[datestr(datetime('now')) ' create workdir']}, app.ProtocolTextArea.Value(:)'];
end

%Append filesep to path, if missing
if ~strcmp(pathInputFolder(end), filesep)
    pathInputFolder = [pathInputFolder filesep];
end

mkdir([pathInputFolder 'workdir']);

%% Step 1: DICOM Import


try
    app.ProtocolTextArea.Value = [{[datestr(datetime('now')) ' import DICOM']}, app.ProtocolTextArea.Value(:)'];
end

addpath('BatchDICOM_Import');

foldersForInput = dir([pathInputFolder]);

% remove linux folder-dots .. . and workidr
foldersForInput(strcmp({foldersForInput.name}, '..')) = [];
foldersForInput(strcmp({foldersForInput.name}, '.')) = [];
foldersForInput(strcmp({foldersForInput.name}, 'workdir')) = [];
% only folders
foldersForInput = foldersForInput([foldersForInput(:).isdir]);

for i=1:length(foldersForInput)
    fcnDICOMImportBatch([pathInputFolder foldersForInput(i).name], [pathInputFolder foldersForInput(i).name], '','noGUI');
end

%remove intermediate file from DICOM import
try
    delete('DICOMImportBatch_jobINTERMEDIATE.m')
end

rmpath('BatchDICOM_Import');

% Move created nifti files to workdir

for i=1:length(foldersForInput)
    filesInFolder = dir([pathInputFolder foldersForInput(i).name filesep '*.nii']);
    for j=1:length(filesInFolder)
        movefile([filesInFolder(j).folder filesep filesInFolder(j).name], [pathInputFolder 'workdir']);
    end
end


%% Step 2: Movement Correction

try
    app.ProtocolTextArea.Value = [{[datestr(datetime('now')) ' Movement Correction started']}, app.ProtocolTextArea.Value(:)'];
end

addpath('MovementCorrection');
fcnMovementCorrection([pathInputFolder 'workdir' filesep], 'noGUI');

rmpath('MovementCorrection');

%remove intermediate file from Movement Correction
try
    delete('MovCor_job_INTERMEDIATE.m')
end

%% Step 3: convert to 4D Nifti

try
    app.ProtocolTextArea.Value = [{[datestr(datetime('now')) ' 4D Nifti conversion']}, app.ProtocolTextArea.Value(:)'];
end

addpath('ConvertTo4D');
if ~exist('numberOfFramesToModel','var')
    numberOfFramesToModel = 23;
end
conversion4DSuccessful = fcnConvert4D([pathInputFolder 'workdir' filesep], 'movCor_*.nii', numberOfFramesToModel, 'noGUI');

if conversion4DSuccessful
    % delete non4D files
    delete([pathInputFolder 'workdir' filesep '4D*.mat']);
    delete([pathInputFolder 'workdir' filesep 'movCor_*.nii']);
end

rmpath('ConvertTo4D');

%remove intermediate file from 4D Conversion 
try
    delete('Convert4D_job_INTERMEDIATE.m')
end

%% Step 4: SetAC origin

try
    app.ProtocolTextArea.Value = [{[datestr(datetime('now')) ' Set AC Origin ']}, app.ProtocolTextArea.Value(:)'];
end

addpath('SetACOrigin');

fcnSetACOrigin([pathInputFolder 'workdir' filesep], [pathInputFolder 'workdir' filesep], '4D*.nii', numberOfFramesToModel);

rmpath('SetACOrigin');


%% Step 5: Normalize against perfusion template

try
    app.ProtocolTextArea.Value = [{[datestr(datetime('now')) ' Spatial normalization started']}, app.ProtocolTextArea.Value(:)'];
end

addpath('NormalizePerfusionPETbased');

fcnNormalizePerfusionPETbased([pathInputFolder 'workdir' filesep], 'noGUI');

rmpath('NormalizePerfusionPETbased');

%remove intermediate file from spatial normalization
try
    delete('normalizePerfusionBased_batch_INTERMEDIATE.m')
end




%% Step 6: Run qmodeling with the Normalized Dataset to

try
    app.ProtocolTextArea.Value = [{[datestr(datetime('now')) ' kinetic modeling started']}, app.ProtocolTextArea.Value(:)'];
end

addpath('autoQModeling');

% clear qModeling input folder of nifti files
delete(['autoQModeling' filesep 'workdir' filesep 'studies' filesep 'automatedCGN' filesep '*.nii']);
delete(['autoQModeling' filesep 'workdir' filesep 'studies' filesep 'automatedCGN' filesep '*.hdr']);
delete(['autoQModeling' filesep 'workdir' filesep 'studies' filesep 'automatedCGN' filesep '*.img']);

%delete qModeling results fodler
try
    rmdir(['autoQModeling' filesep 'workdir' filesep 'results'], 's');
end
try
    mkdir(['autoQModeling' filesep 'workdir' filesep 'results']);
end

%move normalized 4D file to qModeling input folder
normalized4DNifti = dir([pathInputFolder 'workdir' filesep 'wAC*.nii']);
copyfile([normalized4DNifti(1).folder filesep normalized4DNifti(1).name], ['autoQModeling' filesep 'workdir' filesep 'studies' filesep 'automatedCGN']);

oldfolder = cd('autoQModeling');

run('localPathDefinition.m');
addpath(path_qmodeling);
autoQModelingCGN();
cd(oldfolder);

% move results files back to orginal directory and rename folder
movefile(['autoQModeling' filesep 'workdir' filesep 'results'], pathInputFolder);
movefile([pathInputFolder filesep 'results'], [pathInputFolder filesep 'results_kinetic_modeling' filesep]);

rmpath(path_qmodeling);


%% Step 7: Create z transformed deviation map

try
    app.ProtocolTextArea.Value = [{[datestr(datetime('now')) ' Create z transformed deviation map']}, app.ProtocolTextArea.Value(:)'];
end

addpath('zTransformation');

FolderNameSetOfNormals = 'PI2620_HC_Piramal';
fcnZtransform([pathInputFolder 'results_kinetic_modeling' filesep],'*SRTM2_BPnd*', FolderNameSetOfNormals);

rmpath('zTransformation');


%% Step 8: Skull stripping

try
    app.ProtocolTextArea.Value = [{[datestr(datetime('now')) ' Remove skull']}, app.ProtocolTextArea.Value(:)'];
end

addpath('skullStripping');

fcnSkullStrip([pathInputFolder 'results_kinetic_modeling' filesep]);

rmpath('skullStripping');


%% Step 9: Human readable Output as Png-image and dicom

try
    app.ProtocolTextArea.Value = [{[datestr(datetime('now')) ' Overview-Output Sheet']}, app.ProtocolTextArea.Value(:)'];
end


overlaySlices([pathInputFolder 'results_kinetic_modeling' filesep 'BET_zDev_automatedCGN_SRTM2_BPnd_image.nii'], [pathInputFolder 'results_kinetic_modeling' filesep 'BET_zDev_automatedCGN_SRTM2_BPnd_image.nii'], pathInputFolder, [pathInputFolder 'results_kinetic_modeling' filesep]);



%% Finished 

rmpath('setup');

try
    app.ProtocolTextArea.Value = [{[datestr(datetime('now')) ' done']}, app.ProtocolTextArea.Value(:)'];
end

end

