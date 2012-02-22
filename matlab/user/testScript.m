% Test_1;

context.remote_store = false;

if isunix()
    if context.remote_store
        context.store_path = 'emillman@localhost:/home/emillman/masters/store';
    else
        context.store_path = '/home/emillman/masters/store';
    end
    context.temp_path = '/home/emillman/masters/temp';
    context.cache.limit_bytes = 500*1024^2;
    context.cache.overhead_bytes = 450*1024^2;
    
    context.raw_compression = 2;
else
    context.store_path = 'c:\masters\store';
    context.temp_path = 'c:\masters\temp';
    %context.cache.limit_bytes = context.cache.overhead_bytes + 4*1024^2; % 4MB over what matlab is using
end

context.config = 'Test';
context.parameter = 1;
context.parameters = 1;

context.tmax = 1800;

context.repeat = 500;
context.max_repeat = 500;
context.first_repeat = 501;
context.cpu = matlabpool('size');

context.debug = true;

testFeatures;