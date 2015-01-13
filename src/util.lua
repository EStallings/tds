function capVector(vx, vy, max)
	local length = vx*vx+vy*vy
	if length > max*max and length > 0 then
		local r = max/math.sqrt(length)
		vx = vx * r
		vy = vy * r
	end
	return vx, vy
end


function getOffsetVector(rotation)
	return math.sin(rotation) - math.cos(rotation), math.sin(rotation) + math.cos(rotation)
end

function rint(n)
	return math.floor(love.math.random()*n)
end

local haveSpare = false
local rand1
local rand2
function rnormal(variance)
	if(haveSpare) then
		haveSpare = false;
		return math.sqrt(variance * rand1) * math.sin(rand2);
	end
	haveSpare = true;
	rand1 = love.math.random();
	rand1 = -2 * math.log(rand1);
	rand2 = (love.math.random()) * math.pi*2;
	return math.sqrt(variance * rand1) * math.cos(rand2);
end

function rintnormal(v, d, n)
	local r = math.floor((rnormal(v)/d)*n/2+n/2);
	if r >= n then 
		r = n-1
	elseif r < 0 then
		r = 0
	end
	return r;
end


function shuffle(o)
    local j
    local x
    local i = o.length
    while i > 0 do
    	j = math.floor(love.math.random() * i)
    	i = i-1
    	x = o[i]
    	o[i] = o[j]
    	o[j] = x
    end
    return o;
end