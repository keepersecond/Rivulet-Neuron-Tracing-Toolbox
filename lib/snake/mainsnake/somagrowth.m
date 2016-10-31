function soma = somagrowth(inivcheck, somathres, showthres, plotcheck, ax, imgsoma, center, sqradius, smoothing, lambda1, lambda2, stepnum)
	% The following kernel is used for the SI and IS operation 
	global P3
	P2kernel = ones(3);
	P2kernel(:,1) = 0;
	P2kernel(:,3) = 0;
	P3kernel(:,:,1) = P2kernel; 
	P3kernel(:,:,2) = P2kernel; 
	P3kernel(:,:,3) = P2kernel; 
	P3{1} = P3kernel;
	P2kernel = P2kernel';
	P3kernel(:,:,1) = P2kernel; 
	P3kernel(:,:,2) = P2kernel; 
	P3kernel(:,:,3) = P2kernel; 
	P3{2} = P3kernel;
	P3kernel = zeros(3, 3, 3);
	P3kernel(:,:,2) = ones(3, 3);
	P3{3} = P3kernel;
	P2kernel = eye(3);
	P3kernel(:,:,1) = P2kernel; 
	P3kernel(:,:,2) = P2kernel; 
	P3kernel(:,:,3) = P2kernel; 
	P3{4} = P3kernel;
	P2kernel = flipud(eye(3));
	P3kernel(:,:,1) = P2kernel; 
	P3kernel(:,:,2) = P2kernel; 
	P3kernel(:,:,3) = P2kernel; 
	P3{5} = P3kernel;
	P3kernel = zeros(3, 3, 3);
	P3kernel(:, 1, 1) = 1;
	P3kernel(:, 2, 2) = 1;
	P3kernel(:, 3, 3) = 1;
	P3{6} = P3kernel;
	P3kernel = zeros(3, 3, 3);
	P3kernel(:, 3, 1) = 1;
	P3kernel(:, 2, 2) = 1;
	P3kernel(:, 1, 3) = 1;
	P3{7} = P3kernel;
	P3kernel = zeros(3, 3, 3);
	P3kernel(1, :, 1) = 1;
	P3kernel(2, :, 2) = 1;
	P3kernel(3, :, 3) = 1;
	P3{8} = P3kernel;
	P3kernel = zeros(3, 3, 3);
	P3kernel(3, :, 1) = 1;
	P3kernel(2, :, 2) = 1;
	P3kernel(1, :, 3) = 1;
	P3{9} = P3kernel;
	startpoint = zeros(1, 3);
	startpoint = center - 3 * sqradius;
	% disp(startpoint);
    endpoint = zeros(1, 3);
	endpoint = center + 3 * sqradius;
	% disp(endpoint);
	shape = size(imgsoma);
	startpoint(1) = constrain(startpoint(1), 1, shape(1));
	startpoint(2) = constrain(startpoint(2), 1, shape(2));
	startpoint(3) = constrain(startpoint(3), 1, shape(3));
	endpoint(1) = constrain(endpoint(1), 1, shape(1));
	endpoint(2) = constrain(endpoint(2), 1, shape(2));
	endpoint(3) = constrain(endpoint(3), 1, shape(3));
	% Fix the warning : Integer operands are required for colon operator when used as index
	startpoint = round(startpoint);
	endpoint = round(endpoint);
	% fprintf('The soma region is defined as: x from %i to %i; y from %i to %i; z from %i to %i;\n', startpoint(1), endpoint(1), startpoint(2), endpoint(2), startpoint(3), endpoint(3));
	oriI = imgsoma;
	imgsoma = imgsoma(startpoint(1):endpoint(1), startpoint(2):endpoint(2), startpoint(3):endpoint(3));
	shape = size(imgsoma);
	oldcenter = center;
	center = shape/2;
	center = floor(center);
	% Basically it creates a logical disk with true elements inside and false elements outside
	u = circlelevelset3d(shape, center, sqradius);
	% fprintf('The estimation of sqradius is %2.2f\n', sqradius);
	threshold = 0.5;
	MorphGAC = ACWEinitialise(double(imgsoma), smoothing, lambda1, lambda2);
	% the threshold is just for visulisation
	% u is the snake mask which will evolve according to level set equation
    if inivcheck
        iniu = somaini_v_quick(double(imgsoma), somathres);
        MorphGAC.u = iniu > 0.5;
    else
        MorphGAC.u = u;
    end
	% disp(stepnum)
	% figure
	if plotcheck
		if(~isempty(ax))
			axes(ax);
			% hold on;
		end
	end
	% The following vector is used for storing values of counting the number of foreground voxels  
	foreground_num = [];
	% The following vector is initialised for storing forward difference
	forward_diff_store = [];
	% This is the initialization of sliding window with length of 5
	slider_diff = [];
	for i = 1 : stepnum
		fprintf('The current step number is %i\n', i);
		MorphGAC = ACWEstep3d(MorphGAC, i);		
		A = MorphGAC.u > threshold;  % synthetic data
		foreground_num(end+1) = sum(A(:));
		% The following code tries to calculate the first order difference of foreground_num
		if numel(foreground_num) > 2
			diff_step=foreground_num(end)-foreground_num(end-1);
			forward_diff_store(end+1)=diff_step;
			if numel(forward_diff_store) > 5
				cur_slider_diff = sum(forward_diff_store(end-5:end));
				% fprintf('The current value of cur_slider_diff%3.2f\n', cur_slider_diff);
				if abs(cur_slider_diff) < 20 || abs(cur_slider_diff) < (0.06*foreground_num(end))
					% save('/home/donghao/Desktop/somadata/converged/slider_diff.mat', 'slider_diff');
					% save('/home/donghao/Desktop/somadata/converged/forward_diff_store.mat', 'forward_diff_store');
					% save('/home/donghao/Desktop/somadata/converged/foreground_num.mat', 'foreground_num');
					converged_ratio = abs(cur_slider_diff) / (0.1*foreground_num(end));
					fprintf('The current converged_ratio is %3.2f\n', converged_ratio);
					break;
				end	
				slider_diff(end+1) = cur_slider_diff; 
			end
			% if i == stepnum
			% 	save('/home/donghao/Desktop/somadata/converged/slider_diff.mat', 'slider_diff');
			% 	save('/home/donghao/Desktop/somadata/converged/forward_diff_store.mat', 'forward_diff_store');
			% 	save('/home/donghao/Desktop/somadata/converged/foreground_num.mat', 'foreground_num');
			% end
		end  
		[x y z] = ind2sub(size(A), find(A));
		x = x + startpoint(1);
		y = y + startpoint(2);
		z = z + startpoint(3);
		if plotcheck
			% cla(ax);
			hold on
            safeshowbox(oriI, showthres);
		end
		if plotcheck
			plot3(y, x, z, 'b.');
            axis equal
			hold off
            
			% axis([0 shape(2) 0 shape(1) 0 shape(3)])
			drawnow
		end
	end

	ini_vol = sum(MorphGAC.u(:));
	for i = 1 : MorphGAC.smoothing
		A = curvop3d(MorphGAC.u, P3, 1);
		% vol_pct is the percent compared to the initial volume compared to  
		vol_pct = sum(A(:)) / ini_vol;
		% Try to use sliding windows method to detect the converged smoothing
		foreground_num(end+1) = sum(A(:));
		diff_step=foreground_num(end)-foreground_num(end-1);
		forward_diff_store(end+1)=diff_step;
		cur_slider_diff = sum(forward_diff_store(end-5:end));
		slider_diff(end+1) = cur_slider_diff;
		% fprintf('The size of current sliding window method is %4.1f\n', cur_slider_diff);  
		if vol_pct < 0.85
			break;
		end 
		foreground_num(end+1) = sum(A(:));
		% fprintf('The current soma volume is %4.1f\n', foreground_num(end));
		MorphGAC.u = A;
	end

	% close
	% disp(class(MorphGAC.u));
	% The following code extracts the volume of each face of somatic region 
	A = MorphGAC.u > threshold;
	somaslice = A(1,:,:);
	somaslice = squeeze(somaslice);
    sliceval(1) = sum(somaslice(:));
    
    somaslice = A(end,:,:);
	somaslice = squeeze(somaslice); 	
    sliceval(2) = sum(somaslice(:));
    
    somaslice = A(:,1,:);
	somaslice = squeeze(somaslice); 	
    sliceval(3) = sum(somaslice(:));
    
    somaslice = A(:,end,:);
    somaslice = squeeze(somaslice);
    sliceval(4) = sum(double(somaslice(:)));
    
    somaslice = A(:,:,1);
    sliceval(5) = sum(somaslice(:));

    somaslice = A(:,:,end);
    sliceval(6) = sum(somaslice(:));
    sz1 = size(somaslice, 1);
	sz2 = size(somaslice, 2);
	sliceptr = sliceval / (sz1 * sz2);
	
	[maxval, maxind] = max(sliceptr)	
	if max(sliceptr) > 0.1
		fprintf('The new bounding box range is beling calculated.\n');
		soma.enlrspt = startpoint;
		soma.enlrept = endpoint;
		switch maxind
			case 1
				soma.enlrspt(1) = soma.enlrspt(1) - (sz1 / 4);
			case 2
				soma.enlrept(1) = soma.enlrept(1) + (sz1 / 4); 
			case 3
				soma.enlrspt(2) = soma.enlrspt(2) - (sz1 / 4);
			case 4
				soma.enlrept(2) = soma.enlrept(2) + (sz1 / 4);
			case 5
				soma.enlrspt(3) = soma.enlrspt(3) - (sz1 / 4);
			case 6
				soma.enlrept(3) = soma.enlrept(3) + (sz1 / 4);
		    otherwise
		        disp('Invalid number is given and code should be checked')
		end
		
		% To constrain new bounding box inside 
		soma.enlrspt(1) = constrain(soma.enlrspt(1), 1, size(oriI, 1));
		soma.enlrspt(2) = constrain(soma.enlrspt(2), 1, size(oriI, 2));
		soma.enlrspt(3) = constrain(soma.enlrspt(3), 1, size(oriI, 3));
		soma.enlrept(1) = constrain(soma.enlrept(1), 1, size(oriI, 1));
		soma.enlrept(2) = constrain(soma.enlrept(2), 1, size(oriI, 2));
		soma.enlrept(3) = constrain(soma.enlrept(3), 1, size(oriI, 3));
		
		% To make sure the indexs of the soma box are integers
		soma.enlrspt = round(soma.enlrspt);
		soma.enlrept = round(soma.enlrept); 
	end
	% fprintf('The volume of somaplane is %5.2f\n', sum(A(:)));
	disp(sliceval);
	fprintf('The volume of somaplane is %5.2f\n', sliceptr);
	backsoma = zeros(size(oriI));
	backsoma(startpoint(1):endpoint(1), startpoint(2):endpoint(2), startpoint(3):endpoint(3)) = MorphGAC.u;
	soma.I = double(backsoma);
	
	% Recalculate soma centre
	somaidx = find(soma.I == 1);
	[x, y, z] = ind2sub(size(soma.I), somaidx);
	soma.x = mean(x);
	soma.y = mean(y);
	soma.z = mean(z);
    soma.startpoint = startpoint;
    soma.endpoint = endpoint;
	% fprintf('The soma centre is recalculated as (%f, %f, %f)', soma.x, soma.y, soma.z);
end
