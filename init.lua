--服务启动文件
--author sunny5156

local path = "/PDT/FileService-Openresty/"
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s",path, path, m_package_path)
local FS = require "router.FileService"
FS.run()
