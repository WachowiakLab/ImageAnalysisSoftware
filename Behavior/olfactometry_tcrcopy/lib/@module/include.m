function include(m)
    fs = fieldnames(m.public);
    for f = 1:length(fs)
        assignin('caller',fs{f},m.public.(fs{f}))
    end
end