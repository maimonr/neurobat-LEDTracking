function plot_sample_tracking_mov(pd,frameIdx,exp_date_str,varargin)
% pd is the relevant position data object and frameIdx is the frame number
% that the movie will be centered on +/- tOffset seconds

pnames = {'sessionType','groupStr','annotationRadius','useOverlay','tOffset','saveMovie'};
dflts  = {'social','',8,false,1,false};
[sessionType,groupStr,annotationRadius,useOverlay,tOffset,saveMovie] = internal.stats.parseArgs(pnames,dflts,varargin{:});

if ~isempty(groupStr)
    groupNum = groupStr(1);
else
    groupNum = '';
end
batNums = reshape(setdiff(pd.all_bat_nums,pd.exclBats),1,[]);

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

switch pd.expType
    case 'adult_social'
        ROI_rot = load('ROI_rot_adult_social.mat');
        fisheyeModel = load('fisheye_model_adult_social.mat');
    case 'sst'
        ROI_rot = load('ROI_rot_sst.mat');
        fisheyeModel = load('fisheye_model_sst.mat');
end

trackingDir = fullfile(pd.serverPath,'tracking_data');
videoDir = fullfile(pd.serverPath,exp_date_str,'video',[sessionType groupNum],'color');
led_tracks_fname = fullfile(trackingDir,['LEDtracking_pred_' [sessionType groupStr] '_' exp_date_str '.mat']);

LEDTracks = load(led_tracks_fname, 'fileIdx','file_frame_number','video_fNames');

file_k = LEDTracks.fileIdx(frameIdx);
v = VideoReader(fullfile(videoDir,LEDTracks.video_fNames(file_k).name));
center_frame_k = LEDTracks.file_frame_number(frameIdx);

frameOffset = round(v.FrameRate * tOffset);

frames = read(v,[max(1,center_frame_k-frameOffset)...
    min(v.NumFrames,center_frame_k+frameOffset-1)]);
nFrames = size(frames,4);

if useOverlay
    video_data_dir = fullfile(pd.serverPath,'video_data');
    videoDir_IR = fullfile(pd.serverPath,exp_date_str,'video',[sessionType groupNum],'infrared');
    overlayObjs = load('Regist_IR2color_objects_8132020','Rfixed','t');
    
    frame_ts_fname_color = fullfile(video_data_dir,...
        [exp_date_str '_color_frame_timestamps_info_' sessionType groupStr '.mat']);
    frame_ts_fname_infrared = strrep(frame_ts_fname_color,'color','infrared');
    
    frame_ts_color = load(frame_ts_fname_color); frame_ts_color = frame_ts_color.frame_ts_info;
    frame_ts_infrared = load(frame_ts_fname_infrared); frame_ts_infrared = frame_ts_infrared.frame_ts_info;
    
    center_frame_time = frame_ts_color.timestamps(frame_ts_color.fileIdx == file_k &...
        frame_ts_color.file_frame_number == center_frame_k);
    
    [~,infrared_frame_idx] = min(abs(frame_ts_infrared.timestamps - center_frame_time));
    
    file_k = frame_ts_infrared.fileIdx(infrared_frame_idx);
    center_frame_k_IR = frame_ts_infrared.file_frame_number(infrared_frame_idx+1);
    
    [~,fname,ext] = fileparts(frame_ts_infrared.videoFNames{file_k});
    video_IR_fname = fullfile(videoDir_IR,[fname ext]);
    vIR = VideoReader(video_IR_fname);
    frameOffset = round(vIR.FrameRate * tOffset);
    
    framesIR = read(vIR,[max(1,center_frame_k_IR-frameOffset)...
        min(vIR.NumFrames,center_frame_k_IR+frameOffset-1)]);
    
    if round(vIR.FrameRate) > round(v.FrameRate)
        n_ir_frames = size(framesIR,4);
        subsampleIdx = round(linspace(1,n_ir_frames,nFrames));
        framesIR = framesIR(:,:,:,subsampleIdx);
    end
    framesIR = squeeze(framesIR(:,:,1,:));
    imSize(1,:) = size(frames,[1 2]);
    imSize(2,:) = size(framesIR,[1 2]);
    imSize = max(imSize);
    overlaid_video_data = zeros(imSize(1),imSize(2),3,nFrames,'uint8');
    for frame_k = 1:nFrames
        coRegFrame = imwarp(framesIR(:,:,frame_k),overlayObjs.t,'OutputView',overlayObjs.Rfixed);
        coRegFrame = imadjust(coRegFrame,[0 0.9],[0 0.5]);
        overlayFrame = frames(:,:,:,frame_k);
        overlaid_video_data(:,:,:,frame_k) = imadjust((repmat(coRegFrame,1,1,3) + overlayFrame)/2,[0 0.4]);
    end
    frames = overlaid_video_data;
end
imH = image(frames(:,:,:,1));
ylim(ROI_rot.ylims+[0 100])
xlim(ROI_rot.xlims+[0 100])
axis square
%%
if saveMovie
    saveDir = 'C:\Users\tobias\Documents\local_analysis_dir\';
    [~,fname,ext] = fileparts(LEDTracks.video_fNames(file_k).name);
    vWrite = VideoWriter(fullfile(saveDir,[fname '_sample' ext]),'MPEG-4');
    cropIdx = {round(ROI_rot.ylims+[0 100]),round(ROI_rot.xlims+[0 100])};
    vWrite.FrameRate = v.FrameRate;
    vWrite.Quality = 90;
    open(vWrite);
end
for frame_k = 1:nFrames
    currentFrame = undistortFisheyeImage(frames(:,:,:,frame_k), fisheyeModel.cameraParams.Intrinsics);
    
    for batNum = batNums
        batPos = currentPos(batNum);
        currentLoc = pd.pos2loc(batPos(frameIdx-frameOffset+frame_k+1,:),ROI_rot);
        if ~any(isnan(currentLoc))
            colorStr = bat_color_table(batNum);
            batColor = 256*color_name_table(colorStr);
            currentFrame = insertObjectAnnotation(currentFrame,'circle',[currentLoc annotationRadius],...
                batNum,'Color',batColor,'TextBoxOpacity',0,'TextColor',batColor);
        end
    end
    currentFrame = imrotate(currentFrame,-ROI_rot.deg,'bilinear');
    imH.CData = currentFrame;
    if saveMovie
       writeVideo(vWrite,currentFrame(cropIdx{1}(1):cropIdx{1}(2),cropIdx{2}(1):cropIdx{2}(2),:,:)); 
    end
    pause(0.05)
end

if saveMovie
    close(vWrite)
end

end