--数据操作类
--author sunny5156

local _M = {}
_M.__index = _M

--引入mongo扩展
local mongol = require "resty.mongol"

function _M:new(bucket_name)
    local conn = mongol:new()
    local ok, err = conn:connect("127.0.0.1", tonumber(27017))
    if not ok then
        ngx.log(ngx.ERR, "failed to connect db: ", err)
        ngx.exit(500)
    end
    local db = conn:new_db_handle("admin")
    if not db then
        ngx.log(ngx.ERR, "failed handle")
        ngx.exit(500)
    end
    --授权验证
--    local ok, err = db:auth_scram_sha1("admin","admin")
--    if not ok then
--        ngx.log(ngx.ERR, "failed to auth", err)
--        ngx.exit(500)
--    end
    local db = conn:new_db_handle("FileServieOpenresty")
    local b = { bucket = db:get_gridfs(bucket_name)}
    setmetatable(b, _M)
    return b
end

function _M:get(object_name)
    local f = self.bucket:find_one({["filename"]=object_name})
    if not f then return nil end
    --return f:read()
    return f
end

function _M:put(object_name)
    f, err = self.bucket:new({["filename"]=object_name})
    if not f then return nil, err end
    return f
end

function _M:list()
    local c = self.bucket.file_col:find({}, {_id=0})
    local ret = {}
    for idx, item in c:pairs() do
        ret[idx] = item
    end
    return ret
end

function _M:delete(object_name)
    return self.bucket:remove({["filename"]=object_name}, 0, 1)
end

function _M:head(object_name)
    return self.bucket.file_col:find_one({["filename"]=object_name}, {_id=0})
end

return _M