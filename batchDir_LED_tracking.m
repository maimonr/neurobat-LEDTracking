function  batchDir_LED_tracking(baseDir,saveFolder,localDir,sessionType,expDates)

LEDtrackingParams = load('LEDtrackingParams.mat');

s = load('color_pred_model_august.mat');
color_pred_model = s.color_pred_model_august;

fisheyeModel = load('fisheye_model.mat');
cameraParams = fisheyeModel.cameraParams; % not needed, but...

for exp_k = 1:length(expDates)
    exp_date_str = datestr(expDates(exp_k),'mmddyyyy');
    remote_video_dir = fullfile(baseDir,exp_date_str,'video',sessionType,'color','*.mp4');
    local_video_dir = fullfile(localDir,exp_date_str);
    [status,copy_err_msg] = remote_copy(remote_video_dir,local_video_dir);
    if ~status
       disp(copy_err_msg)
       keyboard
    end
    
    LEDTracks = batch_process_LED_tracking(local_video_dir,LEDtrackingParams,cameraParams,color_pred_model,sessionType);
    
    outFname = fullfile(saveFolder,strjoin({'LEDtracking_pred',sessionType,exp_date_str},'_'));
    save(outFname,'-struct','LEDTracks')
    [rmdir_status, rmdir_err_msg] = rmdir(local_video_dir,'s');
    if ~rmdir_status
        disp(rmdir_err_msg)
        keyboard
    end
end

end


function [status,copy_err_msg] = remote_copy(remoteDir,localDir)

status = false;
copy_err_msg = [];

TicTransfer = tic;

while ~status && toc(TicTransfer)<30*60
    [status,copy_err_msg] = copyfile(remoteDir,localDir,'f');
end


if ~status
    disp('Failed to copy folder TO server after 30 minutes')
    disp(copy_err_msg)
    keyboard
end

end