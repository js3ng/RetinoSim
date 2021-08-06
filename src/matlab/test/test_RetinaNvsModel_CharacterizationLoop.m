%% TEST SCRIPT TO CHARACTERIZE RETINA MODEL USING SIMPLE TEMPORAL STIMULII

clear; clc

%% Create Stimulii 
final_loss.on = [];
final_loss.off = [];

for std = 0.3: +0.01: 0.6
    amacrine_spread.std = std;
    addpath(genpath('../modeling'));
    addpath(genpath('../filters'));
    
    step = "......RUNNING STIMULII.....";
    fprintf("%s\n",step);
    
    sensor_size                         = [128 128];
    intensity_params.starting_level     = 10;
    intensity_params.end_level          = 255;
    intensity_params.number_levels      = 20;
    intensity_params.iterations         = 3;
    intensity_params.pattern            = 'triangle';
    shape_params.type                   = 'uniform';
    show_frame                          = 0;
    show_plot                           = 0;
    
    [frames, intensities, log_out] = GenerateRetinaStimulii(sensor_size, intensity_params, shape_params, show_frame, show_plot);
    
    %% set global params
    
    % terminate iterative correction if loss is less than tolerance
    tol.on = 0.1;
    tol.off = 0.1;
    
    update_mode = 'epc';
    amacrine_spread.mode = 1; % 0: no spread; 1: spread before; 2: spread after
    amacrine_spread.size = 9;
    

    %% Set Model Parameters
    
    params.frames_per_second            = 240;
    params.frame_show                   = 0;
    
    params.on_threshold                 = 0.25*ones(size(frames(:,:,1)));
    params.off_threshold                = 0.25*ones(size(frames(:,:,1)));
    
    params.percent_threshold_variance   = 2.5; % 2.5% variance in threshold - from DVS paper
    
    params.enable_threshold_variance    = 1;
    
    params.enable_pixel_variance        = 1;
    
    params.enable_diffusive_net         = 0;
    params.enable_temporal_low_pass     = 1;
    
    params.enable_leak_ba               = 1;
    params.leak_ba_rate                 = log(8);
    
    params.enable_refractory_period     = 0;
    params.refractory_period            = 1 * (1/params.frames_per_second);
    
    params.inject_spike_jitter          = 1;
    
    params.inject_poiss_noise           = 0;
    
    params.write_frame = 0;
    
    % [TD, ~, rng_settings] = RetinaNvsModel(double(frames), params);
    %
    % fprintf("%d events in simulated stream.\n", length(TD.x));
    
    
    %% Run Iterative Threshold Correction process
    
    isplot = 0;
    
    epochs = 10;
    loss.on = [];
    loss.off = [];
    num_events = [];
    
    
    for epoch = 1:epochs+1
        fprintf("|-------------------EPOCH %d-------------------|\n", epoch);
        
        % ---------------------------------------------------------------------
        step = "......1. RUNNING MODEL.....";
        fprintf("%s\n",step);
        
        if epoch == 1
            params.resample_threshold           = 1;
            params.rng_settings                 = 0;
            
            [ events, events_per_cycle_ideal, isi_ideal ] = IdealRetina1D(log_out, ...
                params.frames_per_second, ...
                params.on_threshold(1,1), ...
                params.off_threshold(1,1), ...
                intensity_params.iterations);
            
        else
            params.on_threshold             = threshold_on_update;
            params.off_threshold            = threshold_off_update;
            params.rng_settings             = rng_settings;
            params.resample_threshold       = 0;
        end
        
        if isplot
            figure();
            histogram(params.on_threshold(:));
            hold on;
            histogram(params.on_threshold(:));
            hold off;
            title(['Threshold Distribtuion Epoch:' num2str(epoch)], 'Interpreter', 'latex');
            legend({'ON', 'OFF'}, 'Interpreter', 'latex');
        end
        
        %----running Retina Model
        [TD, ~, rng_settings] = RetinaNvsModel(double(frames), params);
        fprintf("%d events in simulated stream.\n", length(TD.x));
        num_events = [num_events length(TD.x)];
        
        % ---------------------------------------------------------------------
        step = "............2. RUNNING CHARACTERIZATION..........";
        fprintf("%s\n",step);
        
        [isi,events_per_cycle] = CharacterizeRetina(TD, intensity_params, isplot);
        
        
        if epoch == 1
            isi_init = isi;
            epc_init = events_per_cycle;
        end
        
        if amacrine_spread.mode == 1
            [events_per_cycle.on , events_per_cycle.off] = AmacrineSpread(events_per_cycle.on , events_per_cycle.off, amacrine_spread.size, amacrine_spread.std);
        end
        
        % ---------------------------------------------------------------------
        step = "...........3. AMACRINE UPDATE............";
        fprintf("%s\n",step);
        
        learning_rate.on = 0.0003;
        learning_rate.off = 0.0003;
        
        if strcmp(update_mode,'epc')
            ideal.on = events_per_cycle_ideal(1);
            ideal.off = events_per_cycle_ideal(2);
        else
            ideal.on = isi_ideal(1);
            ideal.off = isi_ideal(1);
        end
        
        [ threshold_on_update, threshold_off_update, loss_on, loss_off ] = AmacrineUpdateGaussian( learning_rate, ...
            events_per_cycle, ...
            isi, ...
            ideal, ...
            update_mode, ...
            params, ...
            intensity_params, ...
            size(frames,3), ...
            amacrine_spread);
        
        fprintf("On loss: %.4f Off Loss: %.4f\n", loss_on, loss_off);
        loss.on = [loss.on loss_on ];
        loss.off = [loss.off loss_off];
        
        if (abs(loss_on) <= tol.on) && (abs(loss_off) <= tol.off)
            epochs = epoch;
            break
        end
    end
    final_loss.on = [final_loss.on loss_on ];
    final_loss.off = [final_loss.off loss_off ];
end

fprintf("%g ", final_loss.on);
fprintf("\n");
fprintf("%g ", final_loss.off);

figure();
combined = [final_loss.on(:), final_loss.off(:)];
x = 0.3:0.01:0.6;
bar(x, combined, 'grouped');
ylim([-0.1 0.1])
legend({'ON Loss','OFF Loss'},  'Interpreter', 'latex');
title('Loss (Before)',  'Interpreter', 'latex');
export_fig ../../../../figures/loss.pdf -append

% epochs = epoch;
%
% figure();
% subplot(2,1,1);
% histogram(events_per_cycle.on(:));
% hold on;
% histogram(epc_init.on(:));
% hold off;
% legend({'ON Events - Final','ON Events - Initial'},  'Interpreter', 'latex');
% title('Events/Cycle',  'Interpreter', 'latex');
% subplot(2,1,2);
% hold on;
% histogram(events_per_cycle.off(:));
% histogram(epc_init.off(:));
% hold off;
% legend({'OFF Events - Final','OFF Events - Initial'},  'Interpreter', 'latex');
% title('Events/Cycle',  'Interpreter', 'latex');
%
% figure();
% histogram(isi.on(:));
% hold on;
% histogram(isi.off(:));
% legend({'ON Events','OFF Events'},  'Interpreter', 'latex');
% title('ISI',  'Interpreter', 'latex');
% hold off;
%
% figure();
% plot(1:epochs, loss.on, 'r-*', 1:epochs, loss.off, 'b-o');
% title('Loss over time Before Filter(9 0.7)','Interpreter','latex');
%
% figure();
% plot(1:epochs, num_events, 'r-*');
% title('Number events over time','Interpreter','latex');