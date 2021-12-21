%%%% Test various NVS models

clear;clc;

addpath(genpath('../modeling'));
addpath(genpath('../aux'));
addpath(genpath('../io'));

%%  read-in video

nrows = 512;
ncols = 512;
videoFile = '../../../../spike_proc/data/video/simp_ball/simp_ball_4.mp4';

brightness_ratio = 1;
numframes = 45;
input_vid = brightness_ratio * readVideo_rs( videoFile, nrows, ncols, numframes, 1 );

%% Parameterize model 

params.frame_show                       = 1;

params.enable_shot_noise                = 0;

params.time_step                        = 10;

params.leak_ba_rate                     = 0.5;

params.percent_threshold_variance       = 2.5;

params.threshold(:,:,1)                 =   112 *ones(size(input_vid(:,:,1)));
params.threshold(:,:,2)                 =   20 *ones(size(input_vid(:,:,1)));
params.threshold(:,:,3)                 =   20 *ones(size(input_vid(:,:,1)));

params.bc_offset                        = 4;
params.bc_leak                          = 0;
params.gc_reset_value                   = 0;
params.gc_refractory_period             = 0;
params.oms_reset_value                  = 3;
params.oms_refractory_period            = 0;
params.dbg_mode                         = 'photo';
params.opl_time_constant                = 0.3;
params.hpf_gc_tc                        = 1.0;
params.hpf_wac_tc                       = 0.4;

params.enable_sequentialOMS             = 0;


%% Run Model 
clc;

[TD, eventFrames, dbgFrames, OMSNeuron] = StNvsModel(input_vid, params);

%% figures
if (params.frame_show == 1)
    fig = figure();
    
    fig.Units = 'normalize';
    fig.Position=[0.1 0.25 0.8 0.75];
    
    ax(1)=axes;
    ax(2)=axes;
    
    x0=0.15;
    y0=0.3;
    dx=0.25;
    dy=0.45;
    ax(1).Position=[x0 y0 dx dy];
    x0 = x0 + dx + 0.2;
    ax(2).Position=[x0 y0 dx dy];
    
    im(1) = imagesc(ax(1),dbgFrames(:,:,1));
    ax(1).Title.String = ['Debug: Frame ' num2str(1)];
    set(ax(1), 'xtick', [], 'ytick', []);
    colormap();
    
    im(2) = imagesc(ax(2),eventFrames(:,:,:,1));
    ax(2).Title.String = ['Accumulated Events: Frame ' num2str(1)];
    set(ax(2), 'xtick', [], 'ytick', []);
    
%     v = VideoWriter('../../../../figures/livingroom_walk.avi');
%     open(v);
%     
    for ii = 2:size(dbgFrames,3)
%         fprintf("Frame : %d\n", ii);
        ax(1).Title.String = ['Intensity: Frame ' num2str(ii)];
        ax(2).Title.String = ['Accumulated Events: Frame ' num2str(ii)];
        set(im(1),'cdata',dbgFrames(:,:,ii));
        set(im(2),'cdata',eventFrames(:,:,:,ii));
        frame = getframe();
        colorbar(ax(1));

        pause(1/60);
    end
    close(v);
end
