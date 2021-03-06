function [refFrame, DiagInfo] = ERCrefFramePatella(F,V,axEst,Param)
%ERCREFFRAMEPATELLA computes the ERC standard anatomical reference frame
%   for a patella
%
%   The ERC standard reference frame is defined according to Ho e.a.'s
%   definition:
%       AP(X): Perpendicular to the anterior surface
%       PD(Y): Connecting the patellar geometric center to the inferior pole*
%       ML(Z): Perpendicular to both
%   *Almost, the closest vertex perpendicular to AP is used.
%   
%   [Patella, DiagInfo] = ERCREFFRAMEPATELLA(F,V,axEst,Param)
%
%--Input
%   F        -    Faces of the patella
%   V        -    Vertices of the patella
%   axEst    -    Axis estimate
%                   Used for determining the signs of the axes and seeding
%                   the inferior pole finding.
%   Param    -    Parameter structure with (any of the) fields( = default):
%                     Param.infPoleFindScaleF = 1.5 
%                     Param.anteriorPercentage = 30 ;
%                     Param.IAgridSize = 0.5 ;
%
%--Output
%   refFrame  -   Struct with three field (X,Y,Z), having the coordinates of the
%                 respective axis 
%   DiagInfo -    Diagnostics information, use plotPatellaDiagInfo to show
%                 the different steps.
%
%
%   ORL Nijmegen, WJ Zevenbergen Januari 2013
%  (V1.0) ORL Nijmegen, Max Bakker 2016
%
%   References:
%      - Ho 2012; Computed tomography analysis of knee pose and geometry before
%        and after total knee arthroplasty
%      - Sharma 2012; Radiological method for measuring patellofemoral tracking
%         and tibiofemoral kinematics before and after total knee replacement
%
% see also ERCrefFrameTibia ERCrefFrameFemur plotPatellaDiagInfo

