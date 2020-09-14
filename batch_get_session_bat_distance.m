function [call_bat_pos_info, all_bat_nums]= batch_get_session_bat_distance(baseDir,sessionType)

T = get_rec_logs;
bat_idx = contains(T.Properties.VariableNames,'Bat_');
all_bat_nums = T{T.Date > datetime(2020,7,22),bat_idx};
all_bat_nums = unique(all_bat_nums);
all_bat_nums = all_bat_nums(~isnan(all_bat_nums));

s = load('color_pred_model_august.mat');
color_pred_model = s.color_pred_model_august;
colorStrs = color_pred_model.ClassificationSVM.ClassNames;

led_tracking_dir = fullfile(baseDir,'tracking_data');
video_data_dir = fullfile(baseDir,'video_data');

led_track_fnames = dir(fullfile(led_tracking_dir,['LEDtracking_pred_' sessionType '*.mat']));
fnameSplit = arrayfun(@(x) strsplit(x.name,'_'),led_track_fnames,'un',0);
exp_date_strs= cellfun(@(x) x{end}(1:end-4),fnameSplit,'un',0);

nExp = length(exp_date_strs);

[session_bat_dist,expDates] = deal(cell(1,nExp));

for exp_k = 1:nExp
    led_track_fname = fullfile(led_track_fnames(exp_k).folder,led_track_fnames(exp_k).name);
    exp_date_str = exp_date_strs{exp_k};
    expDate = datetime(exp_date_str,'InputFormat','MMddyyyy');
    if strcmp(sessionType,'social')
        frame_ts_info_fname = fullfile(video_data_dir,[exp_date_str '_color_frame_timestamps_info_social.mat']);
    else
        frame_ts_info_fname = fullfile(video_data_dir,[exp_date_str '_color_frame_timestamps_inf.mat']);
    end
    
    if isfile(frame_ts_info_fname)
        
        s = load(frame_ts_info_fname);
        frame_ts_info = s.frame_ts_info;
        
        LEDTracks = load(led_track_fname);
        
        session_bat_dist{exp_k} = get_bat_dist(LEDTracks,frame_ts_info,color_pred_model,expDate,T,sessionType,all_bat_nums,colorStrs);
        expDates{exp_k} = expDate;
    end
end

call_bat_pos_info = struct('dist',session_bat_dist,'expDate',expDates);

end

function [batDist,video_timestamps] = get_bat_dist(LEDTracks,frame_ts_info,color_pred_model,expDate,T,sessionType,all_bat_nums,colorStrs)


frame_and_file_table_data = array2table([LEDTracks.file_frame_number;LEDTracks.fileIdx]');
frame_and_file_table_ts = array2table([frame_ts_info.file_frame_number;frame_ts_info.fileIdx]');
[~,idx_data,idx_ts] = intersect(frame_and_file_table_data,frame_and_file_table_ts,'stable');
video_timestamps = frame_ts_info.timestamps_nlg(idx_ts);

pred_centroids = get_pred_centroids(LEDTracks,color_pred_model);
colons = repmat({':'},1,ndims(pred_centroids)-1);
pred_centroids = pred_centroids(idx_data,colons{:});

reordered_bat_pos = reorder_bat_pos(pred_centroids,T,expDate,sessionType,all_bat_nums,colorStrs);

nFrame = size(reordered_bat_pos,1);
nBat = size(reordered_bat_pos,3);
batDist = zeros(nFrame,nBat,nBat);
for k = 1:nFrame
    batDist(k,:,:) = squareform(pdist(squeeze(reordered_bat_pos(k,:,:))'));
end


end