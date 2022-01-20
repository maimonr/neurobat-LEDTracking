function plot_sample_tracking_mov(pd,frameIdx,exp_date_str,varargin)
% pd is the relevant position data object and frameIdx is the frame number
% that the movie will be centered on +/- tOffset seconds

pnames = {'sessionType','groupStr','annotationRadius','useOverlay','tOffset',...
    'saveMovie','annotationType','yOffset','xOffset','videoFnames','trackDuration',...
    'imRot'};
dflts  = {'social','',8,false,[1 1],...
    false,'circle',[0 0],[0 0],{},2,...
    []};
[sessionType,groupStr,annotationRadius,useOverlay,tOffset,...
    saveMovie,annotationType,yOffset,xOffset,videoFnames,trackDuration,...
    imRot] = internal.stats.parseArgs(pnames,dflts,varargin{:});

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
        colorKeys = {'re','or','ch','gr',...
            'sp','az','bl','vi','rd'};
        colorValues = {[1 0.2 0.2], [0.8 0.6 0], [0.6 0.8 0], [0.2 1 0.2],...
            [0 0.8 0.6], [0 0.6 0.8], [0.2 0.2 1], [0.6 0 0.8], [1 0 0]};
end

[bat_color_table,~,ROI_rot] = pd.get_rec_day_info(exp_date_str);
color_scheme_version = unique(cellfun(@(x) x(end),bat_color_table.color,'un',0));
colorKeys = cellfun(@(ck) [ck color_scheme_version{1}],colorKeys,'un',0);

colorValues = cellfun(@(rgb) rgb,colorValues,'un',0);
color_name_table = containers.Map(colorKeys,colorValues);

currentPos = pd.batPos(exp_date_str);
bat_color_table = containers.Map(bat_color_table.batNum,bat_color_table.color);

switch pd.expType
    case 'adult_social'
        fisheyeModel = load('fisheye_model_adult_social.mat');
    case 'sst'
        fisheyeModel = load('fisheye_model_sst.mat');
end

if isempty(imRot)
    imRot = ROI_rot.deg;
end

trackingDir = fullfile(pd.serverPath,'tracking_data');
videoDir = fullfile(pd.serverPath,exp_date_str,'video',[sessionType groupNum],'color');
led_tracks_fname = fullfile(trackingDir,['LEDtracking_pred_' [sessionType groupStr] '_' exp_date_str '.mat']);

LEDTracks = load(led_tracks_fname, 'fileIdx','file_frame_number','video_fNames');

if isempty(videoFnames)
    file_k = LEDTracks.fileIdx(frameIdx);
    videoFnames{1} = fullfile(videoDir,LEDTracks.video_fNames(file_k).name);
    center_frame_k = LEDTracks.file_frame_number(frameIdx);
else
    [~,fname] = fileparts(videoFnames{1});
    file_k = find(contains({LEDTracks.video_fNames.name},fname));
    center_frame_k = frameIdx;
    frameIdx = find(LEDTracks.file_frame_number == frameIdx & LEDTracks.fileIdx == file_k);
end

v = VideoReader(videoFnames{1});

frameOffset_color = round(v.FrameRate .* tOffset);

totalFrames = round(v.Duration*v.FrameRate);

frames = read(v,[max(1,center_frame_k-frameOffset_color(1))...
    min(totalFrames,center_frame_k+frameOffset_color(2)-1)]);
nFrames = size(frames,4);
%%

