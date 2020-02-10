local return_json = {}
function return_json.getjson(status,msg,data)
      local json = '{"status":"'..status..'","msg":"'..msg..'","data":"'..data..'"}'
      return json
end

return return_json
