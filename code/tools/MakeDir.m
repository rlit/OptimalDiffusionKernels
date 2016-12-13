function MakeDir(dir2create)

if ~isdir(dir2create)
    [success,message] = mkdir(dir2create);
    if ~success
        error(message)
    end    
end


