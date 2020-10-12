function runWithSuccess = fcnConvert4D(pathInputFolder, FilenameProperties, numberOfFramesToModel, noGUI)

runWithSuccess = false;

FilenameProperties = 'movCor_*.nii';

clear subj;

%search inputFolder for multiple 3D files
subj = dir([pathInputFolder FilenameProperties]);

%prepare inputFileList
inputFileList = '';

if length(subj) < numberOfFramesToModel
    numberOfFramesToModel = length(subj);
end

for i=1:numberOfFramesToModel
    inputFileList = [inputFileList '''' subj(i).folder filesep subj(i).name  '''' char(10)];
end

fprintf(inputFileList);

%set outputFilename based on first inputfile
outputFilename = ['4D_' subj(1).name];

fin = fopen('Convert4D_job.m', 'r');
fout = fopen('Convert4D_job_INTERMEDIATE.m', 'w');

findstr1 = 'LIST_OF_INPUT_FILES';
replacestr1 = inputFileList;

findstr2 = 'OUTPUT_FILENAME';
replacestr2 = outputFilename;

while ~feof(fin)
    s = fgetl(fin);
    s = strrep(s, findstr1, replacestr1);
    s = strrep(s, findstr2, replacestr2);
    
    fprintf(fout,'%s\n',s)
end

fclose(fin)
fclose(fout)

 jobfile = {'Convert4D_job_INTERMEDIATE.m'};
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

 %if ~isempty(subj) > 0
    runWithSuccess = true;
 %end

disp('done');

end
