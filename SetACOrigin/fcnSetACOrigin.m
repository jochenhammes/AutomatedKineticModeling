function runWithSuccess = fcnSetACOrigin(pathInputFolder, pathOutputFolder, FilenameProperties)

runWithSuccess = false;

pathInputFolder = '/DATA/hammesj/Scripts/AutomatedKineticModeling/SetACOrigin/newtest/';
pathOutputFolder = '/DATA/hammesj/Scripts/AutomatedKineticModeling/SetACOrigin/workdir/';

%Select Files to be normalized, run recursively through all subfolders with **
clear subj;
FilenameProperties = '*.nii';
subj = dir([pathInputFolder FilenameProperties]);

% load sample headers for PET and CT
load('sampleCT_header.mat')
%load('sample4DPET_header.mat')

% load niftis, check if matrix is 512 (--> i.e. CT, otherwise PET), change
% header and save back files
for i=1:length(subj)
    myNiftis(i) = load_untouch_nii([subj(i).folder filesep subj(i).name]);
    
    if size(myNiftis(i).img,1) == 512
        disp('CT');
        sampleCT_header.img = myNiftis(i).img;
        sampleCT_header.fileprefix = ['ACOrig_' subj(i).name];
        save_nii(sampleCT_header, [pathOutputFolder 'ACOrig_' subj(i).name]);
    end
    
end


end