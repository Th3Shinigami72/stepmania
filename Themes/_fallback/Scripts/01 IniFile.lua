--[[
IniFile: basically a Lua rewrite of SM's IniFile class that serves as the
basis for the sm-ssc UserPrefs and ThemePrefs configuration systems.
Note that this is a namespace, not a class per se.
--]]

-- ThemePrefs is obsolete and removed.  IniFile remains to allow reading ini
-- files. -Kyz

-- redeclared here for my sanity's sake
-- TODO: declare these as global variables
local RageFile =
{
	READ	=	1,
	WRITE	=	2,
	STREAMED =	4,
	SLOW_FLUSH =	8
}

-- IniFile namespace
IniFile = 
{
	StrToKeyVal = function( str )
		local key, value = str:match( "(.+)=(.*)" )

		-- key is always a string, but value may be num, bool, or nil.
		-- do a few quick checks to see which one it is.

		-- if it's a nil, convert it to an empty string and return
		if value == nil then value = ""; return key, value; end

		-- if it's a number, convert it in place and return
		if tonumber(value) ~= nil then value = tonumber(value); return key, value; end

		-- not a number, so let's try a boolean value
		if value == "true" then value = true;
		elseif value == "false" then value = false;
		end

		return key, value
	end,

	ReadFile = function( file_path )
		Trace( "IniFile.ReadFile( " .. file_path .. " )" )
		local file = RageFileUtil.CreateRageFile()

		if not file:Open(file_path, RageFile.READ) then
			Warn( string.format("ReadFile(%s): %s",file_path,file:GetError()) )
			file:destroy()
			return { }	-- return a blank table
		end

		local tbl = { }
		local current = tbl

		while not file:AtEOF() do
			local str = file:GetLine()
			
			--ignore comments.
			if not str:find("^%s*#") then
				-- is this a section?
				local sec = str:match( "%[(.+)%]" )

				-- if so, set focus there; otherwise, try to
				-- read a key/value pair (ignore blank lines)
				if sec then
					-- if this section doesn't exist, create it
					tbl[sec] = tbl[sec] and tbl[sec] or { }
					current = tbl[sec]
					--Warn( "Switching section to " .. sec )
				else
					local k, v = IniFile.StrToKeyVal( str )
					if k and v ~= nil then current[k] = v end
				end
			end
		end

		file:Close()
		file:destroy()

		return tbl
	end,

	WriteFile = function( file_path, tbl )
		Trace( "IniFile.WriteFile( " .. file_path .. " )" )
		local file = RageFileUtil.CreateRageFile()

		if not file:Open(file_path, RageFile.WRITE) then
			Warn( string.format("WriteFile(%s): %s",file_path.file:GetError()) )
			file:destroy()
			return false
		end

		-- declare functions so we can write with foreach_ordered
		local function put_pair( k, v )
			file:PutLine( string.format("%s=%s", k, tostring(v)) )
		end

		local function put_section( section, pair )
			file:PutLine( "[" .. section .. "]" )
			foreach_ordered( pair, put_pair )
			file:PutLine("") -- put a blank line between sections
		end

		-- each base key is a section and its value is a
		-- table of key-value pairs under that section.
		foreach_ordered( tbl, put_section )

		file:Close()
		file:destroy()
		return true
	end	
};
