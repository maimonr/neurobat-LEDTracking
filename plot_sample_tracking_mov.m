function plot_sample_tracking_mov(pd,frameIdx,frameOffset)
% pd is the relevant position data object and frameIdx is the frame number
% that the movie will be centered on +/- frameOffset # of frames
exp_date_str = '03102021';
sessionType = 'social';
groupNum = '3';
permLabel = 'a';
groupStr = [groupNum permLabel];
annotationRadius = 8;
batNums = setdiff(pd.all_bat_nums,pd.exclBats)';

switch pd.expType
    case 'adult_social'
        colorKeys = {'rd','gr','or','sp',...
            'az','vi','re','ch'};
        colorValues = {[1, 0, 0],[0, 1, 0],[1, 0.5, 0],[0, 1, 0.5],...
            [0, 0.5, 1],[0.5, 0, 1],[1, 0, 0.5],[0.5, 1, 0]};
    case 'sst'
        colorKeys = {'re2','or2','ch2','gr2',...
            'sp2','az2','bl2','vi2','rd2'};
        colorValues = {[1 0.2 0.2], [0.8 0.6 0], [0.6 0.8 0], [0.2 1 0.2],...
            [0 0.8 0.6], [0 0.6 0.8], [0.2 0.2 1], [0.6 0 0.8], [1 0 0]};
end
colorValues = cellfun(@(rgb) rgb,colorValues,'un',0);
color_name_table = containers.Map(colorKeys,colorValues);

currentPos = pd.batPos(exp_date_str);
bat_color_table = pd.get_bat_color_table(exp_date_str);
bat_color_table = containers.Map(bat_color_table.batNum,bat_color_table.color);

fisheyeModel = load('fisheye_model_sst.mat');
switch pd.expType
    case 'adult_social'
        ROI_rot = load('ROI_rot.mat');
    case 'sst'
        ROI_rot = load('ROI_rot_sst.mat');
end

trackingDir = fullfile(pd.serverPath,'tracking_data');
videoDir = fullfile(pd.serverPath,exp_date_str,'video',[sessionType groupNum],'color');
led_tracks_fname = fullfile(trackingDir,['LEDtracking_pred_' [sessionType groupStr] '_' exp_date_str '.mat']);

LEDTracks = load(led_tracks_fname, 'fileIdx','file_frame_number','video_fNames');

v = VideoReader(fullfile(videoDir,LEDTracks.video_fNames(LEDTracks.fileIdx(frameIdx)).name));
k = LEDTracks.file_frame_number(frameIdx);

frames = read(v,[max(1,k-frameOffset)  min(v.NumFrames,k+frameOffset-1)]);
imH = imagesc(frames(:,:,:,1));
ylim(ROI_rot.ylims+[-25 25])
xlim(ROI_rot.xlims+[-25 25])
axis square

for frame_k = 1:size(frames,4)
    currentFrame = undistortFisheyeImage(frames(:,:,:,frame_k), fisheyeModel.cameraParams.Intrinsics);
    
    for batNum = batNums
        batPos = currentPos(batNum);
        currentLoc = pd.pos2loc(batPos(frameIdx-frameOffset+frame_k+1,:),ROI_rot);
        if ~any(isnan(currentLoc))
            colorStr = bat_color_table(batNum);
            batColor = 256*color_name_table(colorStr);
            currentFrame = insertObjectAnnotation(currentFrame,'circle',[currentLoc annotationRadius],...
                batNum,'Color',batColor,'TextBoxOpacity',0.1);
        end
    end
    imH.CData = currentFrame;
    pause(0.05)
end

end