# FileService-Openresty

## 配置文件
```
##nginx 配置文件,copy到 openresty 配置目录中##
server {
	lua_code_cache off;
	listen 8090;
    charset utf-8;
	server_name  localhost;
	location / {
		default_type text/html;
		content_by_lua_file /PDT/FileService-Openresty/init.lua;
	}
}

```

## 访问

## 使用方法

上传以及更新 curl -F file=@delinfo.txt http://{domain}{:port}/{bucket}/{file.png}
下载 wget http://{domain}{:port}/bucket/file.png
判断是否存在 curl -X HEAD http://{domain}{:port}/bucket/file.png
删除文件 curl -X DELETE http://{domain}{:port}/bucket/file.png
上述通过判断http状态码来判断服务是否正确

##php调用方法

```
<?php
    header('content-type:text/html;charset=utf8');

    $file = dirname(__FILE__).'/{fileName}.png';
    $data['file'] = new CurlFile($file);
    $url = "http://localhost:8090/{bucket}/{saveFileName}.png";
    
    $ch = curl_init();
    curl_setopt($ch,CURLOPT_URL, $url);
    curl_setopt($ch,CURLOPT_RETURNTRANSFER,true);
    curl_setopt($ch,CURLOPT_POST,true);
    curl_setopt($ch,CURLOPT_POSTFIELDS,$data);
    $result = curl_exec($ch);
    curl_close($ch);
	
	print_r($result);
    
    //echo json_decode($result);
?>
```

## 修改init.lua

```
--服务启动文件
--author sunny5156

local path = "{FileService Project Path}"  --修改这里
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s",path, path, m_package_path)
local FS = require "router.FileService"
FS.run()

```


