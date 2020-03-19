
function  [BigestCentroTrace]= framegrab(fnum,v,hsv) % this  funciton takes the frame number and 
f = read(v,fnum);
f = f(1:1000,1:1380,:); 
[bw, mask] = createMaskFilter(f,hsv);
[centroidLocs, BigestCentro, meanCentro] = findLEDcentroid(bw);


image(f); 

if ~isempty(centroidLocs)  
axis on ; hold on; plot(centroidLocs(:,1), centroidLocs(:,2), 'w*','MarkerSize', 10,'DisplayName',num2str(size(centroidLocs,1))); hold off 
  
else
end

if ~isempty(BigestCentro) 
    axis on ; hold on; plot(BigestCentro(1,1), BigestCentro(1,2), 'wo','MarkerSize', 18); hold off 
else
end


if ~isempty(meanCentro)
    axis on ; hold on; plot(meanCentro(1,1), meanCentro(1,2), 'wd','MarkerSize', 15); hold off 
else
end

meanCentro = []; 
BigestCentro = []; 
centroidLocs = []; 

end





