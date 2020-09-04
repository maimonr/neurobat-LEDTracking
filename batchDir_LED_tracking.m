function  batchDir_LED_tracking(VideoFolders,saveFolder) 

folders = dir(VideoFolders);
folders = folders(3:end); % get rid of wildcard entries 

for i = 1:size(folders,1)
videoDir = [folders(i).folder,'\',folders(i).name]; 
[centroidLocs, predColors, props, predPosterior, predLab, t2] = batch_process_LED_tracking(videoDir)
fname = [saveFolder,'\LEDtracking_pred_social_',folders(i).name]; % make sure that this is mapped 
save(fname) 
end 

