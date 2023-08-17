%%% anpp_parsing.m %%%
% DESCRIPTION
% - Tool for parsing through Advanced Navigation Packet Protocol log files.
% - Tool will scan for start of packets and then compare against packet IDs in a switch-case statement.
% 
% NOTES
% - This tool uses some brute-force methods and therefore can be slow for long log files. For example, a 30 minute log file takes
%   about 30 seconds to parse on my machine.
% - You'll likely need to add a case to the switch-case statement below to grab whichever packet you're after.
% - I find it useful to use this script to grab all packets that I'm interested in from the original log, stash them into a 
%   variable, save that var, then use another script to experiment with the data. This saves me from having to wait 30+ seconds
%   each time I need to generate a plot, for example. An included subtool named parse_remote_track_packets.m is a result of 
%   using this method.
%
% CHANGELOG
% 2023-08-17 11-45 c. mcguire
%   - Initial version
%
% Carson McGuire / N.C. State University

clear;clc;
fid = fopen('ANPP_LOG_000754_2020_01_01_00_00_37.anpp');
%fid = fopen('GNSS_ANPP_LOG_000755_2020_01_01_00_00_46.anpp');
%fid = fopen('slave_ANPP_LOG_000054_2020_01_01_00_00_37.anpp');
dataStream = (fread(fid, Inf, 'uint8')); % parses for uint8 type, stores as double
fclose(fid);

