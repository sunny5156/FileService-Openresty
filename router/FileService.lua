--FileService 操作
--author sunny5156

local _M= {}

local mongoOperate = require "models.mongoOperate" --mongo操作
local upload = require "resty.upload"  --上传
local md5 = require "resty.md5" --md5
local cjson = require "cjson"  --json扩展
local mysql = require "resty.mysql" --mysql扩展

local http_time = ngx.http_time --http 时间
local resp_header = ngx.header  --nginx 请求包头
local ngx_var = ngx.var --nginx 参数
local method = ngx.var.request_method --nginx 请求方法

local config = require "conf.config" -- 配置文件



local function gen_cache_control_headers(ts)
    resp_header["Last-Modified"] = http_time(tonumber(ts) / 1000)
    resp_header["Cache-Control"] = "max-age=3600"
end

local function my_get_file_name(str)
    --local filename,err = ngx.re.match(res,'(.*)filename="(.*)"(.*)')
    local fileInfo,err = ngx.re.match(str, "form-data; name=\"file\"; filename=\"(?<filename>[A-Za-z0-9_/.]+)\"")
    if fileInfo then
        return fileInfo[1]
    end
end

local function debug(data)

  if type(data) == "table" then
    for k,v in pairs(data) do
      if type(v) == "table" then
        ngx.say(k,":",table.concat(v,","),"</br>")
      else
        ngx.say(k,":",v,"</br>")
      end
    end
  else
    ngx.say(data)
  end
end


--获取扩展名
function get_ext(str)
    return str:match(".+%.(%w+)$")
end


--启动类
--路由分发

function _M.run()
    local uri = ngx_var.uri

    if "GET" == method then
        --首页
        if uri == "/" then
            resp_header["Cache-Control"] = "max-age=3600"
            --local res = ngx.location.capture("/index.html", {})
            -- ngx.say(res.body)
            --return
            return ngx.say("<h1>Static server by FileService-Openresty!!!</h1>")
        else
          return _M.get()
        end
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

    else
        ngx.say("not found filename in uri")
        ngx.exit(200)
        return
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
    local ext
    if not m then
        ngx.exit(404)
    end

    local bn = m["bn"]
    local filename = m["filename"]


--    if not bn then
--      bn = "default"
--    end
--    if not filename then
--      filename = ngx.md5( bn.. ngx.now())
--    end
--    ngx.say(filename)
    local form, err = upload:new()
    local db,err = mysql:new()
    local blob = ""
    local originFileName = ""

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

    --读取文件内容
    while true do
        local typ, res, err = form:read()

        if not typ then
            ngx.log(ngx.ERR, "failed to read: ", err)
            ngx.exit(500)
            return
        end
        if typ == "header" then
            if res[1] == 'Content-Disposition' then
              originFileName = my_get_file_name(res[2])
              ext = get_ext(originFileName)
            end

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

    --更新文件
    local fres = f:write(blob, 0)

    --更新文件名
    --meta["filename"] = ngx.md5( bn.. ngx.now()).."."..ext
    f:update_md5()
    f:update_meta(meta)

    --写入mysql
    local db, err = mysql:new()
    if not db then
        ngx.say("failed to instantiate mysql: ", err)
        ngx.log(ngx.ERR, "failed to read: ", err)
        return
    end

    db:set_timeout(1000) -- 1 sec

    local ok, err, errcode, sqlstate = db:connect(config.default.MYSQL)

    if not ok then
        ngx.say("failed to connect: ", err, ": ", errcode, " ", sqlstate)
        return
    end

    --ngx.say("connected to mysql.")

    local insertSQL = "INSERT INTO `db_filesystem`.`fs_attachment` ( `type`,  `name`,  `size`,  `savepath`,  `savename`,  `ext`,  `hash`) "..
    "VALUES  ('"..meta["contentType"].."','"..originFileName.."',"..f['file_size']..",'"..bn.."/"..filename.."','"..filename.."','"..ext.."','hash' );"
    ngx.log(ngx.ERR,insertSQL)
    local res, err, errcode, sqlstate =  db:query(insertSQL)
    if not res then
        ngx.say("bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
        return
    end

--    local res, err, errcode, sqlstate =
--        db:query("drop table if exists cats")
--    if not res then
--        ngx.say("bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
--        return
--    end
--    local result =  {}
--    result.filename = mate["filename"]
--    result.savePath = bn.."/"..mate["filename"]
--    ngx.print(cjson.encode(meta))
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