clear;clc;
load XYZdata_2023-08-17-10-30.mat % [time, rawX, rawY, rawZ, corrX, corrY, corrZ]
XYZdata(XYZdata(:,2) == 5.877471754111438e-39, :) = []; % remove data rows that recorded as 0
XYZdata(:,1) = XYZdata(:,1) - XYZdata(1,1); % adjust time to be experiment runtime rather than unix time

figure(1)
clf
sgtitle('CSI USBL Testing - Aug 2023')
subplot(2,1,1)
plot(XYZdata(:,1), XYZdata(:,5), '.--');
hold on
plot(XYZdata(:,1), XYZdata(:,6), '.--');
plot(XYZdata(:,1), XYZdata(:,7), '.--');
xlabel('Time (s)')
ylabel('Position (m)')
legend('X position', 'Y position', 'Z position (depth)', 'location', 'northwest')
title('Remote USBL X,Y,Z position (in local USBL frame)')
grid on

load filterStatusHistory_2023-08-17-10-45.mat % [time, filterStatus]
% bit 17 records if fixed position is active
fixedPositionActive = boolean(bitand(filterStatusHist(:,2), 131072));     
% yyaxis right
% plot(filterStatusHist(:,1), fixedPositionActive, 'DisplayName', 'Fixed Position Active')

subplot(2,1,2)
plot(XYZdata(:,1), sqrt(XYZdata(:,5).^2 + XYZdata(:,6).^2), '.--');
xlabel('Time (s)')
ylabel('Vessel range (m)')
title('Approx. range between vessels (based on X,Y data)')
grid on
fig = gcf;
fig.Position = [1000 661 952 677];

% figure(2)
% clf
% plot(XYZdata(:,1) - XYZdata(1,1), XYZdata(:,7), '.--');
% title('Corrected depth')

animateXY = false;

if animateXY
    figure(3)
    clf
    h = animatedline;
    title('X-Y position')
    xlabel('X position')
    ylabel('Y position')
    axis([-15 20 -15 30])
    startTime = 0;
    endTime = inf;
    inds = XYZdata(:,1) > startTime & XYZdata(:,1) < endTime;
    for q = find(inds)'
        addpoints(h, XYZdata(q,5), XYZdata(q,6))
        drawnow
        pause((XYZdata(q+1,1) - XYZdata(q,1)));
    end
    
end