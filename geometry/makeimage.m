function [ImagePoints] = makeimage(Camera, World, noise, associate, camID)
kfimpointcount = 0;
ImagePoints = [];
haspoints = false;
for i = 1:length(World.points)
    
    ImagePoint = projectpoint(Camera, World.points(i),noise, associate,camID);
    if (~isempty(ImagePoint))
        if ~haspoints
            haspoints = true;
            clear ImagePoints;
        end
            
        kfimpointcount = kfimpointcount + 1;
        ImagePoints(kfimpointcount) = ImagePoint;
    end
end






end