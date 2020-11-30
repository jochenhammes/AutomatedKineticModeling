function runWithSuccess = fcnMovementCorrection(pathInputFolder, noGUI)

runWithSuccess = false;

%Job file for DICOM Import

clear subj;
FilenameProperties = '*.nii';
subj = dir([pathInputFolder FilenameProperties]);

%remove linux folder-dots .. .
subj(strcmp({subj.name}, '..')) = [];
subj(strcmp({subj.name}, '.')) = [];

%remove CT niftis, i.e. niftis that have a filesize > 55000000 bytes
subj([subj.bytes] > 55000000) = [];

%remove files with certain Prefixes
subj(startsWith({subj.name},'movCor_')) = [];
subj(startsWith({subj.name},'mean')) = [];

%prepare inputFileList
inputFileList = '';

for i=1:length(subj)
    inputFileList = [inputFileList '''' subj(i).folder filesep subj(i).name  '''' char(10)];
end

fprintf(inputFileList);


fin = fopen('MovCor_job.m', 'r');
fout = fopen('MovCor_job_INTERMEDIATE.m', 'w');

findstr1 = 'LIST_OF_INPUT_FILES';
replacestr1 = inputFileList;

while ~feof(fin)
    s = fgetl(fin);
    s = strrep(s, findstr1, replacestr1);
    
    fprintf(fout,'%s\n',s)
end

fclose(fin)
fclose(fout)

 jobfile = {'MovCor_job_INTERMEDIATE.m'};
 spm('defaults', 'PET');
 
%  %Open SPM GUI
if ~exist('noGUI')
    spm
end
 
 %Run job
 spm_jobman('serial', jobfile);
 
%  %Close SPM GUI again
if ~exist('noGUI')
    myfigures = get(groot,'children'); % Save handles of SPM windows
    handleOfMenu = find(endsWith({myfigures.Name},'Menu'));
    close(myfigures(handleOfMenu));
end

 %if ~isempty(subj) > 0
    runWithSuccess = true;
 %end

disp('done');

end
