function autoQModelingCGN()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to run a _demo_ of the command line of QModeling.
%
% At _/QModeling/command_line/demo_ there are four neccesary folders to run
% this demo script:
% 
% -/studies: A folder to the PET studies. You could put here all the studies
% you want to fit. As an example, one study called "study_0" has been
% added.
% -/reference_masks: This folder have to contain the reference masks or TACs of the
% studies which are at the studies folder. The name of this files must be
% the same as the correspond studies.
% -/interest_masks: This folder have to contain the interest masks or TACs of the
% studies which are at the studies folder. The name of this files must be
% the same as the correspond studies.
% -/results: A folder where the results will be saved.
%
% Also, a defautl time table, _TimeTable.txt_ has been included at /QModeling/command_line in
% order to use it in the case the studies do not have frame times.
%
% Once you have run this function (typing demoQModeling at your command
% line window) all the steps executed will be displayed to you.

% Some comments at the code have been included to help you to
% understand each step. And to guide you in the case you would like to change some
% parameters, to add new studies,...
% --------------------------------------------------------------------------
% demoQModeling is part of QModeling.
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
% Copyright (C) 2018 Francisco Javier López González

actualpath=mfilename('fullpath'); 
[path, ~, ~]=fileparts(actualpath);
demo=strcat(path,filesep,'demo',filesep);

% you can change these paths to your own ones
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
studies_path=strcat(demo,'studies');
reference_path=strcat(demo,'reference_masks');
interest_path=strcat(demo,'interest_masks');
results_path=strcat(demo,'results');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%times=strcat(fileparts(path),filesep,'TimeTable.txt');
times=strcat(path, filesep, 'TimeTable.txt');

%% STEP 1: TACs generation
disp('STEP 1: TACs generation');
% from the studies and the reference and interest masks, the following function will
% return the TACs in a .txt called "tacs"
QModeling_generateTACs(studies_path,reference_path,interest_path,results_path,times);
 TACsfile=strcat(demo,'results',filesep,'tacs.txt');

disp('TACs generation done. Press any key to continue');
pause();

%% STEP 2: Preprocessing reference model
disp('STEP 2: Preprocessing SRTM');
model='SRTM';
% default input parameters to SRTM. You can change them trying to get a better fit of the TAC:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
k2a_min=0.006;
k2a_max=0.6;
num_basis_functions=100;
resampling=5.0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parameters=[k2a_min k2a_max num_basis_functions resampling];
% The following function adjust the model to the interest region
QModeling_preprocessTACs(TACsfile,times,results_path,model,parameters);

disp('Preprocessing SRTM method done. Press any key to continue');
pause();

disp('STEP 2: Preprocessing SRTM2');
model='SRTM2';
% input parameters to SRTM2. You can change them trying to get a better fit of the TAC:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
k2a_min=0.006;
k2a_max=0.6;
num_basis_functions=100;
resampling=5.0;
k2_p=0.128205;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parameters=[k2a_min k2a_max num_basis_functions resampling k2_p]; % giving a specific value for k2_p
% parameters=[k2a_min k2a_max num_basis_functions resampling -1]; %if you
% want to estimate and fix the k2_p value instead of directly giving a
% value for it.

% The following function adjust the model to the interest region
QModeling_preprocessTACs(TACsfile,times,results_path,model,parameters);
disp('Preprocessing SRTM2 method done. Press any key to continue');
pause();

disp('STEP 2: Preprocessing PatlakRef');
model='PatlakRef';
% input parameters to Patlak Ref. You can change them trying to get a better fit of the TAC:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
restrict_t_min=0;
restrict_t_max=60;
MaxError=10;
% fixed_t=40;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parameters=[restrict_t_min restrict_t_max MaxError];
% parameters=[-1 -1 MaxError]; If you do not want to use restrictions in the estimate of t* 
% parameters=fixed_t; if you want to use a fixed value of t*.

% The following function adjust the model to the interest region
QModeling_preprocessTACs(TACsfile,times,results_path,model,parameters);

disp('Preprocessing Patlak Ref method done. Press any key to continue');
pause();
%% STEP 3: Parametric images
disp('STEP 3: Parametric images (SRTM)');
model='SRTM';
% input parameters to SRTM. You can change them trying to get better results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
k2a_min=0.006;
k2a_max=0.6;
num_basis_functions=100;
resampling=0.5;
threshold=3;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parameters=[k2a_min k2a_max num_basis_functions resampling threshold];
% The following function generate a set of parametric images fitting the
% SRTM method at the voxel level
QModeling_parametric_images(studies_path,reference_path,interest_path,results_path,model,parameters,times)

disp('Parametric images for SRTM method generated. Press any key to continue');
pause();

disp('STEP 3: Parametric images (SRTM2)');
model='SRTM2';
% input parameters to SRTM2. You can change them trying to get a better fit of the TAC:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
k2a_min=0.006;
k2a_max=0.6;
num_basis_functions=100;
resampling=0.5;
k2_p=0.128205;
threshold=3;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parameters=[k2a_min k2a_max num_basis_functions resampling k2_p threshold];
% parameters=[k2a_min k2a_max num_basis_functions resampling -1 threshold]; %if you
% want to estimate and fix the k2_p value instead of directly giving a
% value for it.

% The following function generate a set of parametric images fitting the
% SRTM2 method at the voxel level
QModeling_parametric_images(studies_path,reference_path,interest_path,results_path,model,parameters,times)

disp('Parametric images for SRTM2 method generated. Press any key to continue');
pause();

disp('STEP 3: Parametric images (PatlakRef)');
model='PatlakRef';
% input parameters to Patlak Ref. You can change them trying to get a better fit of the TAC:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
restrict_t_min=0;
restrict_t_max=60;
MaxError=10;
threshold=3;
% fixed_t=40;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parameters=[restrict_t_min restrict_t_max MaxError threshold];
% parameters=[-1 -1 MaxError threshold]; If you do not want to use restrictions in the estimate of t* 
% parameters=[fixed_t threshold]; if you want to use a fixed value of t*.

% The following function generate a set of parametric images fitting the
% Patlak Ref method at the voxel level
QModeling_parametric_images(studies_path,reference_path,interest_path,results_path,model,parameters,times)

disp('Parametric images for PatlakRef method generated');
disp('End demoQModeling');
end