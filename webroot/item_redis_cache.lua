--指定要访问的lua包所在的路径
package.path = package.path..";/data/luacache/config/?.lua;/data/luacache/lib/?.lua"
--package.path = package.path..";../config/?.lua;../lib/?.lua"
local config = require "config_constant"
local readhttp = require "read_http"
local returnjson = require "return_json"
--redis连接池工厂
local redis_factory = require('redis_factory')(config.redisConfig) 
--获取redis的连接实例
local ok, redis_a = redis_factory:spawn('redis_a')

--用于接收前端数据的对象
local args=nil
--获取前端的请求方式 并获取传递的参数   
local request_method = ngx.var.request_method
--判断是get请求还是post请求并分别拿出相应的数据
if "GET" == request_method then
        args = ngx.req.get_uri_args()
elseif "POST" == request_method then
        ngx.req.read_body()
        args = ngx.req.get_post_args()
        --兼容请求使用post请求，但是传参以get方式传造成的无法获取到数据的bug
        if (args == nil or args.data == null) then
                args = ngx.req.get_uri_args()
        end
end

--ngx.log(ngx.ERR,"args.key:",args.key)

if args.itemid == nil or args.itemid=="" then

    local json = returnjson.getjson("1",'key not exist or key is empty',"")
    --ngx.log(ngx.ERR,"json:",json)
    ngx.say(json)

else
        
    --获取前端传递的itemid
    local itemid = args.itemid

    --在redis中获取itemid对应的值
    local va = redis_a:get(itemid)

    if va == ngx.null or va == nil then

          --ngx.log(ngx.ERR, "redis not found content, back to http, itemid : ", itemid) 
          local url="/backenditem/item"
          va = readhttp.read(url,itemid)
          ngx.print(returnjson.getjson(0,itemid,va)) 
    else 
            --响应前端
         ngx.say(returnjson.getjson(0,itemid,va))
    end

end
