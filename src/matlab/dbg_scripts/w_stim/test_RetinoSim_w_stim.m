%%%% Test various NVS models

clear;clc;

addpath(genpath('../modeling'));
addpath(genpath('../aux'));
addpath(genpath('../io'));

%%  Generate Stim

hsf = 0.01; % 1/512 fundamental frequencies to allow for full resolvement of the frequency
vsf = 0;
htf = 0.03;
vtf = 0;
hamp = 1;
vamp = 1;
write = false;
numFrames = 80-1;
dims = [1 1024];

vPath = '/home/jonahs/projects/ReImagine/AER_Data/model_stim/hsf_0_vsf_4_htf_2_vtf_0_hamp_255_vamp_255.avi';

frames = CreateStimulus(hsf, vsf, htf, vtf, hamp, vamp, write, vPath, numFrames, dims) + 1;

%% Parameterize model 

params.frame_show                       = 1;

params.enable_shot_noise                = 0;

params.time_step                        = 10;

params.leak_ba_rate                     = 2.0;

params.percent_threshold_variance       = 0;

params.threshold(:,:,1)                 =   112 *ones(size(frames(:,:,1))); % BC thresholds
params.threshold(:,:,2)                 =   20 *ones(size(frames(:,:,1))); % ON thresholds
params.threshold(:,:,3)                 =   20 *ones(size(frames(:,:,1))); % OFF thresholds

params.spatial_fe_mode                  = "bandpass";
params.bc_offset                        = 0;
params.bc_leak                          = 0;
params.gc_reset_value                   = 0;
params.gc_refractory_period             = 0;
params.oms_reset_value                  = 3;
params.oms_refractory_period            = 0;
params.dbg_mode                         = 'opl_str';
params.opl_time_constant                = 0.7;
params.hpf_gc_tc                        = 1.0;
params.hpf_wac_tc                       = 0.4;
params.resample_threshold               = 0;
params.rng_settings                     = 0;
params.enable_sequentialOMS             = 0;


%% Run Model 
clc;
[TD, eventFrames, dbgFrames, OMSNeuron] = RetinoSim(frames, params);

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
end
