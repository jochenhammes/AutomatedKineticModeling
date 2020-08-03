function results = QModeling_LoganPlot(Ct,Cr,times,k2_p,maxError,step_flag,varargin)
% It is used as a low-level function, called by QModeling_preprocessTACs or
% QModeling_parametric_images
%---------------------------------------------------------------------------------
% QModeling_LoganPlot is part of QModeling.
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
% Copyright (C) 2017 Francisco Javier Lopez Gonzalez, Karl-Khader
% Thurnhofer Hemsi, Daniel Toro Flores

num_files = length(Ct);
n_case=0;
if step_flag == 0 %preprocess
    if nargin==7 %Restriction time is inactive
        t_star=varargin{1}*60;
        n_case=1;
    elseif nargin==8
        min_t_star=varargin{1}*60;
        max_t_star=varargin{2}*60;
        n_case=2;
    end
else %parametric images
    Cpet=varargin{1};
    if nargin==8 %Restriction time is inactive
        t_star=varargin{2}*60;
        n_case=1;
    elseif nargin==9
        min_t_star=varargin{2}*60;
        max_t_star=varargin{3}*60;
        n_case=2;
    end
end

pY=cumsum(diff(times,1,2).*Ct)./Ct;
numX=(cumsum(diff(times,1,2).*Cr) + Cr/k2_p);
pX=numX./Ct;
f=0;

% Correct cancel errors (0/0)
for i = 1:num_files
    if(isnan(pY(i)) || isinf(pY(i)))
        pY(i)=0;
    end
    if(isnan(pX(i)) || isinf(pX(i)))
        pX(i)=0;
    end
    if(pX(i)==0 && pY(i)==0)
        f=f+1;
    end
end

%VECTORs X and Y without zeros

pX=pX(f+1:end);
pY=pY(f+1:end);

%Error calc.
Eq=polyfit(pX,pY,1);
Z=polyval(Eq,pX);% Error of all the values of regression
uError = max(abs(pY-Z)./abs(Z))*100;
if(uError>=100)
    uError=100;
end

%Store times.
uTimes=times(f+1:end,1);
%Last time value.
uTimes((num_files+1)-f)=times(num_files,2);
%Middle times.
mTimes=(times(f+1:num_files,1)+times(f+1:num_files,2))/2;
nError=false;

if n_case==0 %Restriction time is inactive
    i=1;
    if(uError>maxError)
        while (uError >= maxError && i<=length(pX)-2)

            uEq=polyfit(pX(i:end),pY(i:end),1);
            uZ=polyval(uEq,pX(i:end));
            uError = max(abs(pY(i:end)-uZ)./abs(uZ))*100;
            i=i+1;
            if(uError<maxError)
                nError=true;
            end
        end
        i=i-1;
        Z=polyval(uEq,pX);
        BPnd=uEq(1)-1;
        intercept=uEq(2);
    end

    if(uError==maxError)
        nError=true;
        BPnd=Eq(1)-1;
        intercept=Eq(2);

    end
elseif n_case==1   
    i=1;
    t=0;
    maxError=100; 
     if t_star > mTimes(length(pX)-1)
        ME = MException('PreprocessLoganPlot:NumberDataPointsFitCondition','The t* value only takes the last frame');
        throw(ME);
    end 
    if t_star >= uTimes(length(pX)-1)
        t_star=uTimes(length(pX)-1);
    end

    if(t_star>0)
     while(t == 0)
         if(t_star <= uTimes(i))
             t=1;
         end
     i=i+1;   
     end 
    i=i-2; 
    end

    if(i<length(pX)-1)
        if(t_star > mTimes(i))
            i=i+1;
        end
    end

    if(i>length(pX)-2)
        warndlg('The restrict time only takes the last two time points');
    end

    if(uError>maxError)    
        while (uError >= maxError && i<=length(pX))
            uEq=polyfit(pX(i:end),pY(i:end),1);
            uZ=polyval(uEq,pX(i:end));
            uError = max(abs(pY(i:end)-uZ)./abs(uZ))*100;
            i=i+1;
            if(uError<maxError)
                nError=true;
            end
        end
         i=i-1;
         Z=polyval(uEq,pX);
         BPnd=uEq(1)-1;
         intercept=uEq(2);

    end
    if(uError==maxError)

        uEq=polyfit(pX(i:end),pY(i:end),1);

        BPnd=uEq(1)-1;
        intercept=uEq(2);
        Z=polyval(uEq,pX);
        nError=true;
    end
