local read_http = {}
function read_http.read(url,id)

     local resp = ngx.location.capture(url, {
          method = ngx.HTTP_GET,
          args = {id = id}
      })


      if not resp then
          ngx.log(ngx.ERR, "request error :", err)
          return
      end

      if resp.status ~= 200 then
          ngx.log(ngx.ERR, "request error, status :", resp.status)
          return
      end

      return resp.body
end

return read_http
