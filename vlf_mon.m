% VLF monitoring in MATLAB
% Version 0.1
% license GPL v3.0
% Alexey "FoxyLab" Voronin
% Email: support@foxylab.com
% Website: https://acdc.foxylab.com
% -----------------------------------
% for 32 bit MATLAB
clc; % cmd wnd clear
disp('***** VLF monitoring *****');
disp('(C) Alexey "FoxyLab" Voronin');
disp('https://acdc.foxylab.com');
disp('**************************');
prompt = {'Interval (dt)'};
defans = {'500'};
answer = inputdlg(prompt,'Interval (dt), msec',1,defans);
[window status] = str2num(answer{1});
if ~status
    error('Incorrect value!');
end;
prompt = {'Numbers (N)'};
defans = {'1800'};
answer = inputdlg(prompt,'Numbers (N)',1,defans);
[nums status] = str2num(answer{1});
if ~status
    error('Incorrect value!');
end;
prompt = {'Monitoring Frequency (f)'};
defans = {'22100'};
answer = inputdlg(prompt,'Monitoring Frequency (f), Hz',1,defans);
[mon_freq status] = str2num(answer{1});
if ~status
    error('Incorrect value!');
end;
mon_delta = 100;
mon_low = mon_freq - mon_delta;
mon_high = mon_freq + mon_delta;
disp(sprintf('dt = %d msec',window));
disp(sprintf('N = %d',nums));
disp(sprintf('f = %d Hz',mon_freq));
Fs = 96000; % sampling freq, Hz
duration = window/1000; % measure interval, sec
% log file name
formatOut = 'yyyymmddHHMMSS'; % date time
unique = datestr(now,formatOut);
unique_txt = strcat(unique,'.txt'); % txt-file save 
txt_file = fopen(unique_txt,'w'); % log file open
fprintf(txt_file,'f = %d Hz\r\n',mon_freq);
fprintf(txt_file,'dt = %d msec\r\n',window);
fprintf(txt_file,'N = %d\r\n',nums);
fclose(txt_file); % log file close
while (true)
ai = analoginput('winsound'); 
addchannel(ai,1); % HW ch add
% ch 1 - mono
set (ai, 'SampleRate', Fs); % sampling freq set
set (ai, 'SamplesPerTrigger', duration*Fs); % samples number set
set (ai, 'TriggerType', 'Manual'); % manual start
set(ai,'TriggerRepeat',Inf);
start(ai); % acquire ready
bins = []; % bin array create
trigger(ai); % acquire start
data = getdata(ai); % data read
L = length(data); % data array size
% disp(sprintf('L = %d samples',L));
% disp(sprintf('dF = %d Hz/bin',Fs/L));
for m =1:1:L/2+1 % bin array clear
    bins(m) = 0;
end;
count = 0;
trigger(ai); % acquire start
while (count < nums) % acquire loop
    data = getdata(ai); % data read
    % wait
    Y = fft(data); 
    % P2 = abs(Y/L);
    % P1 = P2(1:L/2+1);
    % P1(2:end-1) = 2*P1(2:end-1);
    for m =1:1:L/2+1
        bins(m) = (bins(m)*count+abs(Y(m))*2/L)/(count+1);
    end;
    count = count+1;
    disp(sprintf('#%d',count));   
    trigger(ai); % acquire start
end
stop(ai); % acquire stop
delete(ai); % analog input object delete
clear ai; % analog input object clear
f = Fs*(0:(L/2))/L; % freqs
txt_file = fopen(unique_txt,'a+'); % log file open
% peak detection
peak_level = 0;
for m =1:1:L/2+1 
    if (((m-1)*Fs/L)>=mon_low) && (((m-1)*Fs/L)<=mon_high)
        if (bins(m) > peak_level)
            peak_level = bins(m);
        end;
    end;
end;
disp(sprintf('Level: %5.0fu',peak_level*1e6));
fprintf(txt_file,'Level: %5.0fu\r\n',peak_level*1e6);
formatOut = 'dd.mm.yyyy HH:MM'; % date time
cur_time = datestr(now,formatOut);
disp(cur_time);
fprintf(txt_file,'Time: %s\r\n',cur_time);
fclose(txt_file); % log file close
end;
clear all; % objects delete