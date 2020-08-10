function runWithSuccess = fcnSetACOrigin(pathInputFolder, pathOutputFolder, FilenameProperties)

runWithSuccess = false;

%pathInputFolder = '/DATA/hammesj/Scripts/AutomatedKineticModeling/SetACOrigin/newtest/';
%pathOutputFolder = '/DATA/hammesj/Scripts/AutomatedKineticModeling/SetACOrigin/workdir/';
pathOutputFolder = pathInputFolder;

%Select Files to be normalized, run recursively through all subfolders with **
clear subj;
FilenameProperties = '4D*.nii';
subj = dir([pathInputFolder FilenameProperties]);

% load sample headers for PET and CT
load('sampleCT_header.mat')
load('samplePET_header.mat')

% load niftis, check if matrix is 512 (--> i.e. CT, otherwise PET), change
% header and save back files
for i=1:length(subj)
    myCurrentNifti = load_untouch_nii([subj(i).folder filesep subj(i).name]);
    
    if size(myCurrentNifti.img,1) == 512
        disp('CT - matrix 512x512')
        sampleCT_header.img = myCurrentNifti.img;
        sampleCT_header.fileprefix = ['ACOrig_' subj(i).name];
        save_nii(sampleCT_header, [pathOutputFolder 'ACOrig_' subj(i).name]);
    elseif size(myCurrentNifti.img,1) == 400
        disp('PET - matrix 400x400x148');
        samplePET_header.img = myCurrentNifti.img;
        samplePET_header.fileprefix = ['ACOrig_' subj(i).name];
        save_nii(samplePET_header, [pathOutputFolder 'ACOrig_' subj(i).name]);
    else
        disp('no sample header for this matrix size available');
    end
    
    clear myCurrentNifti
    
end

runWithSuccess = true;

end