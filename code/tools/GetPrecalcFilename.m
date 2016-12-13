function [fullPath,filename] = GetPrecalcFilename(fileFullPath,folder)
p = GetParams_LSD();

if 0%~strncmp(p.pathData,'\\',2)
    assert(~isempty(strfind(fileFullPath,p.pathData)),'%s\n%s',fileFullPath,p.pathData)
    fileFullPath = strrep(fileFullPath,p.pathData,tempdir);
end

[pathstr, filename] = fileparts(fileFullPath);
precalcPathname = fullfile(pathstr, folder);
MakeDir(precalcPathname)
fullPath = fullfile(precalcPathname,[filename '.mat']);