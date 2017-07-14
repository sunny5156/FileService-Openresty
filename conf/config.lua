--mysql 链接信息
local _M = {VERSION = '0.0.0.1'}
_M.default = {
  MYSQL = {
    host = "127.0.0.1",
    port = 3306,
    database = "db_filesystem",
    user = "root",
    password = "",
    charset = "utf8",
    max_packet_size = 1024 * 1024,
  }

}

return _M