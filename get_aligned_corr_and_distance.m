function [r,d,video_t_rs,lfp_fs,batPairs] = get_aligned_corr_and_distance(expDate,baseDir,remote_base_dir)

exp_date_str = datestr(expDate,'yyyymmdd');
lfpFnames = dir(fullfile(baseDir,'lfp_data',['*' exp_date_str '_all_session_lfp_results.mat']));
for k = 1:length(lfpFnames)
    all_session_lfp_power(k) = load(fullfile(lfpFnames(k).folder,lfpFnames(k).name));
end

exp_date_str = datestr(expDate,'mmddyyyy');
videoDir = fullfile(remote_base_dir,exp_date_str,'video','social','color');
s = load(fullfile(videoDir,'color_frame_timestamps_info.mat'));
frame_ts_info = s.frame_ts_info;

LEDTracks = load(fullfile(baseDir,'LED_tracking',['LEDtracking_pred_social_' exp_date_str '.mat']));
s = load('color_pred_model_august.mat');
color_pred_model = s.color_pred_model_august;
pred_centroids = get_pred_centroids(LEDTracks,color_pred_model);
videoData = struct('file_frame_number',LEDTracks.file_frame_number,'fileIdx',LEDTracks.fileIdx,'videoData',pred_centroids);
[lfp_interp, frame_data_rs, video_t_rs, lfp_fs] = get_aligned_lfp_frame_data(videoData,frame_ts_info,all_session_lfp_power);

model_colors = color_pred_model.ClassificationSVM.ClassNames;

T = get_rec_logs;
T = T(T.Date == expDate & strcmp(T.Session,'social'),:);

bat_idx = contains(T.Properties.VariableNames,'Bat_');
color_idx = contains(T.Properties.VariableNames,'Color_');
bat_color_table = table(T{1,bat_idx}',T{1,color_idx}','VariableNames',{'batNum','color'});

batPairs = nchoosek({all_session_lfp_power.batNum},2);
n_bat_pair = size(batPairs,1);
nSample = size(frame_data_rs,1);

[r,d] = deal(zeros(n_bat_pair,nSample));


for bat_pair_k = 1:size(batPairs,1)
    lfp_bat_idx = zeros(1,2);
    for bat_k = 1:2
        lfp_bat_idx(bat_k) = find(strcmp({all_session_lfp_power.batNum},batPairs{bat_pair_k,bat_k}));
    end
    
    current_lfp_data =  [nanmedian(lfp_interp{lfp_bat_idx(1)},1);nanmedian(lfp_interp{lfp_bat_idx(2)},1)]';
    current_lfp_data = smoothdata(current_lfp_data,'movmean',100);
    centroid_bat_idx = zeros(1,2);
    for bat_k = 1:2
        color_idx = str2double(batPairs{bat_pair_k,bat_k}) == bat_color_table.batNum;
        centroid_bat_idx(bat_k) = find(strcmp(bat_color_table.color(color_idx),model_colors));
    end
    
    r(bat_pair_k,:) = movCorr(current_lfp_data(:,1),current_lfp_data(:,2),500,0);
    d(bat_pair_k,:) = smoothdata(vecnorm(diff(frame_data_rs(:,:,centroid_bat_idx),[],3)'),100);
end

end