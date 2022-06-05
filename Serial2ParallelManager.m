classdef Serial2ParallelManager
    %SERIAL2PARALLELMANAGER Allows serial process to run in parallel
    %   Allows a serial program to be run in parallel by assigning parallel
    %   workers to separate directories, where unique inputs and outputs
    %   can be processed.

    properties
        HomeDir
        CopyFiles
        NonSerialDir = 'tempSerial'
    end

    methods
        function obj = Serial2ParallelManager(homeDir,copyFiles)
            obj.HomeDir = homeDir;
            obj.CopyFiles = copyFiles;
        end

        function setupDir(obj)
            w = getCurrentWorker;
            if(isempty(w))
                % nonserial case with parpool
                mydir = fullfile(obj.HomeDir,obj.NonSerialDir);
            else
                mydir = fullfile(obj.HomeDir,['temp',num2str(w.ProcessId)]);
            end
            
%             [status, msg, msgID] = mkdir(mydir);
            if(~exist(mydir,"dir"))
                mkdir(mydir);
            end
        
            for ii = 1:length(obj.CopyFiles)
                origInFile = fullfile(obj.HomeDir,obj.CopyFiles{ii});
%                 [SUCCESS,MESSAGE,MESSAGEID] = copyfile(origInFile,mydir);
                copyfile(origInFile,mydir);
            end
        end

        function setupDirWorkers(obj)
            p = gcp;

            %set up parpool workers
            parfor ii = 1:p.NumWorkers
                setupDir(obj)
            end

            %set up serial case
            setupDir(obj)
        end

        function x = run(obj,func,varargin)
            % Changes to worker directory and runs function there
            w = getCurrentWorker;
            if(isempty(w))
                % nonserial case with parpool
                workerDir = fullfile(obj.HomeDir,obj.NonSerialDir);
            else
                workerDir = fullfile(obj.HomeDir,['temp',num2str(w.ProcessId)]);
            end

            if(~strcmp(pwd,workerDir))
                cd(workerDir)
            end

            x = func(varargin{:});
        end
    end

    methods (Static)
        function setupParpool(myFiles,numCores)
            p = gcp('nocreate');
            if(isempty(p))
                if(isempty(numCores))
                    p = parpool();
                else
                    p = parpool(numCores);
                end
            end
            
            if(~isempty(myFiles) && ~isempty(p))
                addAttachedFiles(p, myFiles)
            end
        end
    end
end