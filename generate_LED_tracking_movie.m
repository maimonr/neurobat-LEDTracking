function generate_LED_tracking_movie(video_fname,pred_centroids,train_centroids_mat,ROIIdx)

if isempty(train_centroids_mat)
    train_centroids_mat = nan(size(pred_centroids));
end
pred_centroids(isnan(pred_centroids)) = 0;
train_centroids_mat(isnan(train_centroids_mat)) = 0;
nFrame = size(pred_centroids,1);
nTrail = 10;
[folder,fname,~] = fileparts(video_fname);
video_out_fname = fullfile(folder,[fname '_tracked']);
circle_size = 10;
rgb_colors = 2^8*[0 0 1; 1 0.5 0; 1 0 0; 1 1 0; 0.5 1 0; 0 1 0; 0 1 0.5; 0 1 1; 0.5 0 1; 1 0 1];
nColor = size(rgb_colors,1);

v = VideoReader(video_fname);
vw = VideoWriter(video_out_fname,'MPEG-4');
vw.Quality = 25;
vw.FrameRate = v.FrameRate;
open(vw);
frame_k = 1;
t = tic;
while hasFrame(v) && frame_k
    f = readFrame(v);
    fGray = rgb2gray(f);
    f(fGray < 0.1*2^8) = 0;
    if frame_k == 1 || frame_k == nFrame
         frame_k = frame_k + 1;
        continue
    end
    for color_k = 1:nColor
        if frame_k < nTrail+1
            f = insertShape(f,'Circle',[squeeze(pred_centroids(1:frame_k,color_k,:)) repmat(circle_size,frame_k,1)],'Color',rgb_colors(color_k,:));
        elseif frame_k >= nFrame-nTrail
            f = insertShape(f,'Circle',[squeeze(pred_centroids(frame_k+1:nFrame,color_k,:)) repmat(circle_size,nFrame-frame_k,1)],'Color',rgb_colors(color_k,:));
        else
            f = insertShape(f,'Circle',[squeeze(pred_centroids(frame_k-nTrail+1:frame_k,color_k,:)) repmat(circle_size,nTrail,1)],'Color',rgb_colors(color_k,:)); 
        end
    end
    f = f(ROIIdx(1):ROIIdx(2),ROIIdx(3):ROIIdx(4),:);
    writeVideo(vw,f);
    frame_k = frame_k + 1;
end
toc(t)
close(vw);

end