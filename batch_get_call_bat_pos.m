function call_bat_pos_info = batch_get_call_bat_pos(baseDir,sessionType)

T = get_rec_logs;
bat_idx = contains(T.Properties.VariableNames,'Bat_');
all_bat_nums = T{T.Date > datetime(2020,7,22),bat_idx};
all_bat_nums = unique(all_bat_nums);
all_bat_nums = all_bat_nums(~isnan(all_bat_nums));

s = load('color_pred_model_august.mat');
color_pred_model = s.color_pred_model_august;
colorStrs = color_pred_model.ClassificationSVM.ClassNames;
call_offset = [-2 2]*1e3;

call_data_dir = fullfile(baseDir,'call_data');
led_tracking_dir = fullfile(baseDir,'tracking_data');
video_data_dir = fullfile(baseDir,'video_data');

led_track_fnames = dir(fullfile(led_tracking_dir,['LEDtracking_pred_' sessionType '*.mat']));
fnameSplit = arrayfun(@(x) strsplit(x.name,'_'),led_track_fnames,'un',0);
exp_date_strs= cellfun(@(x) x{end}(1:end-4),fnameSplit,'un',0);

nExp = length(exp_date_strs);

[call_bat_pos,callNums,batNums,expDates] = deal(cell(1,nExp));

for exp_k = 1:nExp
    led_track_fname = fullfile(led_track_fnames(exp_k).folder,led_track_fnames(exp_k).name);
    exp_date_str = exp_date_strs{exp_k};
    expDate = datetime(exp_date_str,'InputFormat','MMddyyyy');
    if strcmp(sessionType,'social')
        frame_ts_info_fname = fullfile(video_data_dir,[exp_date_str '_color_frame_timestamps_info_social.mat']);
        cut_call_fname = fullfile(call_data_dir,[datestr(expDate,'yyyymmdd') '_cut_call_data_social.mat']);
    else
        frame_ts_info_fname = fullfile(video_data_dir,[exp_date_str '_color_frame_timestamps_inf.mat']);
        cut_call_fname = fullfile(call_data_dir,[datestr(expDate,'yyyymmdd') '_cut_call_data.mat']);
    end
    
    if isfile(frame_ts_info_fname) && isfile(cut_call_fname)
        
        s = load(frame_ts_info_fname);
        frame_ts_info = s.frame_ts_info;
        
        s = load(cut_call_fname);
        cut_call_data = s.cut_call_data;
        LEDTracks = load(led_track_fname);
        
        current_bat_call_pos = get_call_bat_pos(LEDTracks,frame_ts_info,cut_call_data,call_offset,color_pred_model);
        call_bat_pos{exp_k} = reorder_bat_pos(current_bat_call_pos,T,expDate,sessionType,all_bat_nums,colorStrs);
        
        callNums{exp_k} = [cut_call_data.uniqueID];
        batNums{exp_k} = {cut_call_data.batNum};
        expDates{exp_k} = repmat(expDate,1,length(batNums{exp_k}));
    end
end

all_call_bat_pos = cat(1,call_bat_pos{:});
all_call_bat_pos = num2cell(all_call_bat_pos,[2 3]);
all_call_bat_pos = cellfun(@squeeze,all_call_bat_pos,'un',0)';

all_exp_dates = [expDates{:}];
all_exp_dates = num2cell(all_exp_dates);

all_call_nums = [callNums{:}];
all_call_nums = num2cell(all_call_nums);

all_call_bat_nums = [batNums{:}];

call_bat_pos_info = struct('pos',all_call_bat_pos,'expDate',all_exp_dates,'callNums',all_call_nums,'batNums',all_call_bat_nums);

end

function call_bat_pos = get_call_bat_pos(LEDTracks,frame_ts_info,cut_call_data,call_offset,color_pred_model)


frame_and_file_table_data = array2table([LEDTracks.file_frame_number;LEDTracks.fileIdx]');
frame_and_file_table_ts = array2table([frame_ts_info.file_frame_number;frame_ts_info.fileIdx]');
[~,idx_data,idx_ts] = intersect(frame_and_file_table_data,frame_and_file_table_ts,'stable');
video_timestamps_nlg = frame_ts_info.timestamps_nlg(idx_ts);

pred_centroids = get_pred_centroids(LEDTracks,color_pred_model);
colons = repmat({':'},1,ndims(pred_centroids)-1);
pred_centroids = pred_centroids(idx_data,colons{:});

nBat = size(pred_centroids,3);

nCall = length(cut_call_data);
call_bat_pos = nan(nCall,2,nBat);
for call_k = 1:nCall
    callPos = cut_call_data(call_k).corrected_callpos(1) + call_offset;
    [~,idx] = inRange(video_timestamps_nlg, callPos);
    call_bat_pos(call_k,:,:) = nanmean(pred_centroids(idx,:,:));
end

end

function reordered_call_bat_pos = reorder_bat_pos(call_bat_pos,T,expDate,sessionType,all_bat_nums,colorStrs)

bat_idx = contains(T.Properties.VariableNames,'Bat_');
color_idx = contains(T.Properties.VariableNames,'Color_');

nBats = length(all_bat_nums);
nCall = size(call_bat_pos,1);
reordered_call_bat_pos = nan(nCall,2,nBats);

T_exp = T(T.Date == expDate & strcmp(T.Session,sessionType),:);
bat_color_table = table(T_exp{1,bat_idx}',T_exp{1,color_idx}','VariableNames',{'batNum','color'});

for color_k = 1:length(colorStrs)
    color_bat_num = bat_color_table.batNum(strcmp(colorStrs{color_k},bat_color_table.color));
    current_bat_idx = all_bat_nums == color_bat_num;
    reordered_call_bat_pos(:,:,current_bat_idx) = call_bat_pos(:,:,color_k);
end


end