function QModeling_preprocessTACs(TACsfile,TimeTable,save_path,model,parameters)
% This function permits to preprocess a set of TACs of interest and
% reference to obtain the parameters of a compartimental model. Four
% models are implemented: SRTM, SRTM2, PatlakRef and LoganPlot.
%
% Usage: call QModeling_preprocessTACs function with the following input
% parameters.
% 
%     - TACsfile: path to a .txt file containing the TACs to be analyzed.
%     This file must be organized as follows. The first row must contain
%     the mid-times of each frame. The following rows are organized in
%     pairs, each pair corresponding to a different PET study. The first
%     row of each pair contains the TAC of the reference region. The second
%     row in the pair contains the TAC of the region of interest of the
%     same PET study.
% 
%     - TimeTable: path to a .txt file containing the start and end times for each frame
% 
%     - save_path: path to a directory where the results will be saved. If
%     the path is 'd', the current directory will be used .
% 
%     - model: a string indicating the name of the selected model. It could be 'SRTM',
%     'SRTM2', 'PatlakRef', 'LoganPlot'.
% 
%     - parameters: a vector containing the minimum information required to
%     preprocess the selected model. For more information, please go to the online manual: 
%     http://www.uimcimes.es/QModeling_help/html/
% 
%       'SRTM': [k2a_min k2a_max num_basis_functions resampling]
% 
%       'SRTM2': [k2a_min k2a_max num_basis_functions resampling k2_p]. If
%       you want to estimate k2_p, use the value -1 (the estimated value of k2_p
%       will be used as a fixed value of this parameter). If you directly want to specify
%       a fixed value for k2_p, simply put it.
% 
%       'PatlakRef': [restrict_t*_min restrict_t*_max MaxError].  If you
%       want to use a fixed value of t*, introduce only this fixed value of t* as "parameters" input. 
%       In other case, t* will be estimated considering the min and max restrictions. 
%       If you don't want to use restrictions in the estimate of t* give the -1 value to
%       the restrict_t*_min and the restrict_t*_max parameters.
%
%       'LoganPlot': [MaxError k2' restrict_t* restrict_t*_min restrict_t*_max]. 
%       There are three ways to run Logan Plot model. One option is
%       estimate t* based on the MaxError (input parameters: MaxError and
%       k2'). Another option is estimate t* between two values,
%       restrict_t*_min and restrict_t*_max, based on MaxError (input 
%       parameters: MaxError, k2', restrict_t*_min and restrict_t*_max).
%       The third option is use a fixed t* value (input parameters:
%       MaxError with a fixed value of 100, k2' and restrict_t* as the 
%       fixed t* value)
%       
%--------------------------------------------------------------------------
% QModeling_preprocessTACs is part of QModeling.
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
    fprintf(QMf_logfile,strcat(aux_date(end-7:end),' Starting command-line function QModeling_preprocessTACs.m with parameters:\n'));
    fprintf(QMf_logfile,strcat(' -TACsfile:',TACsfile,'\n'));
    fprintf(QMf_logfile,strcat(' -time table:',TimeTable,'\n'));
    fprintf(QMf_logfile,strcat(' -save_path:',save_path,'\n'));
    fprintf(QMf_logfile,strcat(' -model:',model,'\n'));
    fprintf(QMf_logfile,strcat(' -parameters:',mat2str(parameters),'\n'));
    
    disp('------------------------------------------------------')
    disp(['Starting job at ', datestr(now)])
    disp('')
    
    data = load(TACsfile); 
    s = size(data);
    if mod((s(1)-1),2) ~= 0
        fprintf(QMf_logfile,strcat('  ERROR: Inconsistent number of Cr-Ct pairs, please check it','\n'));
        error('Inconsistent number of Cr-Ct pairs, please check it')
    end

    times = load(TimeTable);

    num_sim = (s(1)-1)/2;
    CPUtime = 0;

    disp(['Data loaded from ',TACsfile])
    fprintf(QMf_logfile,strcat(aux_date(end-8:end),[' Data loaded from ',TACsfile], '\n'));
    
    if strcmp(model,'SRTM') == 1 
            
        disp('Model selected: SRTM')
        fprintf(QMf_logfile,strcat(aux_date(end-8:end),' Model selected: SRTM \n'));
        
        if length(parameters) ~= 4
            fprintf(QMf_logfile,strcat('  ERROR: There is not enough parameters (4)','\n'));
            error('There is not enough parameters (4)');
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
        end
        
        disp('Parameters:')
        disp(['k2a_min = ', num2str(k2a_min)])
        disp(['k2a_max = ', num2str(k2a_max)])
        disp(['Number of basis functions = ', num2str(num_BF)])
        disp(['Resampling = ', num2str(resampling)])
        
        results_SRTM = zeros(num_sim,6); 
        k=1;
        start = tic;
        for j=2:2:s(1)-1 
            Cr=data(j,:)';
            Ct=data(j+1,:)';              
            results_SRTM(k,:) = QModeling_SRTM(Ct,Cr,times,k2a_min,k2a_max,num_BF,resampling);            
            k=k+1;
        end 

        CPUtime=toc(start);
        
        results_SRTM=[{'R1','k2a','k2','BPnd','NMSE','Corr. Coef.'};num2cell(results_SRTM)];
        
        try
            if strcmp(save_path,'d')
                f=fopen(strcat('Preprocessing',model,'_Results.txt'),'wt');
                save(strcat('Preprocessing',model,'_Results.mat'),'results_SRTM');
            else
                f=fopen(strcat(save_path,filesep,'Preprocessing',model,'_Results.txt'),'wt');
                save(strcat(save_path,filesep,'Preprocessing',model,'_Results.mat'),'results_SRTM');
            end
            fprintf(f,' | %s | \t',results_SRTM{1,:});
            fprintf(f,'\n');
            for i=2:1:k
                fprintf(f,'%f\t',results_SRTM{i,:});
                fprintf(f,'\n');
            end
            fclose(f);
            if strcmp(save_path,'d'), aux_save_path=pwd; else, aux_save_path=save_path; end
            disp(['Preprocessing results written in ', strcat(aux_save_path,filesep,'Preprocessing',model,'_Results(.txt and .mat)')]);
            fprintf(QMf_logfile,strcat(aux_date(end-8:end),['Preprocessing results written in ', strcat(aux_save_path,filesep,'Preprocessing',model,'_Results(.txt and .mat)')],'\n'));
        catch
            fprintf(QMf_logfile,strcat('  ERROR: Writing results in file','\n'));
            error('ERROR Writing results in file');
        end    
    
        
    elseif strcmp(model,'SRTM2') == 1
        
        disp('Model selected: SRTM2')
        fprintf(QMf_logfile,strcat(aux_date(end-8:end),' Model selected: SRTM2 \n'));
        
        if length(parameters) ~= 5
            fprintf(QMf_logfile,strcat('  ERROR: Writing results in file','\n'));
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
            
            k2_p = parameters(5); 
            if isnan(k2_p) || ((k2_p < 0) && (k2_p ~= -1))
                fprintf(QMf_logfile,strcat(strcat('  ERROR: k2',char(39),' must be a positive number or -1'),'\n'));
                error(strcat('k2',char(39),' must be a positive number or -1'));
            end

        end
        
        disp('Parameters:')
        disp(['k2a_min = ', num2str(k2a_min)])
        disp(['k2a_max = ', num2str(k2a_max)])
        disp(['Number of basis functions = ', num2str(num_BF)])
        disp(['Resampling = ', num2str(resampling)])
        if k2_p == -1; disp('Estimating k2_p...'); else disp(['Fixed k2_p = ',num2str(k2_p)]); end
        
        results_SRTM2 = zeros(num_sim,6); 
        k=1;
        start = tic;
        
        for j=2:2:s(1)-1 
            Cr=data(j,:)';
            Ct=data(j+1,:)';              
            results_SRTM2(k,:) = QModeling_SRTM2(Ct,Cr,times,k2_p,k2a_min,k2a_max,num_BF,resampling);
            k=k+1;
        end 

        CPUtime=toc(start);
        
        results_SRTM2=[{'R1','k2a','k2','BPnd','NMSE','Corr. Coef.'};num2cell(results_SRTM2)];
        try
            if strcmp(save_path,'d')
                f=fopen(strcat('Preprocessing',model,'_Results.txt'),'wt');
                save(strcat('Preprocessing',model,'_Results.mat'),'results_SRTM2');
            else
                f=fopen(strcat(save_path,filesep,'Preprocessing',model,'_Results.txt'),'wt');
                save(strcat(save_path,filesep,'Preprocessing',model,'_Results.mat'),'results_SRTM2');
            end
            fprintf(f,' | %s | \t',results_SRTM2{1,:});
            fprintf(f,'\n');
            for i=2:1:k
                fprintf(f,'%f\t',results_SRTM2{i,:});
                fprintf(f,'\n');
            end
            fclose(f);
            if strcmp(save_path,'d'), aux_save_path=pwd; else, aux_save_path=save_path; end
            disp(['Preprocessing results written in ', strcat(aux_save_path,filesep,'Preprocessing',model,'_Results(.txt and .mat)')]);
            fprintf(QMf_logfile,strcat(aux_date(end-8:end),['Preprocessing results written in ', strcat(aux_save_path,filesep,'Preprocessing',model,'_Results(.txt and .mat)')],'\n'));
        catch
            fprintf(QMf_logfile,strcat('  ERROR: Writing results in file','\n'));
            error('ERROR Writing results in file');
        end
    
        
    elseif strcmp(model,'PatlakRef') == 1
        
        disp('Model selected: PatlakRef')
        fprintf(QMf_logfile,strcat(aux_date(end-8:end),' Model selected: PatlakRef \n'));
        
        num_param = length(parameters);
        if num_param ~= 1 && num_param ~= 3
            fprintf(QMf_logfile,strcat('  ERROR: There is not enough parameters (1 or 3)','\n'));
            error('There is not enough parameters (1 or 3)');
        else

            if num_param == 1               
                tfit = parameters;
                if isnan(tfit) || (tfit < 0)
                    fprintf(QMf_logfile,strcat('  ERROR: t* must be a positive number','\n'));
                    error('t* must be a positive number');
                end
                
                disp('Parameters:')
                disp(['Fixed t* = ',num2str(tfit)])
                
                results_PatlakRef = zeros(num_sim,7); 
                k=1;
                start = tic;

                for j=2:2:s(1)-1 
                    Cr=data(j,:)';
                    Ct=data(j+1,:)';  
                    results_PatlakRef(k,:) = QModeling_PatlakRef(Ct,Cr,times,0,tfit);
                    k=k+1;
                end
                CPUtime=toc(start);
                
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
                    fprintf(QMf_logfile,strcat('  ERROR: Upper restriction must be bigger than Lower restrict','\n'));
                    error('Upper restrict must be bigger than Lower restrict');
                end
                
                Max_err = parameters(3);
                if isnan(Max_err)
                    fprintf(QMf_logfile,strcat('  ERROR: MaxErr must be a positive number','\n'));
                    error('MaxErr must be a positive number');
                end
                
                if (minR == -1) || (maxR == -1)
                    useR = 0;
                else
                    useR = 1;
                end
                
                disp('Parameters:')
                
                if useR == 0; disp('No restrictions in t*')
                else disp(['MinRestrict = ',num2str(minR),'; MaxRestrict = ',num2str(maxR)]); end
                disp(['Maximum error = ', num2str(Max_err)])
                
                results_PatlakRef = zeros(num_sim,7); 
                k=1;
                start = tic;

                for j=2:2:s(1)-1 
                    Cr=data(j,:)';
                    Ct=data(j+1,:)';  
                    results_PatlakRef(k,:) = QModeling_PatlakRef(Ct,Cr,times,0,[useR minR maxR],Max_err);
                    k=k+1;
                end
                CPUtime=toc(start);
            end

        end
        
        results_PatlakRef=[{'T','K','intercept','Start','Max_err','NMSE','Corr. Coef.'};num2cell(results_PatlakRef)];
        try
            if strcmp(save_path,'d')
                f=fopen(strcat('Preprocessing',model,'_Results.txt'),'wt');
                save(strcat('Preprocessing',model,'_Results.mat'),'results_PatlakRef');
            else
                f=fopen(strcat(save_path,filesep,'Preprocessing',model,'_Results.txt'),'wt');
                save(strcat(save_path,filesep,'Preprocessing',model,'_Results.mat'),'results_PatlakRef');
            end
             
            fprintf(f,' | %s | \t',results_PatlakRef{1,:});
            fprintf(f,'\n');
            for i=2:1:k
                fprintf(f,'%f\t',results_PatlakRef{i,:});
                fprintf(f,'\n');
            end
            fclose(f);
            if strcmp(save_path,'d'), aux_save_path=pwd; else, aux_save_path=save_path; end
            disp(['Preprocessing results written in ', strcat(aux_save_path,filesep,'Preprocessing',model,'_Results(.txt and .mat)')]);
            fprintf(QMf_logfile,strcat(aux_date(end-8:end),['Preprocessing results written in ', strcat(aux_save_path,filesep,'Preprocessing',model,'_Results(.txt and .mat)')],'\n'));
        catch
            fprintf(QMf_logfile,strcat('  ERROR: Writing results in file','\n'));
            error('ERROR Writing results in file');
        end
        
    elseif strcmp(model,'LoganPlot') == 1
        
        disp('Model selected: LoganPlot')
        fprintf(QMf_logfile,strcat(aux_date(end-8:end),' Model selected: LoganPlot \n'));
        
        num_param = length(parameters);
        if num_param ~= 2 && num_param ~= 3 && num_param ~=4
            fprintf(QMf_logfile,strcat('  ERROR: There is not enough parameters (2, 3 or 4)','\n'));
            error('There is not enough parameters (2, 3 or 4)');
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
            
            k2_p= k2_p/60;           
            results_LoganPlot = zeros(num_sim,5); 
            
            if num_param == 2                 
                
                disp('Parameters:')
                disp(['Max Error = ',num2str(maxError)]);
                disp(['k2',char(39),' = ',num2str(k2_p)]);
                k=1;
                start = tic;
                for j=2:2:s(1)-1 
                        Cr=data(j,:)';
                        Ct=data(j+1,:)';                 
                        results_LoganPlot(k,:) = QModeling_LoganPlot(Ct,Cr,times,k2_p,maxError,0);
                        k=k+1;
                end
                CPUtime=toc(start);
            elseif num_param == 3
                t_star=parameters(3);
                if isnan(t_star) || (t_star < 0)
                    fprintf(QMf_logfile,strcat('  ERROR: the restriction time must be a positive number','\n'));
                    error(strcat('The restriction time must be a positive number'));
                end
                disp('Parameters:')
                disp(['Max Error = ',num2str(maxError)]);
                disp(['k2',char(39),' = ',num2str(k2_p)]);
                disp(['t* = ',num2str(t_star)]);
                k=1;
                start = tic;
                for j=2:2:s(1)-1 
                        Cr=data(j,:)';
                        Ct=data(j+1,:)';                 
                        results_LoganPlot(k,:) = QModeling_LoganPlot(Ct,Cr,times,k2_p,maxError,0,t_star);
                        k=k+1;
                end               
                CPUtime=toc(start);
            else %num_param == 4
               min_t_star=parameters(3);
               max_t_star=parameters(4);
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
               disp('Parameters:')
               disp(['Max Error = ',num2str(maxError)]);
               disp(['k2',char(39),' = ',num2str(k2_p)]);
               disp(['Lower restriction of t* = ',num2str(min_t_star)]);
               disp(['Upper restriction of t* = ',num2str(max_t_star)]);
               k=1;
               start = tic;
               for j=2:2:s(1)-1 
                       Cr=data(j,:)';
                       Ct=data(j+1,:)';                 
                       results_LoganPlot(k,:) = QModeling_LoganPlot(Ct,Cr,times,k2_p,maxError,0,min_t_star,max_t_star);
                       k=k+1;
               end
               CPUtime=toc(start);
            end
        end
            
            results_LoganPlot=[{'BPnd','intercept','t*','NMSE','Corr. Coef.'};num2cell(results_LoganPlot)];
            try
                if strcmp(save_path,'d')
                    f=fopen(strcat('Preprocessing',model,'_Results.txt'),'wt');
                    save(strcat('Preprocessing',model,'_Results.mat'),'results_LoganPlot');
                else
                    f=fopen(strcat(save_path,filesep,'Preprocessing',model,'_Results.txt'),'wt');
                    save(strcat(save_path,filesep,'Preprocessing',model,'_Results.mat'),'results_LoganPlot');
                end

                fprintf(f,' | %s | \t',results_LoganPlot{1,:});
                fprintf(f,'\n');
                for i=2:1:k
                    fprintf(f,'%f\t',results_LoganPlot{i,:});
                    fprintf(f,'\n');
                end
                fclose(f);
                if strcmp(save_path,'d'), aux_save_path=pwd; else, aux_save_path=save_path; end
                disp(['Preprocessing results written in ', strcat(aux_save_path,filesep,'Preprocessing',model,'_Results(.txt and .mat)')]);
                fprintf(QMf_logfile,strcat(aux_date(end-8:end),['Preprocessing results written in ', strcat(aux_save_path,filesep,'Preprocessing',model,'_Results(.txt and .mat)')],'\n'));
            catch
                fprintf(QMf_logfile,strcat('  ERROR: Writing results in file','\n'));
                error('ERROR Writing results in file');
            end

%% ADDING A NEW MODEL %% 
%
% elseif strcmp(model,'newModel_Name') == 1
%     disp('Model selected: newModel_Name')
%         fprintf(QMf_logfile,strcat(aux_date(end-8:end),' Model selected: newModel_Name \n'));
%         
%% Optional: Check the number and the values of the input parameters
% [...]        
% 
% Display the values of the input parameters
%         disp('Parameters:')
%         disp(['1st_parameter_name = ', num2str(1st_parameter_value)])
%         disp(['2nd_parameter_name = ', num2str(2nd_parameter_value)])
%         [...]
%  
%% Run the script of the new model
%         results_model_matrix = zeros(num_sim,num_modelParameters+2); 
%         k=1;
%         start = tic;
%         for j=2:2:s(1)-1 
%             Cr=data(j,:)';
%             Ct=data(j+1,:)';              
%             results_matrix(k,:) = QModeling_newModel_Name(Ct,Cr,times,1st_input_parameter,2nd_input_parameter,...);            
%             k=k+1;
%         end 
% 
%         CPUtime=toc(start);
%
%% Save the results
%         results_matrix=[{'1st_modelFitParameter','2nd_modelFitParameter',...,'MSE','Corr. Coef.'};num2cell(results_model_matrix)];
%         
%         try
%             if strcmp(save_path,'d')
%                 f=fopen(strcat('Preprocessing',model,'_Results.txt'),'wt');
%                 save(strcat('Preprocessing',model,'_Results.mat'),'results_model_matrix');
%             else
%                 f=fopen(strcat(save_path,filesep,'Preprocessing',model,'_Results.txt'),'wt');
%                 save(strcat(save_path,filesep,'Preprocessing',model,'_Results.mat'),'results_model_matrix');
%             end
%             fprintf(f,' | %s | \t',results_model_matrix{1,:});
%             fprintf(f,'\n');
%             for i=2:1:k
%                 fprintf(f,'%f\t',results_model_matrix{i,:});
%                 fprintf(f,'\n');
%             end
%             fclose(f);
%         catch
%             fprintf(QMf_logfile,strcat('  ERROR: Writing results in file','\n'));
%             error('ERROR Writing results in file');
%         end  
    end  
    
    

    disp(['Preprocessing elapsed time: ', num2str(CPUtime)])
    disp(['End job at ', datestr(now)])
    disp('------------------------------------------------------')
    fprintf(QMf_logfile,strcat(aux_date(end-8:end),['Preprocessing elapsed time: ', num2str(CPUtime)],'\n'));
    fprintf(QMf_logfile,strcat(aux_date(end-7:end),[' End job at ', datestr(now)]));
    fprintf(QMf_logfile,strcat('\n','----------------------------------------------','\n'));
    
    fclose(QMf_logfile);
    
delete(h_QM);
end
