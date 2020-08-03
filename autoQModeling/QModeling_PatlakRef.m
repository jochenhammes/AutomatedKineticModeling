function results = QModeling_PatlakRef(Ct,Cr,times,step_flag,varargin)
% It is used as a low-level function, called by QModeling_preprocessTACs or
% QModeling_parametric_images
%---------------------------------------------------------------------------------
% QModeling_PatlakRef is part of QModeling.
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
% Copyright (C) 2016 Francisco Javier Lopez Gonzalez, Karl-Khader
% Thurnhofer Hemsi

num_files = length(Ct);
tmin = ((times(1:num_files,1)+times(1:num_files,2))/2)/60;
times=times(1:length(Ct),:);
% Compute the integral:
intvalue = cumsum(diff(times,1,2).*Cr);

X = intvalue./Cr;
Y = Ct./Cr;

% Correct cancel errors (0/0)
X(isnan(X)|isinf(X)) = 0;
Y(isnan(Y)|isinf(Y)) = 0;

% First frame to be used to fitting
indfr_min = find(X,1,'first');

found = false;

if step_flag==1 %parametric images
    
    if nargin == 7
        t(1) = 1;
        restrict = varargin{1};
        Max_err = varargin{2};
        Cpet=varargin{3};
    else
        t(1) = 0;
        t(2) = varargin{1};
        Cpet=varargin{2};
    end
elseif step_flag==0 %preprocess
    if nargin == 6
        t(1) = 1;
        restrict = varargin{1};
        Max_err = varargin{2};        
    else
        t(1) = 0;
        t(2) = varargin{1};       
    end
else
    error('ERROR invalid value for the step_flag parameter (0 or 1)');
end

tchecked = t(1);
if tchecked == 1
    
    if (restrict(1) == 1)

        % Variables to the restrictions of t*
        rest_min = restrict(2);
        rest_max = restrict(3);
        
        rtm = find((times(:,1)/60) >= rest_min,1,'first');
        if rtm ~= 1 && rest_min <= tmin(rtm-1)
            rtm = rtm-1;
        end
        rtM = find((times(:,1)/60) < rest_max,1,'last');    %I must take a value if there is between the middle point of PET times
        if rtM ~= num_files && rest_max >= tmin(rtM)
            rtM = rtM+1;
        end

        if (rtm > num_files-1) || (rtm > rtM) % General case
            i = indfr_min;
            while (i <= num_files-2) && (found == false)      % At least 3 point to ajust
                x1 = X(i:end);
                y1 = Y(i:end);
                p = polyfit(x1,y1,1);

                z = polyval(p,x1);          % Error of all the values of regression
                err_act = max(abs(y1-z)./abs(z))*100;


                if err_act < Max_err
                    Max_err = err_act;
                    new_p = p;
                    time_ind_st = i;
                    found = true;
                end
                i = i+1;
            end

        else

            if (rtm == num_files-1)

                x1 = X(rtm:end);
                y1 = Y(rtm:end);
                new_p = polyfit(x1,y1,1);
                new_z = polyval(new_p,x1);          % Error of all the values of regression
                Max_err = max(abs(y1-new_z)./abs(new_z))*100;
                time_ind_st = rtm;

            else

                if (rtM >= num_files-1)
                    rtM = num_files-2;
                end
                i = max(rtm,indfr_min);
                while (i <= rtM) && (found == false)      % At least 3 point to ajust
                    x1 = X(i:end);
                    y1 = Y(i:end);
                    p = polyfit(x1,y1,1);

                    z = polyval(p,x1);          % Error of all the values of regression
                    err_act = max(abs(y1-z)./abs(z))*100;

                    if err_act < Max_err
                        Max_err = err_act;
                        new_p = p;
                        time_ind_st = i;
                        found = true;
                    end
                    i = i+1;
                end
            end
        end           

    else
        i = indfr_min;
        while (i <= num_files-2) && (found == false)      % At least 3 point to ajust

            x1 = X(i:end);
            y1 = Y(i:end);
            p = polyfit(x1,y1,1);

            z = polyval(p,x1);                      % Error of all the values of regression
            err_act = max(abs(y1-z)./abs(z))*100;

            if err_act < Max_err
                Max_err = err_act;
                new_p = p;
                time_ind_st = i;
                found = true;
            end
            i = i+1;
            
        end

    end
    
else
    
    tmin_ind = find((times(:,1)/60) >= t(2),1,'first');
    if tmin_ind ~= 1 && t(2) <= tmin(tmin_ind-1)
        tmin_ind = tmin_ind-1;
    end
    
     %New
    tmin_ind = max(tmin_ind,indfr_min);
    
    x1 = X(tmin_ind:end);
    y1 = Y(tmin_ind:end);
    new_p = polyfit(x1,y1,1);

    z = polyval(new_p,x1);                      % Error of all the values of regression
    Max_err = max(abs(y1-z)./abs(z))*100;

    time_ind_st = tmin_ind;
    found = true;
    
end


if (found == false)   
    ME = MException('PreprocessPatlak:MaxErrCondition','Not full fill MaxErr condition');
    throw(ME);
else
  
    %Saving results
    T = times(time_ind_st,1)/60;
    K = new_p(1)*60;
    intercept = new_p(2);
    Start = X(time_ind_st)/60;
    
    %Saving plots
    Z = polyval(new_p,X);
end

if t(1)==0 && t(2)~=T
    warning('t* has been selected discarding some initial frames because they induce 0 or NaN');
end

if step_flag==0
    % Goodness of fit
%     MSE = mean((Y(time_ind_st:end)-Z(time_ind_st:end)).^2);
    NMSE=1-((Y(time_ind_st:end)-Z(time_ind_st:end)).^2)./((Y(time_ind_st:end)-mean(Y(time_ind_st:end))).^2);
    CCoef=corrcoef(Y(time_ind_st:end),Z(time_ind_st:end));
    
%     results = [T K intercept Start Max_err MSE CCoef(1,2)];
    results = [T K intercept Start Max_err mean(NMSE) CCoef(1,2)];
elseif step_flag==1
    tfit_ind=find(times(:,1)/60 == T);
    
    % Define voxel-TAC matrix
    Yall = zeros(size(Cpet));

    % Normalize data
    for i = 1:length(Cr)   
        Yall(i,:) = Cpet(i,:)/Cr(i);
    end

    Yall(isnan(Yall)|isinf(Yall)) = 0;

    % Clear the unuse variable
    clear Cpet

    Xf = X(tfit_ind:end);

    % Construct Vandermonde matrix.
    V(:,2) = ones(length(Xf),1,class(Xf));
    V(:,1) = Xf.*V(:,2);

    % Solve least squares problem.
    [Q,R] = qr(V,0);

    ws = warning('off','all'); 
    images = R\(Q'*Yall(tfit_ind:end,:));    % Same as p = V\y;
    warning(ws);

    results=images;
end

