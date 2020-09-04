function  batchDir_LED_tracking(videosFolder,saveFolder) 
% this snnipet can wrap around batch_process but i gave it a seperate
% script. sue me... 

% This thing just goes thru the folders that contain the videos locally and unleashes batch_process on them, then saves. 
% INPUTS: 
% videosFolder: a folder that containes a few folders. Each seperate folder has only mp4 files of the moveis from social of one day. like 08062020... etc ... 
% saveFolder: the destination folder to save stuff to. should be on the server if possible 
% %LEDtrackingParams: the parameters used in the model. 
%OUTPUT: 
% It saves the workspace you get from the prediction to saveFolder, what else do you want?

load('LEDtrackingParams.mat');
folders = dir(videosFolder);
folders = folders(3:end); % get rid of 'wildcard' entries, idk what they are fuck'em 


for i = 1:size(folders,1)
videoDir = [folders(i).folder,'\',folders(i).name]; 
[centroidLocs, predColors, props, predPosterior, predLab, t2] = batch_process_LED_tracking(videoDir,LEDtrackingParams);
fname = [saveFolder,'\LEDtracking_pred_social_',folders(i).name];
save(fname) 
end 
