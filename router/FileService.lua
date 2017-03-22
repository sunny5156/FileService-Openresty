--FileService 操作
--author sunny5156

local _M= {}

local mongoOperate = require "models.mongoOperate" --mongo操作
local upload = require "resty.upload"  --上传
local md5 = require "resty.md5" --md5
local cjson = require "cjson"  --json扩展
local http_time = ngx.http_time --http 时间
local resp_header = ngx.header  --nginx 请求包头
local ngx_var = ngx.var --nginx 参数
local method = ngx.var.request_method --nginx 请求方法


local function gen_cache_control_headers(ts)
    resp_header["Last-Modified"] = http_time(tonumber(ts) / 1000)
    resp_header["Cache-Control"] = "max-age=3600"
end

--启动类
--路由分发

function _M.run()
    local uri = ngx_var.uri
    if uri == "/" then
        resp_header["Cache-Control"] = "max-age=3600"
        return ngx.say("<h1>Static server by FileService-Openresty!!!</h1>")
    end

    if "GET" == method then
        return _M.get()
    end

    if "HEAD" == method then
        return _M.head()
    end

    if "POST" == method then
        return _M.post()
    end

    if "DELETE" == method then
        return _M.delete()
    end

end

--待完善
function _M.put()
end

function _M.get()
    local uri = ngx_var.uri
    local m, err = ngx.re.match(uri, "/(?<bn>.*?)/(?<filename>[A-Za-z0-9_/.]+)")
    if m then
        local bn = m["bn"]
        local filename = m["filename"]
        local obj = mongoOperate:new(bn)
        local dbfile = obj:get(filename)
        if not dbfile then
            ngx.exit(404)
            return
        end
        if dbfile.last_modified then
            gen_cache_control_headers(dbfile.last_modified)
        end
        if dbfile.content_type then resp_header['Content-Type']=dbfile.content_type end
        if dbfile.file_size then resp_header['Content-Length']=dbfile.file_size end
        ngx.say(dbfile:read())
    end

    ngx.exit(404)
end

--待完善
function _M.options()
end

function _M.post()
    local uri = ngx_var.uri
    local f, err
    local m, err = ngx.re.match(uri, "/(?<bn>.*?)/(?<filename>[A-Za-z0-9_/.]+)")
    if not m then
        ngx.exit(404)
    end
    local bn = m["bn"]
    local filename = m["filename"]
--    ngx.say(filename)
    local form, err = upload:new()
    local blob = ""
    if not form then
        ngx.log(ngx.ERR, "failed to new upload: ", err)
        ngx.exit(500)
        return
    end
    form:set_timeout(6000)
    local obj = mongoOperate:new(bn)
    local meta = {}
    f = obj:get(filename)
    if not f then
        f, err = obj:put(filename)
    end
    if not f then
        ngx.log(ngx.ERR, "failed to put object: ", err)
        ngx.exit(500)
        return
    end

    while true do
        local typ, res, err = form:read()
        if not typ then
            ngx.log(ngx.ERR, "failed to read: ", err)
            ngx.exit(500)
            return
        end
        if typ == "header" then
            if res[1] == "Content-Type" then
                meta["contentType"] = res[2]
            end
        end
        if typ == "body" then
            blob = blob..res
        end
        if typ == "eof" then
            break
        end
    end

    f:write(blob, 0)
    f:update_md5()
    f:update_meta(meta)
    ngx.exit(200)
end

function _M.delete()
    local uri = ngx_var.uri
    local m, err = ngx.re.match(uri, "/(?<bn>.*?)/(?<filename>[A-Za-z0-9_/.]+)")
    if not m then
        ngx.exit(404)
    end
    local bn = m["bn"]
    local filename = m["filename"]
    local obj = mongoOperate:new(bn)
    local ok = obj:delete(filename)
    if ok then
        ngx.exit(200)
    else
        ngx.exit(500)
    end
end

function _M.head()
    local uri = ngx_var.uri
    local m, err = ngx.re.match(uri, "/(?<bn>.*?)/(?<filename>[A-Za-z0-9_/.]+)")
    if m then
        local bn = m["bn"]
        local filename = m["filename"]
        local obj = mongoOperate:new(bn)
        local dbfile = obj:get(filename)
        if not dbfile then
            ngx.exit(404)
        end
        if dbfile.last_modified then
            gen_cache_control_headers(dbfile.last_modified)
        end
        if dbfile.content_type then resp_header['Content-Type']=dbfile.content_type end
        if dbfile.file_size then resp_header['Content-Length']=dbfile.file_size end
        ngx.exit(200)
    end

    ngx.exit(404)
end

return _M