%% Initialising
try
%     P_infPoleFindScaleF = [2 1.5 0.4] ;
    P_infPoleFindScaleF = 1.5 ;
    P_anteriorPercentage = 30 ;
    P_IAgridSize = 0.5 ;
    if nargin > 3
        parfields  = fieldnames(Param) ;
        for pf = parfields'
            switch pf{1}
                case 'infPoleFindScaleF'
                    P_infPoleFindScaleF = Param.infPoleFindScaleF ;
                case 'anteriorPercentage'
                    P_anteriorPercentage = Param.anteriorPercentage ;
                case 'IAgridSize'
                    P_IAgridSize = Param.IAgridSize ;
            end
        end
    end
    
    if nargout > 1
        DiagInfo.param.IAgridSize = P_IAgridSize ;
        DiagInfo.param.anteriorPercentage = P_anteriorPercentage ;
        DiagInfo.param.infPoleFindScaleF = P_infPoleFindScaleF ;
    end
    
    %% Intertial Axes and Centre of Mass femura
    % Center of Mass = origin patella coordinate system
    [CoM,IA,SV] = computeInertialAxes(F,V,P_IAgridSize) ;
    %take the sign of the "AP" axis in agreement with the external frame
    %in order to know you are taking the anterior part
    IA(:,3)  = -sign(dot(axEst.X,IA(:,3))) * IA(:,3) ;
    
    % figure(131);
    % ezplotm([zeros(1,3);axEst.X],'-') ;hold on ;
    % ezplotm([zeros(1,3);IA(:,3)'],'r-')
    if nargout > 1
        DiagInfo.IA.IA = IA ;
        DiagInfo.IA.CM = CoM ;
        DiagInfo.IA.SV = SV ;
    end
    
    %% Select anterior surface patella
    % the perpendicular to the anterior surface is considered as the AP axis
    R_CS1 = eye(3)*IA';            % Rotation matrix inertial axes patella
    V_CS1 = (R_CS1*V')';   % Re-orientation of the patella vertices
    
    %Use axest to determine which side of location 1 is the plateau
    %ScanProt = 2 - (dot(axEst.X,IA(3,:))<0) ;
    
    % select anterior surface
    [F_PatellaAnterior,V_PatellaAnterior_CS1] = cutMeshByPercent(F,V_CS1,[0 P_anteriorPercentage],3);
    % Rotate back to original coordinate system
    V_PatellaAnterior = (R_CS1\V_PatellaAnterior_CS1')';
    
    % Fit plane to anterior surface patella
    [centroid,APaxis] = lsplane(V_PatellaAnterior);
    APaxis = APaxis/rssq(APaxis);       % Normalize
    %allign to external axes ;
    APaxis = sign(dot(axEst.X,APaxis)) * APaxis ;
    if nargout > 1
        DiagInfo.sections.AnteriorPatella.planeFitCentroid = centroid ;
        DiagInfo.sections.AnteriorPatella.V = V_PatellaAnterior ;
        DiagInfo.sections.AnteriorPatella.F = F_PatellaAnterior ;
    end
    %% Find the inferior pole
    rotMat = [axEst.X',axEst.Y',axEst.Z'] ;
    poleImin1 = -10 ; %checking convergence using the last result
    ppi = 1 ;
    fac = P_infPoleFindScaleF(1) ;
    while true ;
        %this function is most of the algorithm
        %what we do: center and rotate and center the patella in the refFrame
        %Then, cut all V for which dim > 0, strech in dimension dim by factor
        %(fac) and find the vertex furthest away from the COM. (the guess)
        [infPoleGuess,poleI,Rotation_CSl,V_find_CSl,distA] = findInfPole(V,rotMat,CoM,fac,2) ;
        
        if nargout > 1
            DiagInfo.polePosition(ppi).guess = infPoleGuess ;
            DiagInfo.polePosition(ppi).I = poleI ;
            DiagInfo.polePosition(ppi).RotM =Rotation_CSl ;
            DiagInfo.polePosition(ppi).V_CSl =V_find_CSl ;
            DiagInfo.polePosition(ppi).distA =distA;
            DiagInfo.polePosition(ppi).inAxes= rotMat;
            ppi = ppi + 1 ;
        end
        
        PDaxisEst = (CoM - infPoleGuess)' ;
        PDaxisEst = PDaxisEst / rssq(PDaxisEst) ;
        
        MLaxis = cross(APaxis,PDaxisEst) ;
        MLaxis = MLaxis / rssq(MLaxis) ;
        % Proximal-distal (inferior-superior) axis -> cross product ML and AP axis
        PDaxis = cross(MLaxis,APaxis) ;
        PDaxis = PDaxis / rssq(PDaxis) ;
        
        %Continue this until you get the same answer twice
        if poleI == poleImin1
            break
        end
        %update the stuff or the next iteration
        rotMat = [APaxis,PDaxis,MLaxis] ;
        
        poleImin1 = poleI  ;
%         %not change the factor 
%         fac = fac - (fac-P_infPoleFindScaleF(2))*P_infPoleFindScaleF(3) ;
    end
    
    %% Final output
    refFrame.X = sign(dot(axEst.X,APaxis)) * APaxis';
    refFrame.Y = sign(dot(axEst.Y,PDaxis)) * PDaxis';
    refFrame.Z = sign(dot(axEst.Z,MLaxis)) * MLaxis';
    refFrame.origin = CoM;
    DiagInfo.failed = 0 ;
    DiagInfo.refFrame = refFrame ;
    
    DiagInfo.failed = 0;
catch emAll
    % For instance to short diaphysis causes the method to crash
    %this block makes sure the output still is somewhat sensible
    emAll.getReport
    
    DiagInfo.failed = 1;
    DiagInfo.errorMessage = emAll ;
    
    %phony data to reveal it goes wrong w/o crashing
    dummyCoords.X = [1 0 0] ;
    dummyCoords.Y = [-1 0  0] ;
    dummyCoords.Z = [0 1 1] ;
    dummyCoords.origin = [ 0 0 0 ] ;
    DiagInfo.refFrame = dummyCoords ;
end

end


function [infPoleGuess,maxI,Rotation_CSl,V_find_CSl,distanceA] = findInfPole(Vertices,refFrame,origin,scaleF,dim)
Rotation_CSl = eye(3)*refFrame';
V_find_CSl = (Rotation_CSl * bsxfun(@minus,Vertices,origin)')'  ;

%take only the most distal "half" (below CM)
areBelow = V_find_CSl(:,dim)<0 ;

%Scale in dims direction
scaleA = ones(1,3) ;
scaleA(dim) = scaleF ;
V_find_CSl = V_find_CSl(areBelow,:) ;
V_find_CSl_scaled = bsxfun(@times,V_find_CSl,scaleA) ;

%find the maximum distance vertex (to [0 0 0], which is the origin)
distanceA = rssq(V_find_CSl_scaled,2) ;
[~,maxICutV] = max(distanceA) ;

%translate the index back to the whole patella, not just the lower half
maxICut = find(areBelow,maxICutV,'first') ;
maxI = maxICut(end) ;
infPoleGuess = Vertices(maxI,:) ;
end
