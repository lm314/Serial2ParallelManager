# Serial2ParallelManager

If a program is serial, but has to read and write files in order to interface with other programs, MATLAB can only run one instance of the serial program at a time, despite having the capability to perform parallel computation. Thus, if we were able to perform these serial computations across multiple cores, we could expect a decrease in the time to execute the program for many varying inputs.

The Serial2ParallelManager MATLAB class achieves this by creating a directory structure where the files necessary for running are copied to separate folders where the MATLAB parallel workers perform the execution of the serial program and the subsequent analysis.

This is particularly useful when `parfor` loops are present; this is the case when performing MOGA optimizations using `ga` or `gamultiobj`.

## Example Use Cases

We provide a couple of possible use cases that call a program called `ImpactZexeWin.exe` that reads in a files `ImpactZ.in` and `particle.in` and outputs text files `fort.1001`. The precompiled windows version of the program that is available [here](https://github.com/impact-lbl/IMPACT-Z) is by default serial, though this class should work for the mpi linux versions of the program if the number of processors cores is specified is 1.

### `parfor` Loop



### `gamultiobj` Optimization

```matlab
%% --------Set up parallel pool and file structure---------

numCores = 10;
parpoolfiles = ["optFunct.m"];
Serial2ParallelManager.setupParpool(parpoolfiles,numCores);

homeDir = pwd;
copyFiles = {'ImpactZ_original.in','ImpactZexeWin.exe','particle.in'};
obj = Serial2ParallelManager(homeDir,copyFiles);
obj.setupDirWorkers();

%% -------------------Run Opitmization----------------------

maxGrad = 15;
KE = 27.9704E+06;
[gamma, beta] = KE2betaGamma(KE);

maxK = 0.2998*maxGrad/beta/(KE*1e-9);
ub = [1,0,1,1,0,1]*maxK;
lb = [0,-1,0,0,-1,0]*maxK;

betaXTuned = 4.525263797052626;
alphaXTuned = 24.890411508540677;
phaseAdvanceTuned = +5;

objectiveFunc = @(Qvals) obj.run(@optFunct,Qvals,betaXTuned,alphaXTuned,phaseAdvanceTuned);

nvars = length(ub);

options = optimoptions('gamultiobj',...
                       'Display','Iter',....
                       'UseParallel',true,...
                       'UseVectorized',false,...
                       'PopulationSize',200,...
                       'MaxGenerations',10);
[x,fval,exitflag,output,population,scores] = gamultiobj(objectiveFunc,nvars,...
    [],[],[],[],lb,ub,options);
```
