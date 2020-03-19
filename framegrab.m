function framegrab(v,varargin) % this  funciton takes the frame number and

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

