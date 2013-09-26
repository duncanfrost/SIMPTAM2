function [vCameras, vPoints, mMeasurements, delta_cams, delta_points] = calculateresidualssparse2(KeyFrames, Map ,map,calcJ,lambda,left1,right1)
%CALCULATERESIDUALS Summary of this function goes here
%   Detailed explanation goes here

ncameras = size(KeyFrames,2);
npoints = size(Map.points,2);
camparams = 6;
pointparams = 3;
K = KeyFrames(1).Camera.K;






for i = 1:size(KeyFrames,2)
    vCameras{i}.U = zeros(6,6);
    vCameras{i}.ea = zeros(6,1);
end

for i = 1:size(Map.points,2)
    vPoints{i}.V = zeros(3,3);
    vPoints{i}.eb = zeros(3,1);
end




measCount = 0;







for i = 1:size(KeyFrames,2)
    
    for j = 1:size(KeyFrames(i).ImagePoints,2)
        
        id = KeyFrames(i).ImagePoints(j).id;
        if ~isempty(id)
            
            measCount = measCount + 1;
            
            
            E = KeyFrames(i).Camera.E;
            
            imagePoint = KeyFrames(i).ImagePoints(j).location;
            
            pointCamera = E*Map.points(id).location;
            X = pointCamera(1);
            Y = pointCamera(2);
            Z = pointCamera(3);
            x = X/Z;
            y = Y/Z;
            pix = K*[x y 1]';
            x = pix(1);
            y = pix(2);
            
            
            
            u = imagePoint(1);
            v = imagePoint(2);
            
            meas.err = [(u-x) (v-y)]';
            meas.c = i;
            meas.p = id;
            
            fx = K(1,1);
            fy = K(2,2);
            
            
            if calcJ
                
                A = zeros(2,6);
                B = zeros(2,3);
                if i > 1
                    for c = 1:camparams
                        [dX_dp dY_dp dZ_dp] = expdiffXn(X,Y,Z,eye(4,4),c);
                        A(1,c) = fx*(dX_dp*Z - dZ_dp*X)/(Z^2);
                        A(2,c)= fy*(dY_dp*Z - dZ_dp*Y)/(Z^2);
                    end
                end
                
                for p = 1:pointparams
                    [dX_dp dY_dp dZ_dp] = diffXn3D(E,p);
                    B(1,p) = fx*(dX_dp*Z - dZ_dp*X)/(Z^2);
                    B(2,p) = fy*(dY_dp*Z - dZ_dp*Y)/(Z^2);
                end
            end
            
            
            meas.A = A;
            meas.B = B;
            
            vCameras{meas.c}.U = vCameras{meas.c}.U + A'*A;
            vCameras{meas.c}.Ustar = vCameras{meas.c}.U + diag(diag(vCameras{meas.c}.U))*lambda;
            vCameras{meas.c}.ea = vCameras{meas.c}.ea + A'*meas.err;
            vPoints{meas.p}.V = vPoints{meas.p}.V + B'*B;
            vPoints{meas.p}.Vstar = vPoints{meas.p}.V + diag(diag(vPoints{meas.p}.V))*lambda;
            vPoints{meas.p}.eb = vPoints{meas.p}.eb + B'*meas.err;
            
            meas.W = A'*B;
            vMeasurements{measCount} = meas;
            mMeasurements{meas.p, meas.c} = meas;
            
            
            
        end
        
        
        
    end
end


for i=1:size(mMeasurements,1)
    for j=1:size(mMeasurements,2)
        if ~isempty(mMeasurements{i,j})
            mMeasurements{i,j}.Y = mMeasurements{i,j}.W/vPoints{i}.Vstar;
        end
    end
end








%Diagonal parts of S
S = zeros((size(KeyFrames,2)-1)*6,(size(KeyFrames,2)-1)*6);
E = zeros((size(KeyFrames,2)-1)*6,1);
for j = 2:size(KeyFrames,2)
    m6 =  vCameras{j}.Ustar;
    v6 =  vCameras{j}.ea;
    
    for i = 1:size(Map.points,2)
        if ~isempty(mMeasurements{i,j})
            m6 = m6 - (mMeasurements{i,j}.Y*mMeasurements{i,j}.W');
            v6 = v6 - (mMeasurements{i,j}.Y*vPoints{i}.eb);
        end
    end
    
    matStart = (j-2)*6 + 1;
    matEnd = (j-2)*6 + 6;
    
    S(matStart:matEnd,matStart:matEnd) = m6;
    E(matStart:matEnd) = v6;
end


%Non-Diagonal Parts
for j = 2:size(KeyFrames,2)
    for k = 2:size(KeyFrames,2)
        if j~=k
            in = zeros(6,6);
            jStart = (j-2)*6 + 1;
            jEnd = (j-2)*6 + 6;
            kStart = (k-2)*6 + 1;
            kEnd = (k-2)*6 + 6;
            for i = 1:size(Map.points,2)
                if ~isempty(mMeasurements{i,j}) && ~isempty(mMeasurements{i,k})
                    in = in - (mMeasurements{i,j}.Y*mMeasurements{i,k}.W');
                end
            end
            
            S(jStart:jEnd,kStart:kEnd) = in;
            
            
            
    
        end
    end
end


delta_cams = S\E;

delta_points = zeros(3*size(Map.points,2),1);



for i = 1:size(Map.points,2)
    delta = vPoints{i}.eb;
    
    pointStart = (i-1)*3 + 1;
    pointEnd = (i-1)*3 + 3;
    
    
    
    for j = 2:size(KeyFrames,2)
        camStart = (j-2)*6 + 1;
        camEnd = (j-2)*6 + 6;
        if ~isempty(mMeasurements{i,j})
            delta = delta - mMeasurements{i,j}.W'*delta_cams(camStart:camEnd);
        end
    end
    
    delta = vPoints{i}.Vstar\delta;
    delta_points(pointStart:pointEnd) = delta;
end

















end


