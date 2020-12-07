function runWithSuccess = fcnSmooth4D(pathInputFolder, FilenameProperties)

runWithSuccess = false;


%Select Files to be normalized, run recursively through all subfolders with **
clear subj;
FilenameProperties = 'wACOrig_4D_movCor*nii';
subj = dir([pathInputFolder FilenameProperties]);

% load unsmoothed nifti

myCurrentNifti = load_nii([subj(1).folder filesep subj(1).name]);
smoothedNifti = myCurrentNifti;

numberOfFrames = size(myCurrentNifti.img, 4)

for i = 1:numberOfFrames
    smoothedNifti.img(:,:,:,i) = smooth3(myCurrentNifti.img(:,:,:,i), 'box', [3 3 3]);
end

save_nii(smoothedNifti, [subj.folder filesep subj.name]);

runWithSuccess = true;

end