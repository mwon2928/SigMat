function [modelOut,modelRamp] = insParam(model,p,tspan,normInp)

if length(p)<model.pFit.npar
	error('insParam:insufficientParameters',['Not enough parameters passed. Parameter vector must be at least ' num2str(model.pFit.npar) ' elements long.'])
end

% Make p a column vector
if isrow(p)
	p = p';
end

% Putting compartments into tensors
freeInd = model.modComp.pInd>0;
compVals = model.modComp.matVal;
if any(freeInd~=0)
	compVals(freeInd,end) = model.modComp.matVal(freeInd,end).*p(model.modComp.pInd(freeInd));
end
modSpcComp = model.modSpc.comp;
modSpcComp(modSpcComp>0) = compVals(modSpcComp(modSpcComp>0));
modSpcComp(modSpcComp==0) = NaN;
modelOut.comp = min(modSpcComp,[],2);

% Putting concentration into tensors
freeInd = model.modSpc.pInd>0;
concVals = model.modSpc.matVal;
if any(freeInd~=0)
	concVals(freeInd,end) = model.modSpc.matVal(freeInd,end).*p(model.modSpc.pInd(freeInd));
end

if strcmp(model.spcMode,'a')  % Case where absolute amount is used. So concentration must be calculated using volume
	concVals = concVals./modelOut.comp;
end
modelOut.modSpc = concVals;

for ii = 1:length(model.param)
	freeInd = model.param(ii).pInd>0;
	%Substitute in parameter
	model.param(ii).matVal(freeInd) = model.param(ii).matVal(freeInd).*p(model.param(ii).pInd(freeInd));
    modelOut.param(ii).matVal = model.param(ii).matVal;
	modelOut.param(ii).name   = model.param(ii).name;
end

modelRamp = model.rxnRules('compile',modelOut,[0 0]);
modelOut = model.rxnRules('compile',modelOut,tspan);

[~,ii] = intersect({modelOut.param.name},'k0');
modelOut.sigma = @(t) normInp(t) + modelOut.param(ii).matVal*ones(1,length(t)); 