function runWithSuccess = fcnSkullStrip(inputFolder)

runWithSuccess = false;

pathBrainmask = dir(['skullStripping' filesep 'brainmask_0.70_79x95x78.nii']);
brainMaskNifti = load_nii([pathBrainmask.folder filesep pathBrainmask.name]);

imagesToSkullStrip = dir([inputFolder filesep '*.nii'])

for i = 1:length(imagesToSkullStrip)
    currentNii = load_nii([imagesToSkullStrip(i).folder filesep imagesToSkullStrip(i).name])
    currentSkullStripped = currentNii;
    currentSkullStripped.img = currentNii.img .* brainMaskNifti.img;
    save_nii(currentSkullStripped, [inputFolder filesep 'BET_' imagesToSkullStrip(i).name]);
end

runWithSuccess = true;
end

