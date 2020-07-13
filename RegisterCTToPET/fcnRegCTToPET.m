function runWithSuccess = fcnRegCTToPET(pathInputFolder)

runWithSuccess = false;

%pathInputFolder = '/DATA/hammesj/PI2620_KinMod/Simsek/Simsek/';

clear subj_CT;
clear subj_PET;


FilenameProperties = 'ACOrig_*.nii';
subj_CT = dir([pathInputFolder filesep 'ACCT' filesep FilenameProperties]);
pathToCT = [subj_CT(1).folder filesep subj_CT(1).name];

subj_PET = dir([pathInputFolder filesep 'PI2620_fulldyn' filesep FilenameProperties]);
pathToPET = [subj_PET(1).folder filesep subj_PET(1).name];

%Prepare jobfile

fin = fopen('RegCTToPET_job.m', 'r');
fout = fopen('RegCTToPET_job_INTERMEDIATE.m', 'w');

findstr1 = 'PATH_TO_PET_FRAME2';
replacestr1 = pathToPET;

findstr2 = 'PATH_TO_CT';
replacestr2 = pathToCT;

while ~feof(fin)
    s = fgetl(fin);
    s = strrep(s, findstr1, replacestr1);
    s = strrep(s, findstr2, replacestr2);
    
    fprintf(fout,'%s\n',s)
end

fclose(fin)
fclose(fout)

% run jobfile

 jobfile = {'RegCTToPET_job_INTERMEDIATE.m'};
 spm('defaults', 'PET');
 
 %Open SPM GUI
 spm
 
 %Run job
 spm_jobman('serial', jobfile);
 
 %Close SPM GUI again
 myfigures = get(groot,'children'); % Save handles of SPM windows
 handleOfMenu = find(endsWith({myfigures.Name},'Menu'));
 close(myfigures(handleOfMenu));
 
 %if ~isempty(subj) > 0
    runWithSuccess = true;
 %end

disp('done');

end
