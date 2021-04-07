function overlay_color_IR_video(fName_color,fName_IR,saveDir,video_data_dir,exp_date_str,varargin)

pnames = {'sessionType','groupStr','expType','frame_search_span','transType'};
dflts  = {'social','','sst',100,'affine'};
[sessionType,groupStr,expType,frame_search_span,coreg_trans_type] = internal.stats.parseArgs(pnames,dflts,varargin{:});

overlayObjs = load(['Regist_color2IR_' expType '.mat']);

switch coreg_trans_type
    case 'affine'
        tform = overlayObjs.tAff;
    case 'projective'
        tform = overlayObjs.tProj;
end

vColor = VideoReader(fName_color);
vIR = VideoReader(fName_IR);

nFrames = vIR.NumFrames;

[~,fName_IR,ext] = fileparts(fName_IR);
fName_overlay = strrep(fName_IR,'_infrared','_overlay');
fName_overlay = fullfile(saveDir,[fName_overlay ext]);
vOverlay = VideoWriter(fName_overlay,'MPEG-4');
vOverlay.FrameRate = vIR.FrameRate;
vOverlay.Quality = 75;
open(vOverlay);

frame_ts_fname_color = fullfile(video_data_dir,...
    [exp_date_str '_color_frame_timestamps_info_' sessionType groupStr '.mat']);
frame_ts_fname_infrared = strrep(frame_ts_fname_color,'color','infrared');

frame_ts_color = load(frame_ts_fname_color); frame_ts_color = frame_ts_color.frame_ts_info;
frame_ts_infrared = load(frame_ts_fname_infrared); frame_ts_infrared = frame_ts_infrared.frame_ts_info;

frame_k_IR = 1;
frame_k_color = 1;
fColor = [];
hWait = waitbar(0,'Processing video');
while frame_k_IR < 100%hasFrame(vIR)
    
    fIR = readFrame(vIR);
%     fIR = fIR(:,:,1);
    if isempty(fColor)
        fColor = read(vColor,frame_k_color);
    end
    
    coRegFrame = imwarp(fColor,tform,'OutputView',overlayObjs.Rfixed);
    fIR = imadjust(fIR,[0 0.9],[0 0.5]);
    
    frameSpan = max(1,frame_k_color - frame_search_span):min(vColor.NumFrames,frame_k_color + frame_search_span);
    
    [~,color_frame_idx] = min(abs(frame_ts_color.timestamps(frameSpan) - frame_ts_infrared.timestamps(frame_k_IR)));
    color_frame_idx = color_frame_idx + frameSpan(1) - 1;
    
    if frame_k_color ~= color_frame_idx
        fColor = read(vColor,color_frame_idx);
        frame_k_color = color_frame_idx;
    end
    
    fOverlay = imadjust((fIR + coRegFrame)/2,[0 0.4]);
    writeVideo(vOverlay,fOverlay)
    waitbar(frame_k_IR/nFrames,hWait);
    frame_k_IR = frame_k_IR + 1;
end

close(vOverlay)
close(hWait);

end