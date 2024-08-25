function onset_sample = detect_onset(excitation_signal, system_response, fs, threshold_percentage)
    % Calculate the threshold
    %threshold = max(abs(system_response)) * threshold_percentage;
    
    % Find the first sample that exceeds the threshold
    %onset_sample = find(abs(system_response) > threshold, 1);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Manual onset detection
    bool = 0;
    while bool == 0
        figure
        hold on
        plot(excitation_signal);
        plot(system_response);
        onset_sample = input("Give onset sample of system response (read it from the plot):  ");
        hold on
        xline(onset_sample)
        if input("Is that correct? Answer with 1:  ") == 1
            bool = 1;
        end
        
    end

    % Convert the sample number to time
    onset_time = (onset_sample - 1) / fs;
end