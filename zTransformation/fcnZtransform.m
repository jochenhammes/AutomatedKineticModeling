function runWithSuccess = fcnZtransform(inputFolder, FilenamePropertiesInput, FolderNameSetOfNormals)

runWithSuccess = false;
%FilenamePropertiesInput = '*SRTM2_BPnd*';


pathMeanNifti = dir(['zTransformation' filesep FolderNameSetOfNormals filesep '*mean*.nii']);
pathStDevNifti = dir(['zTransformation' filesep FolderNameSetOfNormals filesep '*std*.nii']);

meanNifti = load_nii([pathMeanNifti.folder filesep pathMeanNifti.name])
stDevNifti = load_nii([pathStDevNifti.folder filesep pathStDevNifti.name])

%remove Zeros from stDev-Matrix
stDevNifti.img(stDevNifti.img == 0) = 0.0000001;

imageToZTransform = dir([inputFolder filesep FilenamePropertiesInput])

for i = 1:length(imageToZTransform)
    currentNii = load_nii([imageToZTransform(i).folder filesep imageToZTransform(i).name])
    zTransDevMap = currentNii;
    zTransDevMap.img = (currentNii.img - meanNifti.img) ./ stDevNifti.img;
    %Set all Deviation Values > 10 to 10 to avoid too large numbers in the file
    zTransDevMap.img(zTransDevMap.img > 10) = 10; 
    save_nii(zTransDevMap, [inputFolder filesep 'zDev_' imageToZTransform(i).name]);
end

runWithSuccess = true;
end

