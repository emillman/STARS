%
% Copyright (C) 2011 Eamon Millman
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU Lesser General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with this program; if not, see <http://www.gnu.org/licenses/>.
%

function s = my_skewness(x,flag,dim)
%SKEWNESS Skewness.
%   S = SKEWNESS(X) returns the sample skewness of the values in X.  For a
%   vector input, S is the third central moment of X, divided by the cube
%   of its standard deviation.  For a matrix input, S is a row vector
%   containing the sample skewness of each column of X.  For N-D arrays,
%   SKEWNESS operates along the first non-singleton dimension.
%
%   SKEWNESS(X,0) adjusts the skewness for bias.  SKEWNESS(X,1) is the same
%   as SKEWNESS(X), and does not adjust for bias.
%
%   SKEWNESS(X,FLAG,DIM) takes the skewness along dimension DIM of X.
%
%   SKEWNESS treats NaNs as missing values, and removes them.
%
%   See also MEAN, MOMENT, STD, VAR, KURTOSIS.

%   Copyright 1993-2004 The MathWorks, Inc.
%   $Revision: 1.9.2.3 $  $Date: 2004/07/28 04:39:36 $

if nargin < 2 || isempty(flag)
    flag = 1;
end
if nargin < 3 || isempty(dim)
    % The output size for [] is a special case, handle it here.
    if isequal(x,[]), s = NaN; return; end;

    % Figure out which dimension nanmean will work along.
    dim = find(size(x) ~= 1, 1);
    if isempty(dim), dim = 1; end
end

% Need to tile the output of nanmean to center X.
tile = ones(1,max(ndims(x),dim));
tile(dim) = size(x,dim);

% Center X, compute its third and second moments, and compute the
% uncorrected skewness.
x0 = x - my_repmat(my_nanmean(x,dim), tile);
s2 = my_nanmean(x0.^2,dim); % this is the biased variance estimator
m3 = my_nanmean(x0.^3,dim);
s = m3 ./ s2.^(1.5);

% Bias correct the skewness.
if flag == 0
    n = sum(~isnan(x),dim);
    n(n<3) = NaN; % bias correction is not defined for n < 3.
    s = s .* sqrt((n-1)./n) .* n./(n-2);
end

function B = my_repmat(A,M,N)
%REPMAT Replicate and tile an array.
%   B = repmat(A,M,N) creates a large matrix B consisting of an M-by-N
%   tiling of copies of A. The size of B is [size(A,1)*M, size(A,2)*N].
%   The statement repmat(A,N) creates an N-by-N tiling.
%   
%   B = REPMAT(A,[M N]) accomplishes the same result as repmat(A,M,N).
%
%   B = REPMAT(A,[M N P ...]) tiles the array A to produce a 
%   multidimensional array B composed of copies of A. The size of B is 
%   [size(A,1)*M, size(A,2)*N, size(A,3)*P, ...].
%
%   REPMAT(A,M,N) when A is a scalar is commonly used to produce an M-by-N
%   matrix filled with A's value and having A's CLASS. For certain values,
%   you may achieve the same results using other functions. Namely,
%      REPMAT(NAN,M,N)           is the same as   NAN(M,N)
%      REPMAT(SINGLE(INF),M,N)   is the same as   INF(M,N,'single')
%      REPMAT(INT8(0),M,N)       is the same as   ZEROS(M,N,'int8')
%      REPMAT(UINT32(1),M,N)     is the same as   ONES(M,N,'uint32')
%      REPMAT(EPS,M,N)           is the same as   EPS(ONES(M,N))
%
%   Example:
%       repmat(magic(2), 2, 3)
%       repmat(uint8(5), 2, 3)
%
%   Class support for input A:
%      float: double, single
%
%   See also BSXFUN, MESHGRID, ONES, ZEROS, NAN, INF.

%   Copyright 1984-2008 The MathWorks, Inc.
%   $Revision: 1.17.4.14 $  $Date: 2008/12/01 07:17:27 $

if nargin < 2
    error('MATLAB:repmat:NotEnoughInputs', 'Requires at least 2 inputs.')
