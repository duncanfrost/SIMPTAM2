function [  ] = displayerror(handles)
%Display the camera external matrices and the error
World = getappdata(handles.figure1,'world');
PTAM = getappdata(handles.figure1,'ptam');
E1 = World.Camera.E;
E1 = round(E1*1000)/1000;
set(handles.text_camext,'String',['World Camera E: ' mat2str(E1)]);

E2 = PTAM.Camera.E;
E2 = round(E2*1000)/1000;
set(handles.text_estcamext,'String',['PTAM Camera E: ' mat2str(E2)]);

camerror = norm(E2 - E1);
set(handles.text_cameraerror,'String',['Camera Error: ' num2str(camerror)]);

if PTAM.kfcount > 1
    totalcamerror = 0;
    for i = 1:PTAM.kfcount
        E1 = World.KeyFrames(i).Camera.E;
        E2 = PTAM.KeyFrames(i).Camera.E;
        totalcamerror = totalcamerror + norm(E1-E2);
    end
    set(handles.text_totalcamerror,'String',['Total Camera Error: ' num2str(totalcamerror)]);
    set(handles.text_numkeyframes,'String',['Number of KeyFrames: ' num2str(PTAM.kfcount )]);
    set(handles.text_averagecamerror,'String',['Average Camera Error: ' num2str(totalcamerror/PTAM.kfcount )]);
end



[error count] = calculateworlderror(World.Map,PTAM.Map);

hist1 = [];
hist2 = [];
for i = 1:size(PTAM.Map.points,2)
    hist1 = [hist1  PTAM.Map.points(i).id];
end

for i = 1:size(World.Map.points,2)
    hist2 = [hist2  World.Map.points(i).id];
end


estcount = size(PTAM.Map.points,2);
set(handles.text_totalmaperror,'String',['Total Map Error: ' num2str(error)]);
set(handles.text_gtmappoints,'String',['Number of GT Map Points: ' num2str(count)]);
set(handles.text_estmappoints,'String',['Number of Est Map Points: ' num2str(estcount)]);
set(handles.text_averagemaperror,'String',['Average Map Error: ' num2str(error/count)]);

% handles.output = error;

end

