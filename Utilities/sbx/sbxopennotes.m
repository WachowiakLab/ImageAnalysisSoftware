function r = sbxopennotes(an)

% searches notes on a given animal

d = sbxdatadirs;

r = [];

for i = 1:length(d)
    fn = [d{i} filesep an filesep '*notes*'];
    dn = dir(fn);
    if ~isempty(dn)
        winopen([d{i} filesep an filesep dn(1).name]);
        r = d{i};
        break;
    end
end


