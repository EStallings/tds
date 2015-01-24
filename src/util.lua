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
    local i = table.getn(o)
    while i > 0 do
    	j = rint(i)
    	i = i-1
    	x = o[i]
    	o[i] = o[j]
    	o[j] = x
    end
    return o;
end

function push(a, obj)
	if table.getn(a) == 0 then
		a[0] = obj
	else
		table.insert(a, obj)
	end
end

--SLOW method of getting a random entry from a table with NON-INTEGRAL indices
function table.randFrom( t )
	local choice = "F"
	local n = 0
	for i, o in pairs(t) do
		n = n + 1
		if love.math.random() < (1/n) then
			choice = o		
		end
	end
	return choice
end

function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end