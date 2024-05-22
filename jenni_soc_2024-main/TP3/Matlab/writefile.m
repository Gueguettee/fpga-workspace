% Function to write signal in .dat file : <filename.dat>
%  <filename.dat> has the number of samples on the first line and the
%  samples on the others.
function writefile(signal,filename)

fid = fopen([filename '.dat'], 'w');

fprintf(fid,'%d\n', length(signal));
for n=1:length(signal)
    fprintf(fid, '%d\n', signal(n));
end

fclose(fid);
