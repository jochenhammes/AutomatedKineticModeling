function runWithSuccess = fcnNormalizePerfusionPETbased(pathInputFolder, noGUI)
% This function performes an automated template based normalization of a 4D
% dynmic PET series

runWithSuccess = false;

perfusionFramesToBeSummed = [2 5];

pathOutputFolder = pathInputFolder;

%Select Files to be normalized
clear subj;
FilenameProperties = 'ACOrig_4D*.nii';
subj = dir([pathInputFolder FilenameProperties]);

% load niftis,
% header and save back files
for i=1:length(subj)
    myCurrentNifti = load_untouch_nii([subj(i).folder filesep subj(i).name]);
    
    imageDimensions = size(myCurrentNifti.img);
    numberOfFrames = size(myCurrentNifti.img,4);
    imageDimensions =imageDimensions(1:3);
    
    newImage = zeros(imageDimensions, class(myCurrentNifti.img));
    
    %Sum image frames
    for j=1:(perfusionFramesToBeSummed(2) - perfusionFramesToBeSummed(1) + 1)
        currentFrameNumber = perfusionFramesToBeSummed(1) - 1 + j;
        newImage = newImage + myCurrentNifti.img(:,:,:,currentFrameNumber);
    end
    
    %save Summed image
    myCurrentNifti.hdr.dime.dim(5) = 1;
    myCurrentNifti.hdr.hist.descrip = 'summed perfusion frames';
    myCurrentNifti.img = newImage;
    save_untouch_nii(myCurrentNifti, [pathOutputFolder 'SumPerf_' subj(i).name]);
    
    clear myCurrentNifti
    
    
    %Prepare jobfile
    
    fin = fopen('normalizePerfusionBased_batch.m', 'r');
    fout = fopen('normalizePerfusionBased_batch_INTERMEDIATE.m', 'w');
    
    
    %prepare outputFileList
    outputFileList = '';
    for k=1:numberOfFrames
        outputFileList = [outputFileList '''' subj(i).folder filesep subj(i).name ',' num2str(k)  '''' char(10)];
    end
    fprintf(outputFileList);
    
    
    findstr1 = 'PATH_TO_SUMMED_PERFUSION_PET';
    replacestr1 = [pathOutputFolder 'SumPerf_' subj(i).name];
    
    findstr2 = 'LIST_OUTPUT_FILES';
    replacestr2 = outputFileList;
    
    while ~feof(fin)
        s = fgetl(fin);
        s = strrep(s, findstr1, replacestr1);
        s = strrep(s, findstr2, replacestr2);
        
        fprintf(fout,'%s\n',s)
    end
    
    fclose(fin)
    fclose(fout)
    
    
    % run jobfile
    jobfile = {'normalizePerfusionBased_batch_INTERMEDIATE.m'};
    spm('defaults', 'PET');
    
    %Open SPM GUI
    if ~exist('noGUI')
        spm
    end
    
    %Run job
    spm_jobman('serial', jobfile);
    
    %Close SPM GUI again
    if ~exist('noGUI')
        myfigures = get(groot,'children'); % Save handles of SPM windows
        handleOfMenu = find(endsWith({myfigures.Name},'Menu'));
        close(myfigures(handleOfMenu));
    end
    
end



runWithSuccess = true;
end

