function runWithSuccess = fcnDICOMImportBatch(pathInputFolder, pathOutputFolder, FilenameProperties)

%   TODO
%   []  Change WorkingDirectory to a dynamic path
%   []	Filenameprooerties anpassen

runWithSuccess = false;

%pathInputFolder = '/DATA/hammesj/PI2620_KinMod/Simsek/Simsek/PI2620_fulldyn/';
pathOutputFolder = pathInputFolder;
%pathOutputFolder = '/DATA/hammesj/Scripts/AutomatedKineticModeling/BatchDICOM_Import/workdir';

%Append filesep to path, if missing
if ~strcmp(pathInputFolder(end), filesep)
    pathInputFolder = [pathInputFolder filesep];
end

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
 
%  %Open SPM GUI
%  spm
%  
 %Run job
 spm_jobman('serial', jobfile);
 
%  %Close SPM GUI again
%  myfigures = get(groot,'children'); % Save handles of SPM windows
%  handleOfMenu = find(endsWith({myfigures.Name},'Menu'));
%  close(myfigures(handleOfMenu));
%  
 %if ~isempty(subj) > 0
    runWithSuccess = true;
 %end

disp('done');

end
