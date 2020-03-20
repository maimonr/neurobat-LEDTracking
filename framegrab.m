function framegrab(v,varargin) 
% function to send to videofig that determines the regions in an image and
% plots them along with their centroids.
% INPUTS: 
% v: videoReader of the video of interest
% hsvLims: a 3 x 2 matrix defining the lower (first column) and upper
% (second column) bounds for each of the 3 channels in HSV color that
% determines what is included in the mask
% frameNum: the desired frame number (or leave empty to read the next
% frame)
% plot_mean_cent: flag for whether to plot the mean of all centroids
% plot_biggest_centroid: flag for whether to plot the biggest centroid

pnames = {'hsvLims','frameNum','plot_mean_cent','plot_biggest_cent'};
dflts  = {[],[],true,true};
[hsvLims,frameNum,plot_mean_cent,plot_biggest_cent] = internal.stats.parseArgs(pnames,dflts,varargin{:});

if ~isempty(frameNum)
    f = read(v,frameNum);
else
    f = readFrame(v);
end

ROIIdx = [1 1000 1 1380];

bw = getFrameMask(f,'hsvLims',hsvLims,'frameIdx',ROIIdx);
[centroidLocs, Props] = findLEDcentroid(bw);

[~, indexmax]  = max(vertcat(Props.Area)); % store areas of centroides 
bigestCentroid = centroidLocs(indexmax,:);
meanCentroid = mean(centroidLocs,1);

image(f);

if ~isempty(centroidLocs)
    axis on ; hold on; plot(centroidLocs(:,1), centroidLocs(:,2), 'w*','MarkerSize', 10,'DisplayName',num2str(size(centroidLocs,1))); hold off
end

if ~isempty(bigestCentroid) && plot_mean_cent
    axis on ; hold on; plot(bigestCentroid(1,1), bigestCentroid(1,2), 'wo','MarkerSize', 18); hold off
end

if ~isempty(meanCentroid) && plot_biggest_cent
    axis on ; hold on; plot(meanCentroid(1,1), meanCentroid(1,2), 'wd','MarkerSize', 15); hold off
end

end