q = 1;
packetIDlist = [];
XYZdata = [];
timeHist = [];
filterStatusHist = [];
remoteTrackPackets = [];
while q < length(dataStream) - 4
    
    % start of packets are found by searching for a longitudinal redundancy check byte -- see ANPP docs (USBL manual also docs this)
    for q = q:length(dataStream)-4 % for-loop will pick up where it left off after parsing a packet, allows skipping bytes that are payload
        lrc_calc = bitand(bitxor(sum(dataStream(q+1:q+4)), hex2dec('FF')) + 1, hex2dec('FF')); % calc lrc for subsequent four bytes
        if dataStream(q) == lrc_calc && dataStream(q+2) ~= 0 % lrc matches and packet has non-zero length
            break; % leave for-loop for now
        end
    end

    packetStartIndex = q; % index of first packet byte
    headerLRC = dataStream(packetStartIndex+0); % longitudinal redundancy check -- see ANPP docs
    packetID = dataStream(packetStartIndex+1); % packet ID
    packetLength = dataStream(packetStartIndex+2); % length of packet payload (# of bytes after CRC bytes)
    packetCRC = bitshift(uint16(dataStream(packetStartIndex+4)), 8) + uint16(dataStream(packetStartIndex+3)); % cyclic redundancy check

    crc_calc = hex2dec(crc16_ccitt(dataStream(q+5:(q+5+(packetLength)-1)))); % calculate CRC for payload
    
    if crc_calc == packetCRC % CRC passed -- analyze payload
        q = q + 4 + packetLength; % update q index so that for-loop doesn't re-search bytes that were payload
        packetIDlist(end+1) = packetID;
        payload = dataStream(packetStartIndex+5:(packetStartIndex+5+(packetLength)-1));
        switch packetID
            case 20 % system state packet
                unixTimeSeconds = parsePayload(payload, 9, 4, 'uint32');
                microseconds = parsePayload(payload, 13, 4, 'uint32');
                filterStatus = parsePayload(payload, 5, 4, 'uint32');
                filterStatusHist(end+1,:) = [unixTimeSeconds + microseconds/1e6, filterStatus];
                
                %XYZdata(end+1, :) = [unixTimeSeconds + microseconds/1e6, latitude, longitude, height];

            case 24 % remote track packet 
                % The Track Packet contains information about an acoustic track event. This packet is generated
                % when the Subsonus calculates an acoustic position or angle. The fields in this packet contain data
                % for both the Local device and the Remote device. The local Subsonus is the sender of this packet.
                
                unixTimeSeconds = parsePayload(payload, 16, 4, 'uint32');
                microseconds = parsePayload(payload, 20, 4, 'uint32');

                remotePosRawX = parsePayload(payload, 116, 4, 'fp32');
                remotePosRawY = parsePayload(payload, 120, 4, 'fp32');
                remotePosRawZ = parsePayload(payload, 124, 4, 'fp32');

                remotePosCorrectedX = parsePayload(payload, 128, 4, 'fp32');
                remotePosCorrectedY = parsePayload(payload, 132, 4, 'fp32');
                remotePosCorrectedZ = parsePayload(payload, 136, 4, 'fp32');

                deviceAddress = parsePayload(payload, 1, 2, 'uint16');

%                 localLatitude = parsePayload(payload, 24, 8);
%                 localLongitude = parsePayload(payload, 32, 8);
%                 localHeight = parsePayload(payload, 40, 8);

                XYZdata(end+1, :) = [unixTimeSeconds + microseconds/1e6, remotePosRawX, remotePosRawY, remotePosRawZ, ...
                    remotePosCorrectedX, remotePosCorrectedY, remotePosCorrectedZ];

                remoteTrackPackets(end+1,:) = payload';

            otherwise
                % ignore other packets
        end

    else % CRC failed -- discard payload
        q = q + 1; % continue for-loop search with next byte
    end
    
    % return to for-loop to continue searching for start-of-packet bytes
end

disp('Found packets with the following IDs:')
disp(unique(packetIDlist))
%% functions
function crc = crc16_ccitt(data)
    % source: https://www.mathworks.com/matlabcentral/fileexchange/47682-crc_16_ccitt-m
    %CRC-16-CCITT
    %The CRC calculation is based on following generator polynomial:
    %G(x) = x16 + x12 + x5 + 1
    %
    %The register initial value of the implementation is: 0xFFFF
    %
    %used data = string -> 1 2 3 4 5 6 7 8 9
    %
    % Online calculator to check the script:
    %http://www.lammertbies.nl/comm/info/crc-calculation.html
    %
    %
    %crc look up table
    Crc_ui16LookupTable=[0,4129,8258,12387,16516,20645,24774,28903,33032,37161,41290,45419,49548,...
        53677,57806,61935,4657,528,12915,8786,21173,17044,29431,25302,37689,33560,45947,41818,54205,...
        50076,62463,58334,9314,13379,1056,5121,25830,29895,17572,21637,42346,46411,34088,38153,58862,...
        62927,50604,54669,13907,9842,5649,1584,30423,26358,22165,18100,46939,42874,38681,34616,63455,...
        59390,55197,51132,18628,22757,26758,30887,2112,6241,10242,14371,51660,55789,59790,63919,35144,...
        39273,43274,47403,23285,19156,31415,27286,6769,2640,14899,10770,56317,52188,64447,60318,39801,...
        35672,47931,43802,27814,31879,19684,23749,11298,15363,3168,7233,60846,64911,52716,56781,44330,...
        48395,36200,40265,32407,28342,24277,20212,15891,11826,7761,3696,65439,61374,57309,53244,48923,...
        44858,40793,36728,37256,33193,45514,41451,53516,49453,61774,57711,4224,161,12482,8419,20484,...
        16421,28742,24679,33721,37784,41979,46042,49981,54044,58239,62302,689,4752,8947,13010,16949,...
        21012,25207,29270,46570,42443,38312,34185,62830,58703,54572,50445,13538,9411,5280,1153,29798,...
        25671,21540,17413,42971,47098,34713,38840,59231,63358,50973,55100,9939,14066,1681,5808,26199,...
        30326,17941,22068,55628,51565,63758,59695,39368,35305,47498,43435,22596,18533,30726,26663,6336,...
        2273,14466,10403,52093,56156,60223,64286,35833,39896,43963,48026,19061,23124,27191,31254,2801,6864,...
        10931,14994,64814,60687,56684,52557,48554,44427,40424,36297,31782,27655,23652,19525,15522,11395,...
        7392,3265,61215,65342,53085,57212,44955,49082,36825,40952,28183,32310,20053,24180,11923,16050,3793,7920];
    %data=[49 50 51 52 53 54 55 56 57]; % ~ string '1 2 3 4 5 6 7 8 9'
    ui16RetCRC16 = hex2dec('FFFF');
    for I=1:length(data)
        ui8LookupTableIndex = bitxor(data(I),uint8(bitshift(ui16RetCRC16,-8)));
        ui16RetCRC16 = bitxor(Crc_ui16LookupTable(double(ui8LookupTableIndex)+1),mod(bitshift(ui16RetCRC16,8),65536));
    end
    crc=dec2hex(ui16RetCRC16);
end