else %ncase is 2
    
    t=0;
    i=1;
    u=1;

    if min_t_star > mTimes(length(pX)-1)
        ME = MException('PreprocessLoganPlot:LowerTimeIncorrect','Lower time restriction only take the last frame');
        throw(ME)
    elseif(min_t_star<=uTimes(1))
        i=1;
    else
        while(t == 0)
            i=i+1; 
            if(min_t_star <= uTimes(i))
            t=1;
            end
        end
        i=i-1;
    end
    if(min_t_star > mTimes(i))
        i=i+1;
    end
    t=0;
    if max_t_star > mTimes(length(pX))
    u=length(pX);
    else
        while(t == 0)
            u=u+1; 
            if(max_t_star <= uTimes(u))
            t=1;
            end
        end
        u=u-1;
    end
    if(max_t_star >= mTimes(u))
        u=u+1;
    end
    if(uError>maxError)    
        while (uError >= maxError && i<=u+1)
            uEq=polyfit(pX(i:end),pY(i:end),1);
            uZ=polyval(uEq,pX(i:end));
            uError = max(abs(pY(i:end)-uZ)./abs(uZ))*100;
            i=i+1;
            if(i>u+1)
                ME = MException('PreprocessLoganPlot:MaxErrCondition','Not full fill MaxErr condition');
                throw(ME) 
            end
            if(uError<maxError)
                nError=true;
            end 
        end
         i=i-1;
         Z=polyval(uEq,pX);
         BPnd=uEq(1)-1;
         intercept=uEq(2);       
    end
end

if step_flag == 0 %preprocess    
    if (nError == false)   
        ME = MException('PreprocessLoganPlot:MaxErrCondition','Not full fill MaxErr condition');
        throw(ME);
    else   

        %Saving results
        % pX=pX./60;
        %NMSE=goodnessOfFit(pY(i:end),Z(i:end),'NMSE');
        NMSE=1-((pY(i:end)-Z(i:end)).^2)/((pY(i:end)-mean(pY(i:end))).^2);
        CCoef=corrcoef(pY(i:end),Z(i:end));
    %     results=[BPnd intercept uTimes(i)/60 pX(i) CCoef(1,2) NMSE];
        results=[BPnd intercept uTimes(i)/60 CCoef(1,2) mean(NMSE(end))];
        %plots=[pX pY Z];
%         QMlastPreprocess.LoganPlot.numX=numX;
%         QMlastPreprocess.LoganPlot.l=i+f;

    end
else %parametric images
    % Variable start
    nVoxels = size(Cpet,2);    
    fr=i+f;
    X=numX(fr:end);
    RCpet = Cpet(fr:end,:);

    images = zeros(2,nVoxels);
    P = zeros(6,nVoxels);
    y = zeros(num_files);

    %lhs numerator of equation
    for i=1:nVoxels
        y(:,i)=cumsum(Cpet(:,i).*diff(times,1,2)); 
    end

    %take values from t* obtained in the preprocess.
    y=y(fr:end,:);
    
    %Parametric image
    for i = 1:nVoxels
      %Obtain only values differents of NaN or infinite
      nonz=find(RCpet(:,i));
      den=RCpet(nonz,i);

      %At least two points
      if(length(nonz)>=2)    
      Yc=y(nonz,i)./den;
      Xc=X(nonz)./den;

      P(1,i)=mean(Xc);
      P(2,i)=mean(Yc);
      P(3,i)=sum(Yc.*Xc)*length(nonz);
      P(4,i)=sum(Xc);
      P(5,i)=sum(Yc);
      P(6,i)=sum(Xc.^2)*length(nonz);

      end
    end    
    
    % manual regresion 
    images(1,:)=((P(3,:)-P(4,:).*P(5,:))./(P(6,:)-P(4,:).^2))-1;
    images(2,:)=P(2,:)-(images(1,:)+1).*P(1,:);
    
    results=images;
end