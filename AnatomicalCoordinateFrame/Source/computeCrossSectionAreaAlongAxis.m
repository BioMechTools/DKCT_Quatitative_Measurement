function [CA,sectionCenters,CoM,V_csL] = computeCrossSectionAreaAlongAxis(V,R_axes,stepSize_perc)
%COMPUTECROSSSECTIONAREAALONGAXIS(V,R_axes,stepSize_perc)
%Calculates the cross section area of a vertex-set along a certain axis.
% [CA,sectionCenters,CoM,V_csL] = computeCrossSectionAreaAlongAxis(V,R_axes,stepSize_perc)
%
%--Input
%   V             -   Vertices. N by 3 array.
%   R_axes        -   Rotation matrix with the relevat direction as the first row
%   stepSize_perc -   Size (in percentage) of the sections. Note that to
%   low values result in underpopulated sections and bad results.
%
%--Ouput
%   CA            -   Crossectional array per section. 
%   sectionCenters-   Percentage centers of the sections.
%   CoM           -   Center of "mass" on the axis (in perc) 
%   V_csL         -   Vertices in the coordinate system given by R_axes
%
% Example usage:
%     [~, IA,~] = computeInertialAxes(F,V,1);
%     [CA,sectionCenters,CMonCAaxis] = computeCrossSectionAreaAlongAxis(V,IA,2) ;
%     plot(sectionCenters,CA) ;
%
% see also : computeInertialAxes, stlLoad 


%create roation matrix
rotM = eye(3) * R_axes' ;    
%rotate vertices in the relevant frame
V_csL = (rotM * V')' ;

%make sure it fits if you choose stepSize silly e.g. a value in the range
% [51-99] now results in 2 bins of size 50
stepSize_perc = stepSize_perc - mod(100,stepSize_perc) ;
edges = 0 : stepSize_perc:100 ;

V23 = V_csL(:,[2,3]) ;
V1 = V_csL(:,1) ;

%use histogramming on the first coordinate to identify at which
%heigth each vertex is. 
[~,~,secI] = histcounts(V1,(edges/100)*range(V1)+min(V1)) ;
% sectionCenters = (edgesBC(1:end-1) + edgesBC(2:end)) / 2 ;
sectionCenters = (edges(1:end-1) + edges(2:end)) / 2 ;
%now calculate the convex hull at all heights if there are enough points.
for i = max(secI):-1:1
    theseV = V23(secI==i,:) ;
    if size(theseV,1)>2
        [~,CA(i)] = convhull(theseV);
    else
        CA(i) = 0 ;
    end
end

if nargout > 2
    CoM = mean(CA.*sectionCenters)/mean(CA) ;
end
end