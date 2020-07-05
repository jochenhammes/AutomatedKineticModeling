function runWithSuccess = fcnDICOMImportBatch(pathInputFolder, pathOutputFolder, FilenameProperties)

%   TODO
%   []  Change WorkingDirectory to a dynamic path
%   []	Filenameprooerties anpassen

runWithSuccess = false;

%pathInputFolder = '/Volumes/MMNI_RAID/RAID_MMNI/AphasicPatients/DICOM/TV/';
%pathOutputFolder = pathInputFolder;
pathOutputFolder = '/DATA/hammesj/Scripts/AutomatedKineticModeling/BatchDICOM_Import/workdir';


%Job file for DICOM Import

%Select Files to be normalized, run recursively through all subfolders with **
clear subj;
FilenameProperties = '**';
subj = dir([pathInputFolder FilenameProperties]);

%remove linux folder-dots .. .
subj(strcmp({subj.name}, '..')) = [];
subj(strcmp({subj.name}, '.')) = [];

%prepare inputFileList
inputFileList = '';

for i=1:length(subj)
    inputFileList = [inputFileList '''' subj(i).folder filesep subj(i).name  '''' char(10)];
end

fprintf(inputFileList);


fin = fopen('DICOMImportBatch_job.m', 'r');
fout = fopen('DICOMImportBatch_jobINTERMEDIATE.m', 'w');

findstr1 = 'LIST_OF_INPUT_FILES';
replacestr1 = inputFileList;
findstr2 = 'PATH_TO_OUTPUT_FOLDER';
replacestr2 = pathOutputFolder;

while ~feof(fin)
    s = fgetl(fin);
    s = strrep(s, findstr1, replacestr1);
    s = strrep(s, findstr2, replacestr2);
    
    fprintf(fout,'%s\n',s)
end

fclose(fin)
fclose(fout)

 jobfile = {'DICOMImportBatch_jobINTERMEDIATE.m'};
 spm('defaults', 'PET');
 spm_jobman('serial', jobfile);

 
 %if ~isempty(subj) > 0
    runWithSuccess = true;
 %end

disp('done');

end
