% Function to simulate a FIR with 16bits signed integer values
function out = myfir(in,b) 

signal = [zeros(length(b)-1,1);in(:)];
out = zeros(size(in));
for n=length(b):length(signal)
    val=0;
    for m=1:length(b)
        val=val+floor((signal(n-length(b)+m)*b(m))/2^15);
    end
    out(n-length(b)+1)=val;
end