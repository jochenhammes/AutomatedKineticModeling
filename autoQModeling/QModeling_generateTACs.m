function QModeling_generateTACs(studies_path,reference_path,interest_path,save_path,varargin)
% This function permits to generate a set of TACs of interest and
% reference from a set of dynamic PET studies and their respective masks.
% Three items are needed: 
%   1) a directory containing one folder for each subject, which should 
% contains the PET images.
%   2) A folder for the masks of interest which must contains one file 
% per study with the same name of the study folder.
%   3) A folder for the reference masks, which must contains one file 
% per study with the same name of the study folder.
% 
% NIfTI and Analyze formats are allowed for the studies and masks
%
% Usage: call QModeling_generateTACs function with the following input
% parameters.
%
%     - studies_path: path to a directory containing one image folder for each
%     patient. The image file format allowed is NIfTI or Analyze
% 
%     - reference_path: path to a directory which contains the reference
%     masks in NIfTI or Analyze format (with the same name as the study folder).
% 
%     - interest_path: path to a directory which contains the masks of the
%     region of interest in NIfTI or Analyze format (with the same name as the study folder).
% 
% The number of folders at "studies_path", the number of files at "reference_path" and 
% the number of files at "interest_path" must be the same
% 
%     - save_path: path to a directory where the results will be saved. If
%     the path is 'd', the current directory will be used .
% 
%     - timesfile_path (optional): path to a .txt file containing the start and end times
%       for each frame. Default times will be loaded if this optional file is not added 
%       and the studies do not include times series.
%---------------------------------------------------------------------------------
% QModeling_generateTACs is part of QModeling.
%
% QModeling is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% QModeling is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with QModeling.  If not, see <http://www.gnu.org/licenses/>.
%---------------------------------------------------------------------------------
% Copyright (C) 2020 Francisco Javier Lopez Gonzalez, José Paredes Pacheco, Karl-Khader
% Thurnhofer Hemsi


h_QM=QModeling('Visible','off');
pause(0.001);

format long;
global QMf_logfile;

QM_initiateLogFile();

fprintf(QMf_logfile,strcat('\n','----------------------------------------------','\n'));
fprintf(QMf_logfile,date);
fprintf(QMf_logfile,strcat('\n','----------------------------------------------','\n'));
aux_date=datestr(now);
fprintf(QMf_logfile,strcat(aux_date(end-7:end),' Starting command-line function QModeling_generateTACs.m with parameters:\n'));
fprintf(QMf_logfile,strcat(' -studies_path:',studies_path,'\n'));
fprintf(QMf_logfile,strcat(' -reference_path:',reference_path,'\n'));
fprintf(QMf_logfile,strcat(' -interest_path:',interest_path,'\n'));
fprintf(QMf_logfile,strcat(' -save_path:',save_path,'\n'));
if (nargin==5), fprintf(QMf_logfile,strcat(' -time_table:',varargin{1},'\n')); end


disp('------------------------------------------------------')
disp(['Starting job at ', datestr(now)])
disp('') 

aux_date=datestr(now);
fprintf(QMf_logfile,strcat(aux_date(end-8:end),' Preparing TACs \n'));

studies_folder=dir(studies_path);   
studies_folder=studies_folder(3:end,:);
num_studies=length(studies_folder);
multiframe=false;
no_times=(nargin==4);

reference_tac=cell(num_studies,1);
interest_tac=cell(num_studies,1);