end

if nargin == 2
    if isscalar(M)
        siz = [M M];
    else
        siz = M;
    end
else
    siz = [M N];
end

if isscalar(A)
    nelems = prod(double(siz));
    if nelems>0 && nelems < (2^31)-1 % use linear indexing for speed.
        % Since B doesn't exist, the first statement creates a B with
        % the right size and type.  Then use scalar expansion to
        % fill the array. Finally reshape to the specified size.
        B(nelems) = A;
        if ~isequal(B(1), B(nelems)) || ~(isnumeric(A) || islogical(A))
            % if B(1) is the same as B(nelems), then the default value filled in for
            % B(1:end-1) is already A, so we don't need to waste time redoing
            % this operation. (This optimizes the case that A is a scalar zero of
            % some class.)
            B(:) = A;
        end
        B = reshape(B,siz);
    elseif all(siz > 0) % use general indexing, cost of memory allocation dominates.
        ind = num2cell(siz);
        B(ind{:}) = A;
        if ~isequal(B(1), B(ind{:})) || ~(isnumeric(A) || islogical(A))
            B(:) = A;
        end
    else
        B = A(ones(siz));
    end
elseif ndims(A) == 2 && numel(siz) == 2
    [m,n] = size(A);
    if (issparse(A))
        [I, J, S] = find(A);
        I = bsxfun(@plus, I(:), m*(0:siz(1)-1));
        I = bsxfun(@times, I(:), ones(1,siz(2)));
        J = bsxfun(@times, J(:), ones(1,siz(1)));
        J = bsxfun(@plus, J(:), n*(0:siz(2)-1));
        S = bsxfun(@times, S(:), ones(1,prod(siz)));
        B = sparse(I(:), J(:), S(:), siz(1)*m, siz(2)*n, prod(siz)*nnz(A));
    else
        if (m == 1 && siz(2) == 1)
            B = A(ones(siz(1), 1), :);
        elseif (n == 1 && siz(1) == 1)
            B = A(:, ones(siz(2), 1));
        else
            mind = (1:m)';
            nind = (1:n)';
            mind = mind(:,ones(1,siz(1)));
            nind = nind(:,ones(1,siz(2)));
            B = A(mind,nind);
        end
    end
else
    Asiz = size(A);
    Asiz = [Asiz ones(1,length(siz)-length(Asiz))];
    siz = [siz ones(1,length(Asiz)-length(siz))];
    subs = cell(1,length(Asiz));
    for i=length(Asiz):-1:1
        ind = (1:Asiz(i))';
        subs{i} = ind(:,ones(1,siz(i)));
    end
    B = A(subs{:});
end

function m = my_nanmean(x,dim)
%NANMEAN Mean value, ignoring NaNs.
%   M = NANMEAN(X) returns the sample mean of X, treating NaNs as missing
%   values.  For vector input, M is the mean value of the non-NaN elements
%   in X.  For matrix input, M is a row vector containing the mean value of
%   non-NaN elements in each column.  For N-D arrays, NANMEAN operates
%   along the first non-singleton dimension.
%
%   NANMEAN(X,DIM) takes the mean along dimension DIM of X.
%
%   See also MEAN, NANMEDIAN, NANSTD, NANVAR, NANMIN, NANMAX, NANSUM.

%   Copyright 1993-2004 The MathWorks, Inc.
%   $Revision: 2.13.4.3 $  $Date: 2004/07/28 04:38:41 $

% Find NaNs and set them to zero
nans = isnan(x);
x(nans) = 0;

if nargin == 1 % let sum deal with figuring out which dimension to use
    % Count up non-NaNs.
    n = sum(~nans);
    n(n==0) = NaN; % prevent divideByZero warnings
    % Sum up non-NaNs, and divide by the number of non-NaNs.
    m = sum(x) ./ n;
else
    % Count up non-NaNs.
    n = sum(~nans,dim);
    n(n==0) = NaN; % prevent divideByZero warnings
    % Sum up non-NaNs, and divide by the number of non-NaNs.
    m = sum(x,dim) ./ n;
end