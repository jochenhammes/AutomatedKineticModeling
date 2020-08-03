function QModeling_parametric_images(studies_path,reference_path,interest_path,save_path,model,parameters,varargin)
% This function permits to generate a set of parametric images from a set
% of dynamic PET studies and their respective masks or TACs (from the interest and
% reference regions). 
% Three items are needed: 
%   1) A directory containing one folder for each subject, which should 
% contains the PET images.
%   2) A folder for the masks of interest (or interest TACs) which must contains one file 
% per study with the same name of the study folder.
%   3) A folder for the reference masks or TACs, which must contains one file 
% per study with the same name of the study folder.
% 
% NIfTI and Analyze formats are allowed for the studies and masks. If you
% have the TACs instead of masks, the allowed formats are .txt, .xls and
% .xlsx
%
% Usage: call QModeling_parametric_images function with the following input
% parameters.
%
%     - studies_path: path to a directory containing one image folder for each
%     study. The image file format allowed is NIfTI or Analyze
% 
%     - reference_path: path to a directory which contains the reference
%     masks or the TACs. (with the same name as the study folder).
% 
%     - interest_path: path to a directory which contains the masks or the TACs of the
%     region of interest (with the same name as the study folder).
%
% The number of folders at the "studies_path", the number of files at the "reference_path" and 
% the number of files at the "interest_path" must be the same
%
%     - save_path: path to a directory where the results will be saved. If
%     the path is 'd', the current directory will be used .
% 
%     - model: a string indicating the name of the selected model. It could be 'SRTM',
%     'SRTM2', 'PatlakRef' or 'LoganPlot'.
% 
%     - parameters: a vector containing the minimum information required to
%     run the selected model. For more information, please go to the online manual:
%     http://www.uimcimes.es/QModeling_help/html/
% 
%       'SRTM': [k2a_min k2a_max num_basis_functions resampling threshold]
% 
%       'SRTM2': [k2a_min k2a_max num_basis_functions resampling k2_p threshold]. If
%       you want to estimate k2_p, use the value -1. If you want to specify
%       a fixed value for k2_p, simply put it.
% 
%       'PatlakRef': [restrict_t*_min restrict_t*_max MaxError threshold].  If you want to
%       fix t*, introduce only this fixed value of t* and the threshold value: [t*_fixed threshold]
%       In other case, t* will be estimated considering the min and max restrictions. If you don't
%       want to use restrictions in the estimate of t* give the -1 value to
%       the restrict_t*_min and the restrict_t*_max parameters.
%
%       'LoganPlot': [MaxError k2' threshold restrict_t* restrict_t*_min restrict_t*_max]. 
%       There are three ways to run Logan Plot model. One option is
%       estimate t* based on the MaxError (input parameters: MaxError,
%       k2' and threshold). Another option is estimate t* between two values,
%       restrict_t*_min and restrict_t*_max, based on MaxError (input 
%       parameters: MaxError, k2', threshold, restrict_t*_min and restrict_t*_max).
%       The third option is use a fixed t* value (input parameters:
%       MaxError with a fixed value of 100, threshold, k2' and restrict_t* as the 
%       fixed t* value). 
%
%     - timesfile_path (optional): path to a .txt file containing the start and end times
%       for each frame. Default times will be loaded if this optional file is not added 
%       and the studies do not include times series.
%---------------------------------------------------------------------------------
% QModeling_parametric_images is part of QModeling.
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
% Copyright (C) 2018 Francisco Javier Lopez Gonzalez, Karl-Khader
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
    fprintf(QMf_logfile,strcat(aux_date(end-7:end),' Starting command-line function QModeling_parametric_images.m with parameters:\n'));
    fprintf(QMf_logfile,strcat(' -studies_path:',studies_path,'\n'));
    fprintf(QMf_logfile,strcat(' -reference_path:',reference_path,'\n'));
    fprintf(QMf_logfile,strcat(' -interest_path:',interest_path,'\n'));
    fprintf(QMf_logfile,strcat(' -save_path:',save_path,'\n'));
    fprintf(QMf_logfile,strcat(' -model:',model,'\n'));
    fprintf(QMf_logfile,strcat(' -parameters:',mat2str(parameters),'\n'));
    if (nargin==7), fprintf(QMf_logfile,strcat(' -time_table:',varargin{1},'\n')); end
    
    disp('------------------------------------------------------')
    disp(['Starting job at ', datestr(now)])
    disp('')

 %% Add the new model to the first check
 
    if strcmp(model,'SRTM') == 1 || strcmp(model,'SRTM2') == 1  || strcmp(model,'PatlakRef') == 1 || strcmp(model,'LoganPlot')==1
        % || strcmp(model,'newModel_Name')==1
        disp(['Selected model: ', model]);
        fprintf(QMf_logfile,strcat([' Selected model: ', model],'\n'));
    else
        fprintf(QMf_logfile,strcat('  ERROR: Non existing model. Please, type one of this: SRTM, SRTM2, PatlakRef, LoganPlot','\n'));
        error('ERROR Non existing model. Please, type one of this: SRTM, SRTM2, PatlakRef, LoganPlot');
    end
    
%     else
%         fprintf(QMf_logfile,strcat('  ERROR: Non existing model. Please, type one of this: SRTM, SRTM2, PatlakRef, newModel_Name','\n'));
%         error('ERROR Non existing model. Please, type one of this: SRTM, SRTM2, PatlakRef, newModel_Name');
%     end
%%  

    studies_folder=dir(studies_path);   
    studies_folder=studies_folder(3:end,:); 
    num_studies=length(studies_folder);
    disp([num2str(num_studies),' studies to generate parametric images']);
    fprintf(QMf_logfile,strcat([num2str(num_studies),' studies to generate parametric images'],'\n'));
    multiframe=false;
    no_times=(nargin==6);
    
    reference_tac=cell(num_studies,1);
    interest_tac=cell(num_studies,1);
    
    
    for j=1:num_studies        
        study_name=studies_folder(j).name;        
        disp(['Study: ',study_name]);
        fprintf(QMf_logfile,strcat([' Study: ',study_name],'\n'));
        disp(' -Generating TACs...')
        fprintf(QMf_logfile,strcat('  -Generating TACs...','\n'));
        start=tic;
        
        path_study_folder=strcat(studies_path,filesep,study_name,filesep);
        images=dir(strcat(path_study_folder,'*.img')); % trying to load Analyze format 

        if isempty(images)
            images=dir(strcat(path_study_folder,'*.nii')); % trying to load NIfTI format
        end

        if isempty(images) % the format file of the study is not Analyz nor NIfTI
            msgError=strcat(['  ERROR: Input study ', study_name, ' does not have the expected format (.nii or .hdr/.img).']);
            fprintf(QMf_logfile,strcat(msgError,'\n'));
            error(msgError);

        else
            num_files=length(images);
            if num_files==1 % is a multiframe study
               image_hdr=spm_vol(strcat(path_study_folder,images.name));
               num_files=length(image_hdr);
               dim=prod(image_hdr(1).dim);
               multiframe=true;
               Vtemp=image_hdr(num_files);%we need it to create the parametric images
            else
               image_hdr=spm_vol(strcat(path_study_folder,images(1).name));
               dim=prod(image_hdr.dim);
               multiframe=false;
               Vtemp=image_hdr;%we need it to create the parametric images
            end
        end
        
        reference_tac{j}=zeros(1,num_files);
        interest_tac{j}=zeros(1,num_files);
        Cpet=zeros(num_files,dim);
        ref_from_file=true;
        int_from_file=true;
        
        try % trying to load reference mask
            path_reference_file=spm_select('ExtFPList',reference_path,strcat(study_name,'.nii|',study_name,'.img'));
            if ~isempty(path_reference_file)             
                reference_hdr=spm_vol(path_reference_file);
                reference_mask=spm_read_vols(reference_hdr);
                id_ref=unique(reference_mask);
                id_ref=id_ref(2:end);
                ref_from_file=false;
            else
                try
                    reference_tac{j}=importdata(strcat(reference_path,filesep,study_name,'.txt')); 
                    
                catch
                    try
                        [reference_tac{j}, ~, ~]=xlsread(strcat(reference_path,filesep,study_name,'.xls'));
                        
                    catch
                        try
                            [reference_tac{j}, ~, ~]=xlsread(strcat(reference_path,filesep,study_name,'.xlsx'));
                            
                        catch
                            fprintf(QMf_logfile,strcat(['  ERROR: Opening reference TAC of ', study_name,' (.txt, .xls o .xlsx format)'],'\n'));
                            error(['ERROR Opening reference TAC of ', study_name,' (.txt, .xls o .xlsx format)']);
                        end
                    end
                end
            end

        catch 
            fprintf(QMf_logfile,strcat(['  ERROR: Opening reference mask region of ', study_name,' (NIfTI or Analyze format)'],'\n'));
            error(['ERROR Opening reference mask region of ', study_name,' (NIfTI or Analyze format)']);
%             error(['ERROR Opening reference mask region of ', study_name,'. Pay attention to the format file (NIfTI and Analyze format are accepted)']);
        end

        try % trying to load interest mask
            path_interest_file=spm_select('ExtFPList',interest_path,strcat(study_name,'.nii|',study_name,'.img'));
            if ~isempty(path_interest_file)
                interest_hdr=spm_vol(path_interest_file);
                interest_mask=spm_read_vols(interest_hdr);
                id_int=unique(interest_mask);
                id_int=id_int(2:end);
                int_from_file=false;
            else                
                try
                    interest_tac{j}=importdata(strcat(interest_path,filesep,study_name,'.txt'));                    
                catch
                    try
                        [interest_tac{j}, ~, ~]=xlsread(strcat(interest_path,filesep,study_name,'.xls'));
                    catch
                        try
                            [interest_tac{j}, ~, ~]=xlsread(strcat(interest_path,filesep,study_name,'.xlsx'));
                        catch
                            fprintf(QMf_logfile,strcat(['  ERROR: Opening target TAC of ', study_name,' (.txt, .xls o .xlsx format)'],'\n'));
                            error(['ERROR Opening target TAC of ', study_name,' (.txt, .xls o .xlsx format)']);
                        end
                    end
                end
            end
        catch 
            fprintf(QMf_logfile,strcat(['  ERROR: Opening interest mask region of ', study_name,' (NIfTI or Analyze format)'],'\n'));
            error(['ERROR Opening interest mask region of ',study_name,' (NIfTI or Analyze format)']);
        end
    
        
        times=zeros(num_files,2);
        for frame=1:num_files
            if multiframe
                current_im=spm_read_vols(image_hdr(frame));                
            else
                image_hdr=spm_vol(strcat(path_study_folder,images(frame).name));
                current_im= spm_read_vols(image_hdr);
            end
            
            Cpet(frame,:) = current_im(:);
            
            if ~ref_from_file
                reference_tac{j}(frame)=mean(current_im(reference_mask==id_ref));
            end
            if ~int_from_file
                interest_tac{j}(frame)=mean(current_im(interest_mask==id_int));
            end
            
            if (no_times)
                try
                    times(frame,1) = image_hdr(frame).private.timing.toffset;
                    times(frame,2) = times(frame,1) + image_hdr(frame).private.timing.tspace;  
                    if (frame==num_files)
                        no_times=false;
                    end
                catch
                    if (no_times)
                        fprintf(QMf_logfile,strcat('  ERROR: Reading the PET times. Loading default times','\n'));
                        actualpath=mfilename('fullpath');
                        [path, ~, ~]=fileparts(actualpath);
                        aux = load(strcat(fileparts(path),filesep,'TimeTable.txt'));
                        times = aux(1:num_files,:);
                    end
                end
            end
        end

        
        if (nargin==7) && ~(no_times)
            aux = load(varargin{1});
            times = aux(1:num_files,:);
        end
        
        CPUtime=toc(start);
        
        disp(['TACs generated. ', 'Elapsed time: ',num2str(CPUtime)]);
        fprintf(QMf_logfile,strcat(['   TACs generated. ', 'Elapsed time: ',num2str(CPUtime)],'\n'));
        
        disp(' -Generating parametric images...')
        fprintf(QMf_logfile,strcat('  -Generating parametric images...','\n'));
        
        Cr=reference_tac{j}';
        Ct=interest_tac{j}'; 
        
        if strcmp(model,'SRTM') == 1 
            
            disp('Model selected: SRTM')

            if length(parameters) ~= 5
                fprintf(QMf_logfile,strcat('  ERROR: There is not enough parameters (5)','\n'));
                error('There is not enough parameters (5)');
            else
                k2a_min = parameters(1); 
                if isnan(k2a_min) || (k2a_min < 0)
                    fprintf(QMf_logfile,strcat('  ERROR: k2a min must be a positive number','\n'));
                    error('k2a min must be a positive number');
                end

                k2a_max = parameters(2); 
                if isnan(k2a_max) || (k2a_max < 0)
                    fprintf(QMf_logfile,strcat('  ERROR: k2a max must be a positive number','\n'));
                    error('k2a max must be a positive number');
                end

                if k2a_max < k2a_min
                    fprintf(QMf_logfile,strcat('  ERROR: k2a max must be bigger than k2a min','\n'));
                    error('k2a max must be bigger than k2a min');
                end

                num_BF = parameters(3); 
                if isnan(num_BF) || (num_BF < 1)
                    fprintf(QMf_logfile,strcat('  ERROR: The number of basis functions must be a positive integer','\n'));
                    error('The number of basis functions must be a positive integer');
                end

                resampling = parameters(4); 
                if isnan(resampling) || (resampling < 0)
                    fprintf(QMf_logfile,strcat('  ERROR: Resampling must be a positive number','\n'));
                    error('Resampling must be a positive number');
                end
                
                threshold = parameters(5); 
                if isnan(threshold) || (threshold < 0)
                    fprintf(QMf_logfile,strcat('  ERROR: Threshold must be a positive number','\n'));
                    error('Threshold must be a positive number');
                end
            end           

           
            start=tic;
            images = QModeling_SRTM(Ct,Cr,times,k2a_min,k2a_max,num_BF,resampling,Cpet);
            CPUtime=toc(start);
            disp(['Parametric images generated. Elapsed time: ', num2str(CPUtime)])
            fprintf(QMf_logfile,strcat(['   Parametric images generated. Elapsed time: ', num2str(CPUtime)],'\n'));
            
            disp(' -Writing parametric images...');
            fprintf(QMf_logfile,strcat('  -Writing parametric images...','\n'));
            
            % Calculate cut
            energy = diff(times,1,2)'*(Cpet.^2);
            cutoff = max(energy)*(threshold/100);
            indcut = find(energy < cutoff);

            %Perform the cut
            BPnd=images(1,:);
            BPnd(indcut)=0;

            k2=images(2,:);
            k2(indcut)=0;

            k2a=images(3,:);
            k2a(indcut)=0;

            R1=images(4,:);
            R1(indcut)=0;

           
            VBPnd = struct('fname','BPnd_image.nii','dim',Vtemp.dim,'mat',Vtemp.mat,...
                    'dt',[spm_type('float64') spm_platform('bigend')],'n',[1 1]);

            %Create BPnd image
            aux = zeros(VBPnd.dim);
            aux(:) = BPnd(:);
            try
                if strcmp(save_path,'d') %default directory->we save at the current directory
                    VBPnd.fname=strcat(study_name,'_SRTM_BPnd_image.nii');
                else 
                    VBPnd.fname=strcat(save_path,filesep,study_name,'_SRTM_BPnd_image.nii');
                end
                spm_write_vol(VBPnd,aux);
            catch
                fprintf(QMf_logfile,strcat('  ERROR: Writing BPnd image in file','\n'));
                error('ERROR Writing BPnd image in file');
            end
       
            Vk2 = struct('fname','k2_image.nii','dim',Vtemp.dim,'mat',Vtemp.mat,...
                    'dt',[spm_type('float64') spm_platform('bigend')],'n',[1 1]);

            %Create k2 image
            aux = zeros(Vk2.dim);
            aux(:) = k2(:);
            try
                if strcmp(save_path,'d')
                    Vk2.fname = strcat(study_name,'_SRTM_k2_image.nii');
                else
                    Vk2.fname = strcat(save_path,filesep,study_name,'_SRTM_k2_image.nii');
                end
                spm_write_vol(Vk2,aux);
            catch
                fprintf(QMf_logfile,strcat('  ERROR: Writing k2 image in file','\n'));
                error('ERROR Writing k2 image in file');
            end
                 

            VR1 = struct('fname','R1_image.nii','dim',Vtemp.dim,'mat',Vtemp.mat,...
                    'dt',[spm_type('float64') spm_platform('bigend')],'n',[1 1]);

            %Create R1 image
            aux = zeros(VR1.dim);
            aux(:) = R1(:);
            
            try
                if strcmp(save_path,'d')
                    VR1.fname = strcat(study_name,'_SRTM_R1_image.nii');
                else
                    VR1.fname = strcat(save_path,filesep,study_name,'_SRTM_R1_image.nii');
                end
                spm_write_vol(VR1,aux);
            catch
                fprintf(QMf_logfile,strcat('  ERROR: Writing R1 image in file','\n'));
                error('ERROR Writing R1 image in file');
            end
 


            Vk2a = struct('fname','k2a_image.nii','dim',Vtemp.dim,'mat',Vtemp.mat,...
                    'dt',[spm_type('float64') spm_platform('bigend')],'n',[1 1]);

            %Create k2a image
            aux = zeros(Vk2a.dim);
            aux(:) = k2a(:);
            
            try
                if strcmp(save_path,'d')
                    Vk2a.fname = strcat(study_name,'_SRTM_k2a_image.nii');
                else
                    Vk2a.fname = strcat(save_path,filesep,study_name,'_SRTM_k2a_image.nii');
                end
                spm_write_vol(Vk2a,aux);  %Save image in hard disk
            catch
                fprintf(QMf_logfile,strcat('  ERROR: Writing k2a image in file','\n'));
                error('ERROR Writing k2a image in file');
            end

            
            
        elseif strcmp(model,'SRTM2') == 1

            disp('Model selected: SRTM2')

            if length(parameters) ~= 6
                fprintf(QMf_logfile,strcat('  ERROR: There is not enough parameters (6)','\n'));
                error('There is not enough parameters (6)');
            else
                k2a_min = parameters(1); 
                if isnan(k2a_min) || (k2a_min < 0)
                    fprintf(QMf_logfile,strcat('  ERROR: k2a min must be a positive number','\n'));
                    error('k2a min must be a positive number');
                end

                k2a_max = parameters(2); 
                if isnan(k2a_max) || (k2a_max < 0)
                    fprintf(QMf_logfile,strcat('  ERROR: k2a max must be a positive number','\n'));
                    error('k2a max must be a positive number');
                end

                if k2a_max < k2a_min
                    fprintf(QMf_logfile,strcat('  ERROR: k2a max must be bigger than k2a min','\n'));
                    error('k2a max must be bigger than k2a min');
                end

                num_BF = parameters(3); 
                if isnan(num_BF) || (num_BF < 1)
                    fprintf(QMf_logfile,strcat('  ERROR: The number of basis functions must be a positive integer','\n'));
                    error('The number of basis functions must be a positive integer');
                end

                resampling = parameters(4); 
                if isnan(resampling) || (resampling < 0)
                    fprintf(QMf_logfile,strcat('  ERROR: Resampling must be a positive number','\n'));
                    error('Resampling must be a positive number');
                end

                k2_p = parameters(5);
                if isnan(k2_p) || ((k2_p < 0) && (k2_p ~= -1))
                    fprintf(QMf_logfile,strcat(strcat('  ERROR: k2',char(39),' must be a positive number or -1'),'\n'));
                    error(strcat('k2',char(39),' must be a positive number or -1'));
                end
                
                threshold = parameters(6);
                if isnan(threshold) || (threshold < 0)
                    fprintf(QMf_logfile,strcat('  ERROR: Threshold must be a positive number','\n'));
                    error('Threshold must be a positive number');
                end

            end
            
            start=tic;
            images = QModeling_SRTM2(Ct,Cr,times,k2_p,k2a_min,k2a_max,num_BF,resampling,Cpet);
            CPUtime=toc(start);
            
            disp(['Parametric images generated. Elapsed time: ', num2str(CPUtime)])
            fprintf(QMf_logfile,strcat(['   Parametric images generated. Elapsed time: ', num2str(CPUtime)],'\n'));
            
            disp(' -Writing parametric images...');
            fprintf(QMf_logfile,strcat('  -Writing parametric images...','\n'));
            
            % Calculate cut
            energy = diff(times,1,2)'*(Cpet.^2);
            cutoff = max(energy)*(threshold/100);
            indcut = find(energy < cutoff);

            %Perform the cut
            BPnd=images(1,:);
            BPnd(indcut)=0;

            k2=images(2,:);
            k2(indcut)=0;

            k2a=images(3,:);
            k2a(indcut)=0;

            R1=images(4,:);
            R1(indcut)=0;
                       
          
            VBPnd = struct('fname','BPnd_image.nii','dim',Vtemp.dim,'mat',Vtemp.mat,...
                    'dt',[spm_type('float64') spm_platform('bigend')],'n',[1 1]);

            %Create BPnd image
            aux = zeros(VBPnd.dim);
            aux(:) = BPnd(:);
            try
                if strcmp(save_path,'d')
                    VBPnd.fname=strcat(study_name,'_SRTM2_BPnd_image.nii');
                else
                    VBPnd.fname=strcat(save_path,filesep,study_name,'_SRTM2_BPnd_image.nii');
                end
                spm_write_vol(VBPnd,aux);
            catch
                fprintf(QMf_logfile,strcat('  ERROR: Writing BPnd image in file','\n'));
                error('ERROR Writing BPnd image in file');
            end
       
            Vk2 = struct('fname','k2_image.nii','dim',Vtemp.dim,'mat',Vtemp.mat,...
                    'dt',[spm_type('float64') spm_platform('bigend')],'n',[1 1]);

            %Create k2 image
            aux = zeros(Vk2.dim);
            aux(:) = k2(:);
            try
                if strcmp(save_path,'d')
                    Vk2.fname = strcat(study_name,'_SRTM2_k2_image.nii');
                else
                    Vk2.fname = strcat(save_path,filesep,study_name,'_SRTM2_k2_image.nii');
                end
                spm_write_vol(Vk2,aux);
            catch
                fprintf(QMf_logfile,strcat('  ERROR: Writing k2 image in file','\n'));
                error('ERROR Writing k2 image in file');
            end
                 

            VR1 = struct('fname','R1_image.nii','dim',Vtemp.dim,'mat',Vtemp.mat,...
                    'dt',[spm_type('float64') spm_platform('bigend')],'n',[1 1]);

            %Create R1 image
            aux = zeros(VR1.dim);
            aux(:) = R1(:);
            
            try
                if strcmp(save_path,'d')
                    VR1.fname = strcat(study_name,'_SRTM2_R1_image.nii');
                else
                    VR1.fname = strcat(save_path,filesep,study_name,'_SRTM2_R1_image.nii');
                end
                spm_write_vol(VR1,aux);
            catch
                fprintf(QMf_logfile,strcat('  ERROR: Writing R1 image in file','\n'));
                error('ERROR Writing R1 image in file');
            end
 
            Vk2a = struct('fname','k2a_image.nii','dim',Vtemp.dim,'mat',Vtemp.mat,...
                    'dt',[spm_type('float64') spm_platform('bigend')],'n',[1 1]);

            %Create k2a image
            aux = zeros(Vk2a.dim);
            aux(:) = k2a(:);
            
            try
                if strcmp(save_path,'d')
                    Vk2a.fname = strcat(study_name,'_SRTM2_k2a_image.nii');
                else
                    Vk2a.fname = strcat(save_path,filesep,study_name,'_SRTM2_k2a_image.nii');
                end
                spm_write_vol(Vk2a,aux);  %Save image in hard disk
            catch
                fprintf(QMf_logfile,strcat('  ERROR: Writing k2a image in file','\n'));
                error('ERROR Writing k2a image in file');
            end
         
                                    
        elseif strcmp(model,'PatlakRef') == 1

            disp('Model selected: PatlakRef')

            num_param = length(parameters);
            if num_param ~= 2 && num_param ~= 4
                fprintf(QMf_logfile,strcat('  ERROR: There is not enough parameters (2 or 4)','\n'));
                error('There is not enough parameters (2 or 4)');
            else

                if num_param == 2

                    tfit = parameters(1);
                    if isnan(tfit) || (tfit < 0)
                        fprintf(QMf_logfile,strcat('  ERROR: t* must be a positive number','\n'));
                        error('t* must be a positive number');
                    end

                    threshold = parameters(2); %3;
                    if isnan(threshold) || (threshold < 0)
                        fprintf(QMf_logfile,strcat('  ERROR: Threshold must be a positive number','\n'));
                        error('Threshold must be a positive number');
                    end
                    
             
                      start=tic;
                      images = QModeling_PatlakRef(Ct,Cr,times,1,tfit,Cpet); 
                      CPUtime=toc(start);
                      disp(['Parametric images generated. Elapsed time: ', num2str(CPUtime)]); 
                      fprintf(QMf_logfile,strcat(['   Parametric images generated. Elapsed time: ', num2str(CPUtime)],'\n'));
                      disp(' -Writing parametric images...');
                      fprintf(QMf_logfile,strcat('  -Writing parametric images...','\n'));
                else

                    minR = parameters(1);
                    if isnan(minR)
                        fprintf(QMf_logfile,strcat('  ERROR: Lower restriction must be a positive number or -1','\n'));
                        error('Lower restrict must be a positive number or -1');
                    end

                    maxR = parameters(2);
                    if isnan(maxR)
                        fprintf(QMf_logfile,strcat('  ERROR: Upper restriction must be a positive number or -1','\n'));
                        error('Upper restrict must be a positive number or -1');
                    end

                    if minR > maxR
                        fprintf(QMf_logfile,strcat('  ERROR: Upper restriction must be bigger than Lower restriction','\n'));
                        error('Upper restrict must be bigger than Lower restrict');
                    end

                    Max_err = parameters(3);
                    if isnan(Max_err)
                        fprintf(QMf_logfile,strcat('  ERROR: MaxErr must be a positive number','\n'));
                        error('MaxErr must be a positive number');
                    end
                    
                    threshold = parameters(4); %3;
                    if isnan(threshold) || (threshold < 0)
                        fprintf(QMf_logfile,strcat('  ERROR: Threshold must be a positive number','\n'));
                        error('Threshold must be a positive number');
                    end

                    if (minR == -1) || (maxR == -1)
                        useR = 0;
                    else
                        useR = 1;
                    end

                    
                    start=tic;
                    images = QModeling_PatlakRef(Ct,Cr,times,1,[useR minR maxR],Max_err,Cpet);
                    CPUtime=toc(start);
                    disp(['Parametric images generated. Elapsed time: ', num2str(CPUtime)]);
                    fprintf(QMf_logfile,strcat(['   Parametric images generated. Elapsed time: ', num2str(CPUtime)],'\n'));
                    disp(' -Writing parametric images...');
                    fprintf(QMf_logfile,strcat('  -Writing parametric images...','\n'));
                end

            end

            energy = diff(times,1,2)'*(Cpet.^2);
            cutoff = max(energy)*(threshold/100);
            
            images(1,energy < cutoff) = 0;
            images(2,energy < cutoff) = 0;


            VK = struct('fname','K_image.nii','dim',Vtemp.dim,'mat',Vtemp.mat,...
                            'dt',[spm_type('float64') spm_platform('bigend')],'n',[1 1]);

            % Make image
            val = zeros(VK.dim);
            val(:) = images(1,:)*60;


            try
                if strcmp(save_path,'d')
                    VK.fname = strcat(study_name,'_PatlakRef_K_image.nii');
                else
                    VK.fname = strcat(save_path,filesep,study_name,'_PatlakRef_K_image.nii');
                end
                spm_write_vol(VK,val);
            catch
                fprintf(QMf_logfile,strcat('  ERROR: Writing K image in file','\n'));
                error('ERROR Writing K image in file'); 
            end



            VI = struct('fname','intercept_image.nii','dim',Vtemp.dim,'mat',Vtemp.mat,...
                        'dt',[spm_type('float64') spm_platform('bigend')],'n',[1 1]);

            % Make image
            val = zeros(VI.dim);
            val(:) = images(2,:);

            try
                if strcmp(save_path,'d')
                    VI.fname = strcat(study_name,'_PatlakRef_intercept_image.nii');
                else
                    VI.fname = strcat(save_path,filesep,study_name,'_PatlakRef_intercept_image.nii');
                end
                spm_write_vol(VI,val);
            catch
                fprintf(QMf_logfile,strcat('  ERROR: Writing intercept image in file','\n'));
                error('ERROR Writing intercept image in file');
            end
            
        elseif strcmp(model,'LoganPlot') == 1

            disp('Model selected: LoganPlot')

            num_param = length(parameters);
            if num_param ~= 3 && num_param ~= 4 && num_param ~=5
                fprintf(QMf_logfile,strcat('  ERROR: There is not enough parameters (3, 4 or 5)','\n'));
                error('There is not enough parameters (3, 4 or 5)');
            else
                maxError=parameters(1);
                if isnan(maxError) || (maxError < 0) || (maxError > 100)
                    fprintf(QMf_logfile,strcat('  ERROR: Max Error must be a positive number beteween 0 and 100','\n'));
                    error('Max Error must be a positive number beteween 0 and 100');
                end
                k2_p=parameters(2);
                if isnan(k2_p) || (k2_p < 0)
                    fprintf(QMf_logfile,strcat('  ERROR: k2',char(39),' must be a positive number','\n'));
                    error(strcat('k2',char(39),' must be a positive number'));
                end
                k2_p=k2_p/60;
                threshold = parameters(3);
                if isnan(threshold) || (threshold < 0)
                    fprintf(QMf_logfile,strcat('  ERROR: Threshold must be a positive number','\n'));
                    error('Threshold must be a positive number');
                end
                
                if num_param == 3   
                      start=tic;
                      images = QModeling_LoganPlot(Ct,Cr,times,k2_p,maxError,1,Cpet); 
                      CPUtime=toc(start);
                      disp(['Parametric images generated. Elapsed time: ', num2str(CPUtime)]); 
                      fprintf(QMf_logfile,strcat(['   Parametric images generated. Elapsed time: ', num2str(CPUtime)],'\n'));
                      disp(' -Writing parametric images...');
                      fprintf(QMf_logfile,strcat('  -Writing parametric images...','\n'));
                      
                elseif num_param == 4
                    
                    t_star=parameters(4);
                    if isnan(t_star) || (t_star < 0)
                        fprintf(QMf_logfile,strcat('  ERROR: The restriction time must be a positive number','\n'));
                        error(strcat('The restriction time must be a positive number'));
                    end
                    
                    
                    start=tic;
                    images = QModeling_LoganPlot(Ct,Cr,times,k2_p,maxError,1,Cpet,t_star);
                    CPUtime=toc(start);
                    disp(['Parametric images generated. Elapsed time: ', num2str(CPUtime)]);
                    fprintf(QMf_logfile,strcat(['   Parametric images generated. Elapsed time: ', num2str(CPUtime)],'\n'));
                    disp(' -Writing parametric images...');
                    fprintf(QMf_logfile,strcat('  -Writing parametric images...','\n'));
                
                
                else
                   min_t_star=parameters(4);
                   max_t_star=parameters(5);
                   if isnan(min_t_star) || (min_t_star < 0)
                        fprintf(QMf_logfile,strcat('  ERROR: Lower restriction of t* must be a positive number','\n'));
                        error(strcat('Lower restrict of t* must be a positive number'));
                   end
                   if isnan(max_t_star) || (max_t_star < 0)
                        fprintf(QMf_logfile,strcat('  ERROR: Upper restriction of t* must be a positive number','\n'));
                        error(strcat('Upper restriction of t* must be a positive number'));
                   end

                   if min_t_star > max_t_star
                        fprintf(QMf_logfile,strcat('  ERROR: the upper restriction of t* must be bigger than the lower restriction','\n'));
                        error(strcat('The upper restriction of t* must be bigger than the lower restriction'));
                   end
                   
                   start=tic;
                   images = QModeling_LoganPlot(Ct,Cr,times,k2_p,maxError,1,Cpet,min_t_star,max_t_star);
                   CPUtime=toc(start);
                   disp(['Parametric images generated. Elapsed time: ', num2str(CPUtime)]);
                   fprintf(QMf_logfile,strcat(['   Parametric images generated. Elapsed time: ', num2str(CPUtime)],'\n'));
                   disp(' -Writing parametric images...');
                   fprintf(QMf_logfile,strcat('  -Writing parametric images...','\n'));
                end
            end

            energy = diff(times,1,2)'*(Cpet.^2);
            cutoff = max(energy)*(threshold/100);
            
            images(1,energy < cutoff) = 0;
            images(2,energy < cutoff) = 0;


            VBPnd = struct('fname','BPnd_image.nii','dim',Vtemp.dim,'mat',Vtemp.mat,...
                            'dt',[spm_type('float64') spm_platform('bigend')],'n',[1 1]);

            % Make image
            val = zeros(VBPnd.dim);
            val(:) = images(1,:);


            try
                if strcmp(save_path,'d')
                    VBPnd.fname = strcat(study_name,'_LoganPlot_BPnd_image.nii');
                else
                    VBPnd.fname = strcat(save_path,filesep,study_name,'_LoganPlot_BPnd_image.nii');
                end
                spm_write_vol(VBPnd,val);
            catch
                fprintf(QMf_logfile,strcat('  ERROR: Writing BPnd image in file','\n'));
                error('ERROR Writing BPnd image in file'); 
            end



            VI = struct('fname','intercept_image.nii','dim',Vtemp.dim,'mat',Vtemp.mat,...
                        'dt',[spm_type('float64') spm_platform('bigend')],'n',[1 1]);

            % Make image
            val = zeros(VI.dim);
            val(:) = images(2,:);

            try
                if strcmp(save_path,'d')
                    VI.fname = strcat(study_name,'_LoganPlot_intercept_image.nii');
                else
                    VI.fname = strcat(save_path,filesep,study_name,'_LoganPlot_intercept_image.nii');
                end
                spm_write_vol(VI,val);
            catch
                fprintf(QMf_logfile,strcat('  ERROR: Writing intercept image in file','\n'));
                error('ERROR Writing intercept image in file');
            end
%%   Add a new case to the if command in order to add the new model    
%         elseif strcmp(model,'newModel_Name') == 1 
%             
%             disp('Model selected: newModel_Name')
% 
%% Optional: Check the number and the values of the input parameters
% [...]     Errors must be written in the logfile:
%           fprintf(QMf_logfile,strcat('  ERROR: error message','\n'));
%
%% Run the script of the new model to obtain the parametric images            
%             start=tic;
%             images = QModeling_newModel_Name(Ct,Cr,times,1st_input_parameter,2nd_input_parameter,...,Cpet);
%             CPUtime=toc(start);
%             disp(['Parametric images generated. Elapsed time: ', num2str(CPUtime)])
%             fprintf(QMf_logfile,strcat(['   Parametric images generated. Elapsed time: ', num2str(CPUtime)],'\n'));
%             
%             disp(' -Writing parametric images...');
%             fprintf(QMf_logfile,strcat('  -Writing parametric images...','\n'));
%             
%% Optional: Apply a "cut" to the generated images matrices
%             energy = diff(times,1,2)'*(Cpet.^2);
%             cutoff = max(energy)*(threshold/100);
%             indcut = find(energy < cutoff);
% 
%             1st_parametric_image=images(1,:);
%             1st_parametric_image(indcut)=0;
% 
%             2nd_parametric_image=images(2,:);
%             2nd_parametric_image(indcut)=0;
%             
%             [...]
%                          
%% Create and save the parametric images
%            
%             V_1st_parametric_image_name = struct('fname','1st_parametric_image_name.nii','dim',Vtemp.dim,'mat',Vtemp.mat,...
%                     'dt',[spm_type('float64') spm_platform('bigend')],'n',[1 1]);
% 
%             %Create 1st_parametric_image
%             aux = zeros(V_1st_parametric_image_name.dim);
%             aux(:) = 1st_parametric_image_name(:);
%             try
%                 if strcmp(save_path,'d') %default directory->we save at the current directory
%                     V_1st_parametric_image_name.fname=strcat(study_name,'_newModel_Name__1st_parametric_image_name.nii');
%                 else 
%                     V_1st_parametric_image_name.fname=strcat(save_path,filesep,study_name,'_newModel_Name__1st_parametric_image_name.nii');
%                 end
%                 spm_write_vol(V_1st_parametric_image,aux);
%             catch
%                 fprintf(QMf_logfile,strcat('  ERROR: Writing 1st_parametric_image_name image in file','\n'));
%                 error('ERROR Writing 1st_parametric_image_name image in file');
%             end
%        
%             V_2nd_parametric_image_name = struct('fname','2nd_parametric_image_name.nii','dim',Vtemp.dim,'mat',Vtemp.mat,...
%                     'dt',[spm_type('float64') spm_platform('bigend')],'n',[1 1]);
%
%         [...]
%
%             %Create the others parametric_images       
%                  
%         [...]
% 
%             
       end        
    end

    if strcmp(save_path,'d'), aux_save_path=pwd; else, aux_save_path=save_path; end
    disp(['Parametric images written in ', strcat(aux_save_path,filesep)]);
    fprintf(QMf_logfile,strcat(aux_date(end-8:end),['Parametric images written in ', strcat(aux_save_path,filesep)],'\n'));
    
    disp(['End job at ', datestr(now)])
    disp('------------------------------------------------------')
    
    fprintf(QMf_logfile,strcat(aux_date(end-7:end),[' End job at ', datestr(now)]));
    fprintf(QMf_logfile,strcat('\n','----------------------------------------------','\n'));
    
    fclose(QMf_logfile);

delete(h_QM);
end

