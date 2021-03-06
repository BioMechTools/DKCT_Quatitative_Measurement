%% this file is to test the TG and TT in anatomical frame
clear; clc; close all hidden;
% addpath('D:\project\4DTTTG\matlabCode\v0.5\coordinate\Source\');
%% functions location
addpath('.\function\')
addpath('.\draw\')
addpath('..\basic_function\')
addpath('..\coordinate\Source')
addpath('..\')

%% folder definition
str_sourceNew = '..\\..\\Data\\ProcessedData\\';
str_figure_landmark = '..\\..\\Data\\Draw\\landmarks\\';
str_figure = '..\\..\\Data\\Draw\\raw\\';
str_manual = '..\\..\\Data\\ManualTT_TG\\';

%% Data Input
for n_subj = 7
    str_subject = ['S00' num2str(n_subj)];
    for numSide = 1:2
        if numSide==1
            str_side = 'R';
        else

            str_side = 'L';
        end
        %%% read the manual TT and TG in static
        str_landmarks_file =  [str_manual 'Expert_1_1\Subject' num2str(n_subj) '_' str_side '.txt' ] ;
        matLandmarks = load(str_landmarks_file);
        staticLandmarks1 = matLandmarks(1:4,1:3);
        str_landmarks_file =  [str_manual 'Expert_1_2\Subject' num2str(n_subj) '_' str_side '.txt' ] ;
        matLandmarks = load(str_landmarks_file);
        staticLandmarks2 = matLandmarks(1:4,1:3);
        str_landmarks_file =  [str_manual 'Expert_1_3\Subject' num2str(n_subj) '_' str_side '.txt' ] ;
        matLandmarks = load(str_landmarks_file);
        staticLandmarks3 = matLandmarks(1:4,1:3);
        str_landmarks_file =  [str_manual 'Expert_3\Subject' num2str(n_subj) '_' str_side '.txt' ] ;
        matLandmarks = load(str_landmarks_file);
        staticLandmarks4 = matLandmarks(1:4,1:3);
        str_landmarks_file =  [str_manual 'Expert_2\Subject' num2str(n_subj) '_' str_side '.txt' ] ;
        matLandmarks = load(str_landmarks_file);
        staticLandmarks5 = matLandmarks(1:4,1:3);
        manual_TGPoint3D(1,:) = staticLandmarks1(3,:);   
        manual_TGPoint3D(2,:) = staticLandmarks2(3,:);
        manual_TGPoint3D(3,:) = staticLandmarks3(3,:);
        manual_TGPoint3D(4,:) = staticLandmarks4(3,:);
        manual_TGPoint3D(5,:) = staticLandmarks5(3,:);
        manual_TTPoint3D(1,:) = staticLandmarks1(4,:);   
        manual_TTPoint3D(2,:) = staticLandmarks2(4,:);
        manual_TTPoint3D(3,:) = staticLandmarks3(4,:);
        manual_TTPoint3D(4,:) = staticLandmarks4(4,:);
        manual_TTPoint3D(5,:) = staticLandmarks5(4,:);
        manual_LinePoint1_3D(1,:) = staticLandmarks1(1,:);   
        manual_LinePoint1_3D(2,:) = staticLandmarks2(1,:);
        manual_LinePoint1_3D(3,:) = staticLandmarks3(1,:);
        manual_LinePoint1_3D(4,:) = staticLandmarks4(1,:);
        manual_LinePoint1_3D(5,:) = staticLandmarks5(1,:);
        manual_LinePoint2_3D(1,:) = staticLandmarks1(2,:);   
        manual_LinePoint2_3D(2,:) = staticLandmarks2(2,:);
        manual_LinePoint2_3D(3,:) = staticLandmarks3(2,:);
        manual_LinePoint2_3D(4,:) = staticLandmarks4(2,:);
        manual_LinePoint2_3D(5,:) = staticLandmarks5(2,:);

        %%% stl
        femPath = [str_sourceNew str_subject '\stlNew\DynamicResample\Femur_' str_side '.stl' ] ;
        patPath = [str_sourceNew str_subject '\stlNew\DynamicResample\Patella_' str_side '.stl' ] ;
        tibPath = [str_sourceNew str_subject '\stlNew\DynamicResample\Tibia_' str_side '.stl' ] ;
        [Tibia.F,Tibia.V,~] = fImportSTL(tibPath);
        [Femur.F,Femur.V,~] = fImportSTL(femPath);
        [Patella.F,Patella.V,~] = fImportSTL(patPath);

        %%% input coordinates
        fem_coord_path = [str_sourceNew str_subject '\matlab\Coordinate\StaticCoordinateFemur' str_side] ;
        tib_coord_path = [str_sourceNew str_subject '\matlab\Coordinate\StaticCoordinateTibia' str_side] ;
        load(fem_coord_path);
        load(tib_coord_path);
        femCoords.PD = StaticCoordinateFemur(2,1:3);
        femCoords.AP = StaticCoordinateFemur(1,1:3);
        femCoords.ML = StaticCoordinateFemur(3,1:3);
        femCoords.Origin = StaticCoordinateFemur(4,1:3);
        tibCoords.PD = StaticCoordinateTibia(2,1:3);
        tibCoords.AP = StaticCoordinateTibia(1,1:3);
        tibCoords.ML = StaticCoordinateTibia(3,1:3);
        tibCoords.Origin = StaticCoordinateTibia(4,1:3);
        %%% infomation of the coordinates
        str_DiagInfos_path = [str_sourceNew str_subject '\matlab\Coordinate\DiagInfos'] ;
        load(str_DiagInfos_path)
        pt1 = DiagInfos.f.points12.pt1;
%         IA = DiagInfos.f.IA.Femur.IA;
%         R_CS1 = eye(3)*IA';            % Rotation matrix inertial axes femura
%         pt1 = (R_CS1\pt1')';    % Re-orientation of the femoral vertices
        %% Reference line and TG on posterior condyle
        rotationMatrix = [femCoords.PD femCoords.ML femCoords.AP];
        CutMatrix = [tibCoords.PD' tibCoords.ML' tibCoords.AP'];%[0 -1 0;0 0 -1;1 0 0];%[femCoords.PD femCoords.ML femCoords.AP];%
        rotationMatrixTib = [tibCoords.PD' tibCoords.ML' tibCoords.AP'];%[0 -1 0;0 0 -1;1 0 0];%

        [CA,sectionCenters,CMonCAaxis,V_csL,cellV,secI,rotM] = computeCrossSectionAreaAlongAxis_TT_TG_PCL(Femur.V,CutMatrix) ;
        %%% check the height of the TG of manual detected point
        %rotate vertices in the relevant frame
        %%% Test code for detecting the height of manual observation 
        [maxN, maxInd] = max(CA);
%         n_target_ind = maxInd;
        V1 = V_csL(:,1) ;
        [min_v1,v1_ind] = min(V1);
        % %%% Test1
             
%         figure;plotsurf(Femur.V,Femur.F);
%         hold on;
%         scatter3(Femur.V(v1_ind,1),Femur.V(v1_ind,2),Femur.V(v1_ind,3));
%         scatter3(pt1(1),pt1(2),pt1(3));
%         hold off;
        
        rot_pt1 = (rotM \ pt1')' ;
        n_target_ind = round((0.2*(rot_pt1(1) - min_v1)+0.8*maxInd));
        TGPoint3DTemp = zeros(6,3);
        TGPointTemp = zeros(6,2);
        %%% an option to tune the TG, to be confirmed by larger samples
        for num = 5:-1:0
            [Landmark_RefLine, Landmark_TGPoint,Landmark_contour, Vertices_surface] = get_TG_PCL(rotM,femCoords,V_csL,cellV,secI,str_side,n_target_ind-num);
            TGPoint3DTemp(num+1,:) = Landmark_TGPoint.TGPoint3D';
            TGPointTemp(num+1,:) = Landmark_TGPoint.TGPoint;
        end
        Landmark_TGPoint.TGPoint3D = mean(TGPoint3DTemp)';
        Landmark_TGPoint.TGPoint = mean(TGPointTemp);
        draw_TG_PCL_2D(Landmark_TGPoint,Landmark_RefLine,Landmark_contour,(rotM \ manual_TGPoint3D')');
        TGPoint3D = [Landmark_TGPoint.TGPoint3D'; manual_TGPoint3D];
        LinePoint1_3D = [Landmark_RefLine.LinePoint_Medial_3d'; manual_LinePoint1_3D];
        LinePoint2_3D = [Landmark_RefLine.LinePoint_Lateral_3d';manual_LinePoint2_3D];
        draw_TG_PCL_3D(Femur.V,Femur.F,femCoords,tibCoords,TGPoint3D,LinePoint1_3D,...
            LinePoint2_3D,str_figure_landmark,n_subj,str_side)
        %         saveas(gcf,['.\TibiaFrame\TG' num2str(n_subj) '_' str_side '1.png']);
        save([str_sourceNew str_subject '\matlab\Landmarks\28Tibia_Landmark_RefLine_' str_side],'Landmark_RefLine');
        save([str_sourceNew str_subject '\matlab\Landmarks\28Tibia_Landmark_TGPoint_' str_side],'Landmark_TGPoint');

        rotM = eye(3) * rotationMatrixTib; 
        manual_TT = (rotM \ staticLandmarks1(4,:)')' ;       
        [ Landmark_TTPoint ] = getTT( rotationMatrixTib, rotationMatrixTib,Tibia.V,Tibia.F);%getTT_Tibia( Tibia.V, rotationMatrixTib,2,Tibia.V,Tibia.F );
        save([str_sourceNew str_subject '\matlab\Landmarks\28Tibia_Landmark_TTPoint_' str_side],'Landmark_TTPoint');
%         saveas(gcf,['.\TibiaFrame\TT' num2str(n_subj) '_' str_side '1.png']);
        TT3D_Manual_Auto = [Landmark_TTPoint;manual_TTPoint3D];
        draw_TT_3D(Tibia.V,Tibia.F,tibCoords,tibCoords,TT3D_Manual_Auto,str_figure_landmark,n_subj,str_side);
        
        patPath = [str_sourceNew str_subject '\stlNew\DynamicResample\Patella_' str_side '_Static.stl' ] ;
        PatellaSTL= stlread(patPath);
        Landmark_PC =mean(PatellaSTL.vertices);
        save([str_sourceNew str_subject '\matlab\Landmarks\Landmark_PC_' str_side],'Landmark_PC');

    end
end

