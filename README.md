在openresty中使用lua访问redis,直接从缓存中返回response

本项目的说明文档:
https://www.cnblogs.com/architectforest/p/12287395.html

使用redis做商品详情页的cache:

流程：当用户访问时，

               先从redis中获取cache内容，

               如果redis中不存在此value,则会改为访问后端业务系统获取cache

 

说明：在生产环境中，为方便更新，通常会采用redis的主从架构，

              每台业务nginx上所配备的redis的数据能得到实时更新

lua程序文件:   item_redis_cache.lua
lua访问redis的配置文件: config_constant.lua
lua程序文件：read_http.lua：用来从后端业务系统得到response
lua程序文件：return_json.lua :返回json字串