if useOverlay
    video_data_dir = fullfile(pd.serverPath,'video_data');
    videoDir_IR = fullfile(pd.serverPath,exp_date_str,'video',[sessionType groupNum],'infrared');
    overlayObjs = load('Regist_IR2color_sst','Rfixed','tAff');
    
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
    
    if length(videoFnames) < 2
        [~,fname,ext] = fileparts(frame_ts_infrared.videoFNames{file_k});
        videoFnames{2} = fullfile(videoDir_IR,[fname ext]);
    end
    vIR = VideoReader(videoFnames{2});
    
    frameOffset_IR = round(vIR.FrameRate .* tOffset);
    
    totalFrames = round(vIR.Duration*vIR.FrameRate);
    framesIR = read(vIR,[max(1,center_frame_k_IR-frameOffset_IR(1))...
        min(totalFrames,center_frame_k_IR+frameOffset_IR(2)-1)]);
    
    if round(vIR.FrameRate) > round(v.FrameRate)
        n_ir_frames = size(framesIR,4);
        subsampleIdx = round(linspace(1,n_ir_frames,nFrames));
        framesIR = framesIR(:,:,:,subsampleIdx);
    end
    framesIR = squeeze(framesIR(:,:,1,:));
    imSize = overlayObjs.Rfixed.ImageSize;
    overlaid_video_data = zeros(imSize(1),imSize(2),3,nFrames,'uint8');
    for frame_k = 1:nFrames
        coRegFrame = imwarp(framesIR(:,:,frame_k),overlayObjs.tAff,'OutputView',overlayObjs.Rfixed);
        overlayFrame = 2*frames(:,:,:,frame_k);
        overlaid_video_data(:,:,:,frame_k) = imadjust((repmat(coRegFrame,1,1,3) + overlayFrame)/2,[0.03 0.4]);
    end
    frames = overlaid_video_data;
end
imH = image(frames(:,:,:,1));
ylim(ROI_rot.ylims+yOffset)
xlim(ROI_rot.xlims+xOffset)
axis square
%%
if saveMovie
    saveDir = 'C:\Users\tobias\Documents\local_analysis_dir\';
    [~,fname,ext] = fileparts(LEDTracks.video_fNames(file_k).name);
    vWrite = VideoWriter(fullfile(saveDir,[fname '_sample' ext]),'MPEG-4');
    cropIdx = {round(ROI_rot.ylims+yOffset),round(ROI_rot.xlims+xOffset)};
    vWrite.FrameRate = v.FrameRate;
    vWrite.Quality = 90;
    open(vWrite);
end
for frame_k = 1:nFrames
    currentFrame = undistortFisheyeImage(frames(:,:,:,frame_k), fisheyeModel.cameraParams.Intrinsics);
    bat_k = 1;
    for batNum = batNums
        batPos = currentPos(batNum);
        
        current_frame_idx = frameIdx-frameOffset_color(1)+frame_k+1;
        if strcmp(annotationType,'tracks')
            trackLength = round(v.FrameRate*trackDuration);
            current_frame_idx = max(frameIdx-frameOffset_color(1)+1, current_frame_idx-trackLength):current_frame_idx;
        end
        
        currentLoc = pd.pos2loc(batPos(current_frame_idx,:),ROI_rot);
        if ~all(isnan(currentLoc),'all')
            currentLoc(isnan(currentLoc)) = -10;
            colorStr = bat_color_table(batNum);
            batColor = 256*color_name_table(colorStr);
            switch annotationType
                case 'numTag'
                    currentFrame = insertObjectAnnotation(currentFrame,'circle',[currentLoc annotationRadius],...
                        num2str(bat_k),'Color',batColor,'TextBoxOpacity',0.75,'TextColor','w');
                case 'batID'
                    currentFrame = insertObjectAnnotation(currentFrame,'circle',[currentLoc annotationRadius],...
                        batNum,'Color',batColor,'TextBoxOpacity',0,'TextColor',batColor);
                case 'circle'
                    currentFrame = insertShape(currentFrame,'circle',[currentLoc annotationRadius],'Color',batColor);
                case 'tracks'
                    currentFrame = insertShape(currentFrame,'circle',[currentLoc repmat(annotationRadius,size(currentLoc,1),1)],'Color',batColor);

            end
        end
        bat_k = bat_k + 1;
    end
    currentFrame = imrotate(currentFrame,imRot,'bilinear');
    imH.CData = currentFrame;
    if saveMovie
        writeVideo(vWrite,currentFrame(cropIdx{1}(1):cropIdx{1}(2),cropIdx{2}(1):cropIdx{2}(2),:,:));
    end
    pause(0.02)
end

if saveMovie
    close(vWrite)
end

end