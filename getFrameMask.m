function bw = getFrameMask(f,varargin)

pnames = {'hsvLims','frameIdx','fixed_thresh','strel_radius'};
dflts  = {[],[],0.1,10};
[hsvLims,frameIdx,fixed_thresh,strel_radius] = internal.stats.parseArgs(pnames,dflts,varargin{:});

if isempty(frameIdx)
   frameIdx = [1 size(f,1) 1 size(f,2)]; 
end

f = f(frameIdx(1):frameIdx(2),frameIdx(3):frameIdx(4),:);

if isempty(hsvLims)
    f = rgb2gray(f);
    if isa(f,'uint8')
        thresh = fixed_thresh*(2^8);
    else
        thresh = fixed_thresh*range(f(:));
    end
    bw = f > thresh;
else
    bw = createMaskFilter(f,hsvLims);
end

SE = strel('disk',strel_radius);
bw = imclose(bw,SE);

end