start=tic;
for j=1:num_studies   
    study_name=studies_folder(j).name;     
    path_study_folder=strcat(studies_path,filesep,study_name,filesep);
    
    images=dir(strcat(path_study_folder,'*.img')); %trying to load Analyze format    
    if isempty(images)
        images=dir(strcat(path_study_folder,'*.nii')); %trying to load NIfTI format
    end
    
    if isempty(images) %the format file of the study is not Analyz nor NIfTI
        msgError=strcat(['  ERROR: Input study ', study_name, ' does not have the expected format (.nii or .hdr/.img).']);
        fprintf(QMf_logfile,strcat(msgError,'\n'));
        error(msgError);
    else
        num_files=length(images);
        if num_files==1 % is a multiframe study
           image_hdr=spm_vol(strcat(path_study_folder,images.name));
           num_files=length(image_hdr);
           multiframe=true;
        end
    end
    
    try % trying to load reference mask
        path_reference_file=spm_select('ExtFPList',reference_path,strcat(study_name,'.nii|',study_name,'.img'));
        reference_hdr=spm_vol(path_reference_file);
        reference_mask=spm_read_vols(reference_hdr);
        id_ref=unique(reference_mask);
        id_ref=id_ref(2:end);           

    catch 
        fprintf(QMf_logfile,strcat(['  ERROR: Opening reference mask region of ', study_name],'\n'));
        error(['ERROR Opening reference mask region of ', study_name,'. Pay attention to the format file (NIfTI and Analyze format are accepted)']);
    end

    try  % trying to load interest mask
        path_interest_file=spm_select('ExtFPList',interest_path,strcat(study_name,'.nii|',study_name,'.img'));
        interest_hdr=spm_vol(path_interest_file);
        interest_mask=spm_read_vols(interest_hdr);
        id_int=unique(interest_mask);
        id_int=id_int(2:end); 
    catch 
        fprintf(QMf_logfile,strcat(['  ERROR: Opening interest mask region of ', study_name],'\n'));
        error(['ERROR Opening interest mask region of ',study_name]);
    end

    reference_tac{j}=zeros(1,num_files);
    interest_tac{j}=zeros(1,num_files);

    times=zeros(num_files,2);
    for frame=1:num_files
        if multiframe
            current_im=spm_read_vols(image_hdr(frame));
        else
            image_hdr=spm_vol(strcat(path_study_folder,images(frame).name));
            current_im= spm_read_vols(image_hdr);
        end
        %Eliminate posible NaNs from mean calculation
        current_region=current_im(reference_mask==id_ref);
        reference_tac{j}(frame) = mean(current_region(~isnan(current_region)));
        %reference_tac{j}(frame)=mean(current_im(reference_mask==id_ref));
        current_region=current_im(interest_mask==id_int);
        interest_tac{j}(frame) = mean(current_region(~isnan(current_region)));
        %interest_tac{j}(frame)=mean(current_im(interest_mask==id_int));

        if (no_times)
            try
                times(frame,1) = image_hdr(frame).private.timing.toffset;
                times(frame,2) = times(frame,1) + image_hdr(frame).private.timing.tspace;  
                if (frame==num_files)
                    no_times=false;
                end
            catch
                if (no_times) && (j==num_studies) %is the last study
                    fprintf(QMf_logfile,strcat('  ERROR: Reading the PET times. Loading default times','\n'));
                    actualpath=mfilename('fullpath');
                    [path, ~, ~]=fileparts(actualpath);
                    aux = load(strcat(fileparts(path),filesep,'TimeTable.txt'));
                    times = aux(1:num_files,:);                    
                end
            end
        end
    end

    if (nargin==5) && ~(no_times)
        aux = load(varargin{1});
        times = aux(1:num_files,:);
        no_times=false;
    end

    disp(['TACs from study ',study_name,' generated']);
end

fprintf(QMf_logfile,strcat(aux_date(end-8:end),' TACs generated \n'));

tseg = ((times(:,1)+times(:,2))/2);

disp('Writing TACs in file...');
fprintf(QMf_logfile,strcat(aux_date(end-8:end),' Writing TACs in file... \n'));
try        
    if strcmp(save_path,'d') %default directory-> we save at the current directory
        f=fopen('tacs.txt','wt');
    else
        f=fopen(strcat(save_path,filesep,'tacs.txt'),'wt');
    end

    fprintf(f,'%f\t',tseg);
    for j=1:num_studies
        fprintf(f,'\n');
        fprintf(f,'%f\t',reference_tac{j});
        fprintf(f,'\n');        
        fprintf(f,'%f\t',interest_tac{j});

    end

    fclose(f);
    
    if strcmp(save_path,'d'), aux_save_path=pwd; else, aux_save_path=save_path; end
    disp(['TACs written in ', strcat(aux_save_path,filesep,'tacs.txt')]);
    fprintf(QMf_logfile,strcat(aux_date(end-8:end),[' TACs written in ', strcat(aux_save_path,filesep,'tacs.txt')],'\n'));
catch
    error('ERROR Writing results in file');
end
CPUtime=toc(start);
disp(['Generating and writing TACs elapsed time: ', num2str(CPUtime)])
disp(['End job at ', datestr(now)])
disp('------------------------------------------------------')
fprintf(QMf_logfile,strcat(aux_date(end-8:end),[' Generating and writing TACs elapsed time: ', num2str(CPUtime)],'\n'));
fprintf(QMf_logfile,strcat(aux_date(end-7:end),[' End job at ', datestr(now)]));
fprintf(QMf_logfile,strcat('\n','----------------------------------------------','\n'));

fclose(QMf_logfile);
    
delete(h_QM);
end
