clear;clc;
load remoteTrackPacketHistory_2023-08-16-15-54.mat

XYZdata = [];
for q = 1:length(remoteTrackPackets)
    payload = remoteTrackPackets(q,:);
    unixTimeSeconds = parsePayload(payload, 16, 4, 'uint32');
    microseconds = parsePayload(payload, 20, 4, 'uint32');

    remotePosRawX = parsePayload(payload, 116, 4, 'fp32');
    remotePosRawY = parsePayload(payload, 120, 4, 'fp32');
    remotePosRawZ = parsePayload(payload, 124, 4, 'fp32');

    remotePosCorrectedX = parsePayload(payload, 128, 4, 'fp32');
    remotePosCorrectedY = parsePayload(payload, 132, 4, 'fp32');
    remotePosCorrectedZ = parsePayload(payload, 136, 4, 'fp32');

    deviceAddress = parsePayload(payload, 1, 2, 'uint16');

%     localLatitude = parsePayload(payload, 24, 8);
%     localLongitude = parsePayload(payload, 32, 8);
%     localHeight = parsePayload(payload, 40, 8);

    localDepth = parsePayload(payload, 96, 4, 'fp32');
    remoteDepth = parsePayload(payload, 200, 4, 'fp32');

    XYZdata(end+1, :) = [unixTimeSeconds + microseconds/1e6, remotePosRawX, remotePosRawY, remotePosRawZ, ...
                    remotePosCorrectedX, remotePosCorrectedY, remotePosCorrectedZ];
    
end

