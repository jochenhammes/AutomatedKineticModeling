%------------------------------------------------------
% Runs through Folders and makes SPM DICOM-Import
%------------------------------------------------------



clear all

parentPath = '/DATA/hammesj/FTLD_AV1451_CGN/';
%List of folders with patientData
subjects = dir(strcat(parentPath,'*.nii'));

parentContents = dir(parentPath);
patientFolders = {parentContents([parentContents(:).isdir]).name};


%Remove '.' and '..' from list of subfolders
patientFolders(ismember(patientFolders, {'.','..'})) = [];

%Run through all real folders in directory

for i = 1:size(patientFolders,2)
    
    CurrentFullPath = [parentPath patientFolders{i} '/'];
    
    CurrentFilename = [patientFolders{i} '.nii'];
    CurrentFullPath = [parentPath patientFolders{i} '/'];
    
    fcnDICOMImportBatch(CurrentFullPath,'*');
       
    
    
end
