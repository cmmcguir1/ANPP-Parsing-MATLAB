function value = parsePayload(payload, bytesOffset, size, dataType)
    % expected bytesOffset is one greater than what is reported in the manual due to matlab one-indexing
    value = 0;

    switch dataType
        case {'uint32', 'uint64', 'uint8', 'uint16'}
            bitShiftQ = 0;
            for index = bytesOffset:bytesOffset+size-1
                value = value + bitshift(payload(index), 8*bitShiftQ);
                bitShiftQ = bitShiftQ + 1;
            end
        case 'fp32'
            bitShiftQ = 0;
            totalBinString = [];
            for index = bytesOffset:bytesOffset+size-1
                binaryString = pad(dec2bin(payload(index)), 8, 'left', '0');
                totalBinString = [binaryString, totalBinString];
            end
            V = totalBinString-'0'; % convert to numeric
            frc = 1+sum(V(10:32).*2.^(-1:-1:-23)); % fraction
            pow = sum(V(2:9).*2.^(7:-1:0))-127; % power
            sgn = (-1)^V(1); % sign
            value = sgn * frc * 2^pow; % value
        otherwise
    end
end