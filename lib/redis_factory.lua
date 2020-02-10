local redis_factory = function(h)
    
    local h           = h

    h.redis           = require('resty.redis')
    h.cosocket_pool   = {max_idel = 10000, size = 10000}

    h.commands        = {
        "append",            "auth",              "bgrewriteaof",
        "bgsave",            "bitcount",          "bitop",
        "blpop",             "brpop",
        "brpoplpush",        "client",            "config",
        "dbsize",
        "debug",             "decr",              "decrby",
        "del",               "discard",           "dump",
        "echo",
        "eval",              "exec",              "exists",
        "expire",            "expireat",          "flushall",
        "flushdb",           "get",               "getbit",
        "getrange",          "getset",            "hdel",
        "hexists",           "hget",              "hgetall",
        "hincrby",           "hincrbyfloat",      "hkeys",
        "hlen",
        "hmget",             "hmset",             "hscan",
        "hset",
        "hsetnx",            "hvals",             "incr",
        "incrby",            "incrbyfloat",       "info",
        "keys",
        "lastsave",          "lindex",            "linsert",
        "llen",              "lpop",              "lpush",
        "lpushx",            "lrange",            "lrem",
        "lset",              "ltrim",             "mget",
        "migrate",
        "monitor",           "move",              "mset",
        "msetnx",            "multi",             "object",
        "persist",           "pexpire",           "pexpireat",
        "ping",              "psetex",            "psubscribe",
        "pttl",
        "publish",           "punsubscribe",      "pubsub",
        "quit",
        "randomkey",         "rename",            "renamenx",
        "restore",
        "rpop",              "rpoplpush",         "rpush",
        "rpushx",            "sadd",              "save",
        "scan",              "scard",             "script",
        "sdiff",             "sdiffstore",
        "select",            "set",               "setbit",
        "setex",             "setnx",             "setrange",
        "shutdown",          "sinter",            "sinterstore",
        "sismember",         "slaveof",           "slowlog",
        "smembers",          "smove",             "sort",
        "spop",              "srandmember",       "srem",
        "sscan",
        "strlen",            "subscribe",         "sunion",
        "sunionstore",       "sync",              "time",
        "ttl",
        "type",              "unsubscribe",       "unwatch",
        "watch",             "zadd",              "zcard",
        "zcount",            "zincrby",           "zinterstore",
        "zrange",            "zrangebyscore",     "zrank",
        "zrem",              "zremrangebyrank",   "zremrangebyscore",
        "zrevrange",         "zrevrangebyscore",  "zrevrank",
        "zscan",
        "zscore",            "zunionstore",       "evalsha",
        -- resty redis private command
        "set_keepalive",     "init_pipeline",     "commit_pipeline",      
        "array_to_hash",     "add_commands",      "get_reused_times",
    }

    -- connect
    -- @param table connect_info, e.g { host="127.0.0.1", port=6379, pass="", timeout=1000, database=0}
    -- @return boolean result
    -- @return userdata redis_instance
    h.connect = function(connect_info)
        local redis_instance = h.redis:new()
        redis_instance:set_timeout(connect_info.timeout)
        if not redis_instance:connect(connect_info.host, connect_info.port) then 
            return false, nil
        end
        if connect_info.pass ~= '' then
            redis_instance:auth(connect_info.pass)
        end
        redis_instance:select(connect_info.database)
        return true, redis_instance
    end

    -- spawn_client
    -- @param table h, include config info
    -- @param string name, redis config name
    -- @return table redis_client
    h.spawn_client = function(h, name)

        local self = {}
        
        self.name           = ""
        self.redis_instance = nil
        self.connect        = nil
        self.connect_info   = {
            host = "",   port = 0,    pass = "", 
            timeout = 0, database = 0
        }

        -- construct
        self.construct = function(_, h, name)
            -- set info
            self.name         = name
            self.connect      = h.connect
            self.connect_info = h[name]
            -- gen redis proxy client
            for _, v in pairs(h.commands) do
                self[v] = function(self, ...)
                    -- instance test and reconnect  
                    if (type(self.redis_instance) == 'userdata: NULL' or type(self.redis_instance) == 'nil') then
                        local ok
                        ok, self.redis_instance = self.connect(self.connect_info)
                        if not ok then return false end
                    end
                    -- get data
                    local vas = { ... }
                    return self.redis_instance[v](self.redis_instance, ...)
                end
            end
            return true
        end

        -- do construct
        self:construct(h, name) 

        return self
    end     



    local self = {}

    self.pool  = {} -- redis client name pool

    -- construct
    -- you can put your own construct code here.
    self.construct = function()
        return
    end

    -- spawn
    -- @param string name, redis database serial name
    -- @return boolean result
    -- @return userdata redis
    self.spawn = function(_, name)
        if self.pool[name] == nil then
            ngx.ctx[name] = h.spawn_client(h, name) 
            self.pool[name] = true
            return true, ngx.ctx[name]
        else
            return true, ngx.ctx[name]
        end
    end

    -- destruct
    -- @return boolean allok, set_keepalive result
    self.destruct = function()
        local allok = true
        for name, _ in pairs(self.pool) do
            local ok, msg = ngx.ctx[name].redis_instance:set_keepalive(
                h.cosocket_pool.max_idel, h.cosocket_pool.size
            )
            if not ok then allok = false end 
        end
        return allok
    end

    -- do construct
    self.construct() 
        
    return self
end


return redis_factory
